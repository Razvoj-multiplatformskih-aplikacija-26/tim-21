import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  group('domain error messages take the limit from the error', () {
    test('loan duration shows the bounds the server sent', () {
      expect(const InvalidLoanDuration(12, min: 1, max: 10).message, 'Pozajmica traje od 1 do 10 dana.');
    });

    test('active loans show the maximum the server sent', () {
      expect(const TooManyActiveLoans(5, max: 5).message, 'Najveći dozvoljeni broj aktivnih pozajmica je 5.');
    });
  });

  group('failure messages', () {
    String messageFor(RepositoryFailure failure) => failureMessage(RepositoryException('test', failure: failure));

    test('name each kind of failure', () {
      expect(messageFor(RepositoryFailure.unreachable), 'Nema veze sa serverom.');
      expect(messageFor(RepositoryFailure.serverError), 'Greška na serveru.');
      expect(messageFor(RepositoryFailure.refused), 'Server nije prihvatio zahtev.');
      expect(messageFor(RepositoryFailure.sessionExpired), 'Prijava je istekla. Prijavite se ponovo.');
      expect(messageFor(RepositoryFailure.unavailable), 'Podaci trenutno nisu dostupni.');
    });

    test('an unknown cause falls back to a general message', () {
      expect(failureMessage(null), 'Podaci trenutno nisu dostupni.');
    });
  });

  group('sign-out messages', () {
    String? messageFor(SignOutReason? reason) => signOutMessage(reason, roleNotAllowed: mobileRoleNotAllowedMessage);

    test('name each reason the session ended', () {
      expect(messageFor(SignOutReason.expired), 'Prijava je istekla. Prijavite se ponovo.');
      expect(messageFor(SignOutReason.unreachable), 'Nema veze sa serverom.');
      expect(messageFor(SignOutReason.roleNotAllowed), 'Aplikacija je za članove biblioteke.');
    });

    test('each app names the role it admits', () {
      expect(
        signOutMessage(SignOutReason.roleNotAllowed, roleNotAllowed: backofficeRoleNotAllowedMessage),
        'Backoffice je za osoblje biblioteke.',
      );
    });

    test('a deliberate log-out or a first start shows nothing', () {
      expect(messageFor(SignOutReason.loggedOut), isNull);
      expect(messageFor(null), isNull);
    });
  });
}
