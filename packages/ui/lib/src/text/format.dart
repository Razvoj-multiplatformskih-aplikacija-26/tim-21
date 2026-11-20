import 'package:domain/domain.dart';

String formatDate(DateTime instant) {
  final local = instant.toLocal();
  return '${local.day}. ${local.month}. ${local.year}.';
}

String durationText(LoanDuration duration) => '${duration.days} ${duration.days == 1 ? 'dan' : 'dana'}';

({String label, String date})? deadlineOf(LoanStatus status) => switch (status) {
  Approved(:final pickupDeadline) => (label: 'Preuzeti do', date: formatDate(pickupDeadline)),
  PickedUp(:final dueAt) => (label: 'Vratiti do', date: formatDate(dueAt)),
  Overdue(:final dueAt) => (label: 'Rok je bio', date: formatDate(dueAt)),
  Returned(:final returnedAt) => (label: 'Vraćena', date: formatDate(returnedAt)),
  Pending() || Rejected() || Cancelled() => null,
};

String? deadlineText(LoanStatus status) => switch (deadlineOf(status)) {
  (:final label, :final date) => '$label $date',
  null => null,
};
