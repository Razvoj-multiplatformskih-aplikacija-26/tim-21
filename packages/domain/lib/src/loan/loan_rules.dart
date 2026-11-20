import '../availability.dart';
import '../errors.dart';
import '../identifiers.dart';
import '../inventory/game_copy.dart';
import '../result.dart';
import 'loan.dart';
import 'loan_status.dart';

const maxActiveLoans = 3;
const pickupWindow = Duration(days: 2);

Result<void> checkMemberMayRequest({required MemberId member, required List<Loan> loans, required DateTime now}) {
  final memberLoans = loans.where((loan) => loan.memberId == member);
  if (memberLoans.any((loan) => loan.statusAt(now) is Overdue)) return const Failure(MemberHasOverdueLoan());
  final active = memberLoans.where((loan) => loan.status.isActive).length;
  if (active >= maxActiveLoans) return Failure(TooManyActiveLoans(active, max: maxActiveLoans));
  return const Success(null);
}

Result<Loan> approveWithCopy({
  required Loan loan,
  required List<GameCopy> copies,
  required List<Loan> loans,
  required DateTime now,
}) {
  final approved = Approved(pickupDeadline: now.add(pickupWindow));
  if (!canTransition(loan.status, approved)) return Failure(InvalidTransition(from: loan.status, to: approved));
  return switch (assignCopy(game: loan.gameId, copies: copies, loans: loans)) {
    Success(value: final copy) => Success(loan.copyWith(status: approved, copyId: copy)),
    Failure(:final error) => Failure(error),
  };
}

Result<Loan> rejectLoan(Loan loan) => changeLoanStatus(loan, const Rejected());
