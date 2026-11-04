import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../widgets/cancel_dialog.dart';
import '../widgets/loan_texts.dart';

class LoanDetailScreen extends StatelessWidget {
  const LoanDetailScreen({super.key, required this.id});

  final LoanId id;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pozajmica')),
    body: BlocBuilder<MyLoansBloc, MyLoansState>(
      builder: (context, state) => switch (state) {
        MyLoansLoading() => const LoadingView(),
        MyLoansFailure() => FailureView(onRetry: () => context.read<MyLoansBloc>().add(const MyLoansRequested())),
        MyLoansEmpty() => const EmptyView(title: 'Pozajmica nije pronađena.'),
        MyLoansLoaded() => switch (state.items.where((item) => item.loan.id == id).firstOrNull) {
          null => const EmptyView(title: 'Pozajmica nije pronađena.'),
          final item => _Detail(item: item, busy: state.isBusy),
        },
      },
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.item, required this.busy});

  final LoanItem item;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final loan = item.loan;
    final deadline = deadlineText(item.status);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(item.gameTitle, style: text.headlineSmall),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: LoanStatusBadge(status: item.status),
        ),
        const SizedBox(height: 16),
        Text('Trajanje: ${durationText(loan.duration)}', style: text.bodyLarge),
        Text('Zatraženo: ${formatDate(loan.requestedAt)}', style: text.bodyLarge),
        Text('Kopija: ${loan.copyId?.value ?? 'nije dodeljena'}', style: text.bodyLarge),
        if (deadline != null) Text(deadline, style: text.bodyLarge),
        const SizedBox(height: 24),
        if (item.canCancel)
          OutlinedButton(
            onPressed: busy ? null : () => confirmCancellation(context, item),
            child: const Text('Otkaži'),
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => context.push('/pozajmice/${loan.id.value}/nova'),
          child: const Text('Pozajmi ponovo'),
        ),
      ],
    );
  }
}
