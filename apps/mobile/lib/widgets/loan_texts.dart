import 'package:domain/domain.dart';
import 'package:ui/ui.dart';

String? deadlineText(LoanStatus status) => switch (status) {
  Approved(:final pickupDeadline) => 'Preuzeti do ${formatDate(pickupDeadline)}',
  PickedUp(:final dueAt) => 'Vratiti do ${formatDate(dueAt)}',
  Overdue(:final dueAt) => 'Rok je bio ${formatDate(dueAt)}',
  Returned(:final returnedAt) => 'Vraćena ${formatDate(returnedAt)}',
  Pending() || Rejected() || Cancelled() => null,
};

String durationText(LoanDuration duration) => '${duration.days} ${duration.days == 1 ? 'dan' : 'dana'}';
