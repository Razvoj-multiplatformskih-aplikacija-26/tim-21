import 'package:blocs/blocs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../dependencies.dart';
import '../widgets/cancel_dialog.dart';
import '../widgets/loan_texts.dart';

class MyLoansScreen extends StatelessWidget {
  const MyLoansScreen({super.key});

  void _showNotice(BuildContext context, MyLoansNotice notice) {
    final message = switch (notice) {
      LoanCancelled() => 'Pozajmica je otkazana.',
      CancellationRejected(:final error) => error.message,
      CancellationFailed() => 'Otkazivanje nije uspelo. Pokušajte ponovo.',
      LoanRequestSent() => 'Zahtev je poslat.',
      LoanRequestRejected(:final error) => error.message,
      LoanRequestFailed() => 'Zahtev nije poslat. Pokušajte ponovo.',
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
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sledeći zahtev neće uspeti.')));
            case _DebugAction.emptyNextResponse:
              fake.emptyResponses = 1;
              context.read<MyLoansBloc>().add(const MyLoansRequested());
          }
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
        onCancel: item.canCancel && !state.isBusy ? () => confirmCancellation(context, item) : null,
      );
    },
  );
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({super.key, required this.item, required this.cancelling, required this.onCancel});

  final LoanItem item;
  final bool cancelling;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deadline = deadlineText(item.status);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/pozajmice/${item.loan.id.value}'),
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
              Text('Trajanje: ${durationText(item.loan.duration)}', style: theme.textTheme.bodyMedium),
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
      ),
    );
  }
}
