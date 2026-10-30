import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../dependencies.dart';

class MyLoansScreen extends StatelessWidget {
  const MyLoansScreen({super.key});

  void _showNotice(BuildContext context, MyLoansNotice notice) {
    final message = switch (notice) {
      LoanCancelled() => 'Pozajmica je otkazana.',
      CancellationRejected(:final error) => error.message,
      CancellationFailed() => 'Otkazivanje nije uspelo. Pokušajte ponovo.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    context.read<MyLoansBloc>().add(const MyLoansNoticeAcknowledged());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Moje pozajmice'), actions: const [_ReloadButton(), _DebugMenu()]),
    body: BlocConsumer<MyLoansBloc, MyLoansState>(
      listenWhen: (previous, current) => current is MyLoansLoaded && current.notice != null,
      listener: (context, state) => _showNotice(context, (state as MyLoansLoaded).notice!),
      builder: (context, state) => switch (state) {
        MyLoansLoading() => const LoadingView(),
        MyLoansFailure() => FailureView(onRetry: () => context.read<MyLoansBloc>().add(const MyLoansRequested())),
        MyLoansEmpty() => const EmptyView(title: 'Nemate pozajmica.'),
        MyLoansLoaded() => _LoanList(state: state),
      },
    ),
  );
}

class _ReloadButton extends StatelessWidget {
  const _ReloadButton();

  @override
  Widget build(BuildContext context) => BlocBuilder<MyLoansBloc, MyLoansState>(
    builder: (context, state) => IconButton(
      tooltip: 'Osveži',
      icon: const Icon(Icons.refresh),
      onPressed: state.isBusy ? null : () => context.read<MyLoansBloc>().add(const MyLoansRequested()),
    ),
  );
}

enum _DebugAction { failNextRequest, emptyNextResponse }

class _DebugMenu extends StatelessWidget {
  const _DebugMenu();

  @override
  Widget build(BuildContext context) {
    final fake = context.read<AppDependencies>().fakeLoans;
    if (!kDebugMode || fake == null) return const SizedBox.shrink();
    return BlocBuilder<MyLoansBloc, MyLoansState>(
      builder: (context, state) => PopupMenuButton<_DebugAction>(
        tooltip: 'Simulacija',
        enabled: !state.isBusy,
        onSelected: (action) {
          switch (action) {
            case _DebugAction.failNextRequest:
              fake.failingRequests = 1;
            case _DebugAction.emptyNextResponse:
              fake.emptyResponses = 1;
          }
          context.read<MyLoansBloc>().add(const MyLoansRequested());
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: _DebugAction.failNextRequest, child: Text('Simuliraj grešku')),
          PopupMenuItem(value: _DebugAction.emptyNextResponse, child: Text('Simuliraj prazan odgovor')),
        ],
      ),
    );
  }
}

class _LoanList extends StatelessWidget {
  const _LoanList({required this.state});

  final MyLoansLoaded state;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: state.items.length,
    itemBuilder: (context, index) {
      final item = state.items[index];
      return _LoanCard(
        key: ValueKey(item.loan.id.value),
        item: item,
        cancelling: state.isCancelling(item),
        onCancel: item.canCancel && !state.isBusy ? () => _confirmCancellation(context, item) : null,
      );
    },
  );
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({super.key, required this.item, required this.cancelling, required this.onCancel});

  final LoanItem item;
  final bool cancelling;
  final VoidCallback? onCancel;

  String? get _deadline => switch (item.status) {
    Approved(:final pickupDeadline) => 'Preuzeti do ${formatDate(pickupDeadline)}',
    PickedUp(:final dueAt) => 'Vratiti do ${formatDate(dueAt)}',
    Overdue(:final dueAt) => 'Rok je bio ${formatDate(dueAt)}',
    Returned(:final returnedAt) => 'Vraćena ${formatDate(returnedAt)}',
    Pending() || Rejected() || Cancelled() => null,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deadline = _deadline;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(item.gameTitle, style: theme.textTheme.titleMedium)),
                const SizedBox(width: 8),
                LoanStatusBadge(status: item.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Trajanje: ${item.loan.duration.days} ${item.loan.duration.days == 1 ? 'dan' : 'dana'}',
              style: theme.textTheme.bodyMedium,
            ),
            if (deadline != null) Text(deadline, style: theme.textTheme.bodyMedium),
            if (cancelling)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
                ),
              )
            else if (item.canCancel)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: onCancel, child: const Text('Otkaži')),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmCancellation(BuildContext context, LoanItem item) async {
  final bloc = context.read<MyLoansBloc>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Otkazati pozajmicu?'),
      content: Text('${item.gameTitle}. Ovo ne može da se vrati.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Odustani')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Otkaži pozajmicu')),
      ],
    ),
  );
  if (confirmed != true) return;
  bloc.add(LoanCancellationRequested(item.loan.id));
}
