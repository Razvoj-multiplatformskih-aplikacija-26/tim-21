import '../errors.dart';
import '../identifiers.dart';
import '../result.dart';
import 'loan.dart';
import 'loan_status.dart';

const maxActiveLoans = 3;
const pickupWindow = Duration(days: 2);

Result<void> checkMemberMayRequest({required MemberId member, required List<Loan> loans, required DateTime now}) {
  final memberLoans = loans.where((loan) => loan.memberId == member);
  if (memberLoans.any((loan) => loan.statusAt(now) is Overdue)) return const Failure(MemberHasOverdueLoan());
  final active = memberLoans.where((loan) => loan.status.isActive).length;
  if (active >= maxActiveLoans) return Failure(TooManyActiveLoans(active));
  return const Success(null);
}

Result<Loan> approveLoan(Loan loan, GameCopyId copy, DateTime now) =>
    switch (changeLoanStatus(loan, Approved(pickupDeadline: now.add(pickupWindow)))) {
      Success(:final value) => Success(value.copyWith(copyId: copy)),
      final Failure<Loan> failure => failure,
    };

Result<Loan> rejectLoan(Loan loan) => changeLoanStatus(loan, const Rejected());
