import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  Result<void> check(List<Loan> loans) => checkMemberMayRequest(member: ana, loans: loans, now: monday);

  final pending = loanOf(ana);

  test('a member with two active loans may request a third', () {
    expect(check([pending, pending]).isSuccess, isTrue);
  });

  test('a member with three active loans may not request a fourth', () {
    expect(check([pending, pending, pending]), const Failure<void>(TooManyActiveLoans(3)));
  });

  test('finished loans and loans of other members do not count', () {
    final finished = loanOf(ana, status: const Cancelled());
    final others = loanOf(marko);

    expect(check([pending, pending, finished, others, others]).isSuccess, isTrue);
  });

  test('a loan past its due date blocks new requests', () {
    final late = loanOf(ana, status: PickedUp(dueAt: monday.subtract(const Duration(days: 1))));

    expect(check([late]), const Failure<void>(MemberHasOverdueLoan()));
  });

  test('being overdue is reported before the limit', () {
    final late = loanOf(ana, status: PickedUp(dueAt: monday.subtract(const Duration(days: 1))));

    expect(check([late, pending, pending]), const Failure<void>(MemberHasOverdueLoan()));
  });
}
