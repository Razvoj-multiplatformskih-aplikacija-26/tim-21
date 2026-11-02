import 'package:blocs/blocs.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

class LoanDetailPanel extends StatelessWidget {
  const LoanDetailPanel({
    super.key,
    required this.item,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final LoanBoardItem? item;
  final bool busy;
  final ValueChanged<LoanId> onApprove;
  final ValueChanged<LoanId> onReject;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = this.item;
    return Semantics(
      container: true,
      label: 'Detalj pozajmice',
      child: Material(
        color: scheme.surfaceContainerLow,
        child: item == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.xxl),
                  child: Text(
                    'Izaberite pozajmicu u tabeli.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              )
            : _Detail(item: item, busy: busy, onApprove: onApprove, onReject: onReject),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.item, required this.busy, required this.onApprove, required this.onReject});

  final LoanBoardItem item;
  final bool busy;
  final ValueChanged<LoanId> onApprove;
  final ValueChanged<LoanId> onReject;

  (String, String)? get _statusDate => switch (item.status) {
    Approved(:final pickupDeadline) => ('Preuzeti do', formatDate(pickupDeadline)),
    PickedUp(:final dueAt) => ('Vratiti do', formatDate(dueAt)),
    Overdue(:final dueAt) => ('Rok je bio', formatDate(dueAt)),
    Returned(:final returnedAt) => ('Vraćena', formatDate(returnedAt)),
    Pending() || Rejected() || Cancelled() => null,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loan = item.loan;
    final days = loan.duration.days;
    final statusDate = _statusDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.xl, Spacing.xl, Spacing.md),
          child: Semantics(header: true, child: Text(item.gameTitle, style: theme.textTheme.headlineSmall)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
          child: Align(
            alignment: Alignment.centerLeft,
            child: LoanStatusBadge(status: item.status),
          ),
        ),
        const SizedBox(height: Spacing.xl),
        Expanded(
          child: SelectionArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
              children: [
                _Field(label: 'Član', value: loan.memberId.value),
                _Field(label: 'Kopija', value: loan.copyId?.value ?? 'Nije dodeljena'),
                _Field(label: 'Trajanje', value: '$days ${days == 1 ? 'dan' : 'dana'}'),
                _Field(label: 'Zatraženo', value: formatDate(loan.requestedAt)),
                if (statusDate case (final label, final value)) _Field(label: label, value: value),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Tooltip(
                message: 'Odobri (O)',
                child: FilledButton.icon(
                  onPressed: item.canApprove && !busy ? () => onApprove(loan.id) : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Odobri'),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Tooltip(
                message: 'Odbij (R)',
                child: FilledButton.tonalIcon(
                  onPressed: item.canReject && !busy ? () => onReject(loan.id) : null,
                  icon: const Icon(Icons.close),
                  label: const Text('Odbij'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(value, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
