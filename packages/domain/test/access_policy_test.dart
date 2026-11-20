import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  final anasLoan = loanOf(ana);

  test('a member views only their own loans, a librarian views every loan', () {
    expect(AccessPolicy.canView(anaUser, anasLoan), isTrue);
    expect(AccessPolicy.canView(markoUser, anasLoan), isFalse);
    expect(AccessPolicy.canView(librarian, anasLoan), isTrue);
  });

  test('only a member requests a loan', () {
    expect(AccessPolicy.canRequest(anaUser), isTrue);
    expect(AccessPolicy.canRequest(librarian), isFalse);
  });

  test('a member cancels only their own loan, a librarian cancels none', () {
    expect(AccessPolicy.canCancel(anaUser, anasLoan), isTrue);
    expect(AccessPolicy.canCancel(markoUser, anasLoan), isFalse);
    expect(AccessPolicy.canCancel(librarian, anasLoan), isFalse);
  });

  test('only a librarian approves and rejects', () {
    expect(AccessPolicy.canDecide(librarian), isTrue);
    expect(AccessPolicy.canDecide(anaUser), isFalse);
  });

  test('the mobile app is for members', () {
    expect(AccessPolicy.canUseMobile(anaUser), isTrue);
    expect(AccessPolicy.canUseMobile(librarian), isFalse);
  });

  test('the backoffice is for librarians', () {
    expect(AccessPolicy.canUseBackoffice(librarian), isTrue);
    expect(AccessPolicy.canUseBackoffice(anaUser), isFalse);
  });
}
