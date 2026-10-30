import 'package:meta/meta.dart';

import '../errors.dart';
import '../identifiers.dart';
import '../result.dart';
import 'loan_duration.dart';
import 'loan_status.dart';

@immutable
final class Loan {
  const Loan({
    required this.id,
    required this.memberId,
    required this.gameId,
    required this.duration,
    required this.requestedAt,
    this.status = const Pending(),
    this.copyId,
  });

  final LoanId id;
  final MemberId memberId;
  final BoardGameId gameId;
  final LoanDuration duration;
  final DateTime requestedAt;
  final LoanStatus status;
  final GameCopyId? copyId;

  // Nobody records that a loan became overdue: it follows from the due date and the clock.
  LoanStatus statusAt(DateTime now) => switch (status) {
    PickedUp(:final dueAt) when now.isAfter(dueAt) => Overdue(dueAt: dueAt),
    final current => current,
  };

  Loan copyWith({LoanStatus? status, GameCopyId? copyId}) => Loan(
    id: id,
    memberId: memberId,
    gameId: gameId,
    duration: duration,
    requestedAt: requestedAt,
    status: status ?? this.status,
    copyId: copyId ?? this.copyId,
  );

  @override
  bool operator ==(Object other) =>
      other is Loan &&
      other.id == id &&
      other.memberId == memberId &&
      other.gameId == gameId &&
      other.duration == duration &&
      other.requestedAt == requestedAt &&
      other.status == status &&
      other.copyId == copyId;

  @override
  int get hashCode => Object.hash(id, memberId, gameId, duration, requestedAt, status, copyId);

  @override
  String toString() => 'Loan($id, member $memberId, game $gameId, $status)';
}

Result<Loan> changeLoanStatus(Loan loan, LoanStatus next) {
  if (!canTransition(loan.status, next)) return Failure(InvalidTransition(from: loan.status, to: next));
  return Success(loan.copyWith(status: next));
}
