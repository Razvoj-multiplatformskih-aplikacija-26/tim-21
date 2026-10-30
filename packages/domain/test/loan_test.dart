import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('LoanDuration', () {
    test('accepts one and seven days', () {
      expect(LoanDuration.parse(1).valueOrNull?.days, 1);
      expect(LoanDuration.parse(7).valueOrNull?.days, 7);
    });

    test('rejects zero and eight days', () {
      expect(LoanDuration.parse(0), const Failure<LoanDuration>(InvalidLoanDuration(0)));
      expect(LoanDuration.parse(8), const Failure<LoanDuration>(InvalidLoanDuration(8)));
    });
  });

  group('statusAt', () {
    final pickedUp = loanOf(ana, status: PickedUp(dueAt: wednesday));

    test('a loan is not overdue at the very moment it is due', () {
      expect(pickedUp.statusAt(wednesday), PickedUp(dueAt: wednesday));
    });

    test('a loan is overdue one second after it is due', () {
      expect(pickedUp.statusAt(wednesday.add(const Duration(seconds: 1))), Overdue(dueAt: wednesday));
    });

    test('other statuses do not depend on the clock', () {
      final approved = Approved(pickupDeadline: wednesday);

      expect(loanOf(ana, status: approved).statusAt(wednesday.add(const Duration(days: 30))), approved);
    });
  });

  group('changeLoanStatus', () {
    test('applies an allowed transition', () {
      final result = changeLoanStatus(loanOf(ana), const Cancelled());

      expect(result.valueOrNull?.status, const Cancelled());
    });

    test('refuses a forbidden transition and names both statuses', () {
      final returned = Returned(returnedAt: wednesday);

      expect(
        changeLoanStatus(loanOf(ana, status: returned), const Cancelled()),
        Failure<Loan>(InvalidTransition(from: returned, to: const Cancelled())),
      );
    });
  });
}
