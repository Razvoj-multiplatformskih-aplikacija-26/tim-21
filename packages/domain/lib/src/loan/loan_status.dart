import 'package:meta/meta.dart';

/// The kind of a [LoanStatus] without its data, so a set of stages can describe "every picked-up loan".
enum LoanStage { pending, approved, pickedUp, overdue, returned, rejected, cancelled }

sealed class LoanStatus {
  const LoanStatus();

  LoanStage get stage => switch (this) {
    Pending() => LoanStage.pending,
    Approved() => LoanStage.approved,
    PickedUp() => LoanStage.pickedUp,
    Overdue() => LoanStage.overdue,
    Returned() => LoanStage.returned,
    Rejected() => LoanStage.rejected,
    Cancelled() => LoanStage.cancelled,
  };

  bool get isActive => switch (this) {
    Pending() || Approved() || PickedUp() || Overdue() => true,
    Returned() || Rejected() || Cancelled() => false,
  };
}

@immutable
final class Pending extends LoanStatus {
  const Pending();

  @override
  bool operator ==(Object other) => other is Pending;

  @override
  int get hashCode => (Pending).hashCode;

  @override
  String toString() => 'Pending';
}

@immutable
final class Approved extends LoanStatus {
  const Approved({required this.pickupDeadline});

  final DateTime pickupDeadline;

  @override
  bool operator ==(Object other) => other is Approved && other.pickupDeadline == pickupDeadline;

  @override
  int get hashCode => Object.hash(Approved, pickupDeadline);

  @override
  String toString() => 'Approved(pickup by $pickupDeadline)';
}

@immutable
final class PickedUp extends LoanStatus {
  const PickedUp({required this.dueAt});

  final DateTime dueAt;

  @override
  bool operator ==(Object other) => other is PickedUp && other.dueAt == dueAt;

  @override
  int get hashCode => Object.hash(PickedUp, dueAt);

  @override
  String toString() => 'PickedUp(due $dueAt)';
}

@immutable
final class Overdue extends LoanStatus {
  const Overdue({required this.dueAt});

  final DateTime dueAt;

  @override
  bool operator ==(Object other) => other is Overdue && other.dueAt == dueAt;

  @override
  int get hashCode => Object.hash(Overdue, dueAt);

  @override
  String toString() => 'Overdue(due $dueAt)';
}

@immutable
final class Returned extends LoanStatus {
  const Returned({required this.returnedAt});

  final DateTime returnedAt;

  @override
  bool operator ==(Object other) => other is Returned && other.returnedAt == returnedAt;

  @override
  int get hashCode => Object.hash(Returned, returnedAt);

  @override
  String toString() => 'Returned(at $returnedAt)';
}

@immutable
final class Rejected extends LoanStatus {
  const Rejected();

  @override
  bool operator ==(Object other) => other is Rejected;

  @override
  int get hashCode => (Rejected).hashCode;

  @override
  String toString() => 'Rejected';
}

@immutable
final class Cancelled extends LoanStatus {
  const Cancelled();

  @override
  bool operator ==(Object other) => other is Cancelled;

  @override
  int get hashCode => (Cancelled).hashCode;

  @override
  String toString() => 'Cancelled';
}

bool canTransition(LoanStatus from, LoanStatus to) => switch ((from, to)) {
  (Pending(), Approved() || Rejected() || Cancelled()) => true,
  (Approved(), PickedUp() || Cancelled()) => true,
  (PickedUp(), Overdue() || Returned()) => true,
  (Overdue(), Returned()) => true,
  _ => false,
};
