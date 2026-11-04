import 'package:blocs/blocs.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../dependencies.dart';
import '../shortcuts.dart';
import '../widgets/loan_detail_panel.dart';
import '../widgets/loan_filter_bar.dart';
import '../widgets/loan_list.dart';
import '../widgets/loan_table.dart';

class LoanBoardScreen extends StatefulWidget {
  const LoanBoardScreen({super.key});

  @override
  State<LoanBoardScreen> createState() => _LoanBoardScreenState();
}

class _LoanBoardScreenState extends State<LoanBoardScreen> {
  final _boardFocus = FocusNode(debugLabel: 'loan board');

  LoanBoardBloc get _bloc => context.read<LoanBoardBloc>();

  @override
  void dispose() {
    _boardFocus.dispose();
    super.dispose();
  }

  void _showNotice(BuildContext context, LoanBoardNotice notice) {
    final message = switch (notice) {
      LoanBoardActionSucceeded(:final loan) => switch (loan.status) {
        Approved() => 'Pozajmica je odobrena.',
        Rejected() => 'Pozajmica je odbijena.',
        Pending() || PickedUp() || Overdue() || Returned() || Cancelled() => 'Pozajmica je ažurirana.',
      },
      LoanBoardActionRejected(:final error) => error.message,
      LoanBoardActionFailed() => 'Izmena nije sačuvana. Pokušajte ponovo.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    context.read<LoanBoardBloc>().add(const LoanBoardNoticeAcknowledged());
  }

  void _openDetailSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) =>
          SizedBox(height: MediaQuery.sizeOf(sheetContext).height * 0.7, child: const _DetailSheet()),
    );
  }

  @override
  Widget build(BuildContext context) => LoanBoardShortcuts(
    child: Scaffold(
      appBar: AppBar(title: const Text('Tabla pozajmica'), actions: const [_ReloadButton(), _DebugActions()]),
      body: BlocConsumer<LoanBoardBloc, LoanBoardState>(
        listenWhen: (previous, current) => current is LoanBoardLoaded && current.notice != null,
        listener: (context, state) => _showNotice(context, (state as LoanBoardLoaded).notice!),
        builder: (context, state) => switch (state) {
          LoanBoardLoading() => const LoadingView(),
          LoanBoardFailure() => FailureView(onRetry: () => _bloc.add(const LoanBoardRequested())),
          LoanBoardEmpty() => const EmptyView(title: 'Nema pozajmica.'),
          LoanBoardLoaded() => _LoadedBody(state: state, boardFocus: _boardFocus, onOpenDetail: _openDetailSheet),
        },
      ),
    ),
  );
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.state, required this.boardFocus, required this.onOpenDetail});

  final LoanBoardLoaded state;
  final FocusNode boardFocus;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LoanBoardBloc>();
    return Column(
      children: [
        if (state.isBusy) const LinearProgressIndicator(minHeight: 3) else const SizedBox(height: 3),
        LoanFilterBar(
          filter: state.filter,
          games: state.gameOptions,
          members: state.memberOptions,
          onChanged: (filter) => bloc.add(LoanBoardFilterChanged(filter)),
        ),
        const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < Breakpoints.medium;
              final Widget board;
              if (state.items.isEmpty) {
                board = const EmptyView(title: 'Nema pozajmica za izabrane filtere.');
              } else if (narrow) {
                board = LoanList(
                  items: state.items,
                  selectedId: state.selectedId,
                  focusNode: boardFocus,
                  onSelect: (id) => bloc.add(LoanBoardSelected(id)),
                  onMove: (delta) => bloc.add(LoanBoardSelectionMoved(delta)),
                  onOpen: onOpenDetail,
                );
              } else {
                board = LoanTable(
                  items: state.items,
                  selectedId: state.selectedId,
                  focusNode: boardFocus,
                  onSelect: (id) => bloc.add(LoanBoardSelected(id)),
                  onMove: (delta) => bloc.add(LoanBoardSelectionMoved(delta)),
                );
              }
              if (narrow) return board;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: board),
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: 340,
                    child: LoanDetailPanel(
                      item: state.selected,
                      busy: state.isBusy,
                      onApprove: (id) => bloc.add(LoanApprovalRequested(id)),
                      onReject: (id) => bloc.add(LoanRejectionRequested(id)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DetailSheet extends StatefulWidget {
  const _DetailSheet();

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  bool _closing = false;

  void _close() {
    if (_closing) return;
    _closing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= Breakpoints.medium) _close();
    final bloc = context.read<LoanBoardBloc>();
    return LoanBoardShortcuts(
      child: Focus(
        autofocus: true,
        child: BlocConsumer<LoanBoardBloc, LoanBoardState>(
          listenWhen: (previous, current) => (!previous.isBusy && current.isBusy) || current is! LoanBoardLoaded,
          listener: (context, state) => _close(),
          builder: (context, state) => switch (state) {
            LoanBoardLoaded(:final selected?) => LoanDetailPanel(
              item: selected,
              busy: state.isBusy,
              onApprove: (id) => bloc.add(LoanApprovalRequested(id)),
              onReject: (id) => bloc.add(LoanRejectionRequested(id)),
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

class _ReloadButton extends StatelessWidget {
  const _ReloadButton();

  @override
  Widget build(BuildContext context) => BlocBuilder<LoanBoardBloc, LoanBoardState>(
    buildWhen: (previous, current) => previous.isBusy != current.isBusy,
    builder: (context, state) => IconButton(
      tooltip: 'Osveži',
      icon: const Icon(Icons.refresh),
      onPressed: state.isBusy ? null : () => context.read<LoanBoardBloc>().add(const LoanBoardRequested()),
    ),
  );
}

class _DebugActions extends StatelessWidget {
  const _DebugActions();

  @override
  Widget build(BuildContext context) {
    final fake = context.read<AppDependencies>().fakeLoans;
    if (!kDebugMode || fake == null) return const SizedBox.shrink();
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.medium;
    return BlocBuilder<LoanBoardBloc, LoanBoardState>(
      buildWhen: (previous, current) => previous.isBusy != current.isBusy,
      builder: (context, state) {
        void reload() => context.read<LoanBoardBloc>().add(const LoanBoardRequested());
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            _DebugButton(
              compact: compact,
              icon: Icons.cloud_off_outlined,
              label: 'Simuliraj grešku',
              onPressed: state.isBusy
                  ? null
                  : () {
                      fake.failingRequests = 1;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Sledeći zahtev neće uspeti.')));
                    },
            ),
            _DebugButton(
              compact: compact,
              icon: Icons.inbox_outlined,
              label: 'Simuliraj prazan odgovor',
              onPressed: state.isBusy
                  ? null
                  : () {
                      fake.emptyResponses = 1;
                      reload();
                    },
            ),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }
}

class _DebugButton extends StatelessWidget {
  const _DebugButton({required this.compact, required this.icon, required this.label, required this.onPressed});

  final bool compact;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => compact
      ? IconButton(tooltip: label, onPressed: onPressed, icon: Icon(icon))
      : TextButton.icon(onPressed: onPressed, icon: Icon(icon, size: 18), label: Text(label));
}
