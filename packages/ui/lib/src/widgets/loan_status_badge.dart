import 'package:design_tokens/design_tokens.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

extension LoanStatusLabel on LoanStatus {
  String get label => switch (this) {
    Pending() => 'Na čekanju',
    Approved() => 'Odobrena',
    PickedUp() => 'Preuzeta',
    Overdue() => 'Kasni',
    Returned() => 'Vraćena',
    Rejected() => 'Odbijena',
    Cancelled() => 'Otkazana',
  };
}

class LoanStatusBadge extends StatelessWidget {
  const LoanStatusBadge({super.key, required this.status});

  final LoanStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.brightness == Brightness.dark ? StatusColorTokens.dark : StatusColorTokens.light;
    final (background, foreground) = switch (status) {
      Pending() => (tokens.pending, tokens.onPending),
      Approved() => (tokens.approved, tokens.onApproved),
      PickedUp() => (tokens.pickedUp, tokens.onPickedUp),
      Overdue() => (tokens.overdue, tokens.onOverdue),
      Returned() => (tokens.returned, tokens.onReturned),
      Rejected() => (tokens.rejected, tokens.onRejected),
      Cancelled() => (tokens.cancelled, tokens.onCancelled),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
      decoration: BoxDecoration(color: Color(background), borderRadius: BorderRadius.circular(Radii.pill)),
      child: Text(status.label, style: theme.textTheme.labelMedium?.copyWith(color: Color(foreground))),
    );
  }
}
