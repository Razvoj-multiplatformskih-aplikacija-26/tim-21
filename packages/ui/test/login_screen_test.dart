import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

const _member = User(id: UserId('clan1'), name: 'Ana Petrović', role: Role.member);

final class _Sessions implements SessionRepository {
  @override
  Future<User?> logIn({required String username, required String password}) async =>
      username == 'clan1' && password == 'demo' ? _member : null;

  @override
  Future<User?> current() async => null;

  @override
  Future<void> logOut() async {}

  @override
  Stream<void> get expirations => const Stream.empty();
}

void main() {
  Widget loginScreen({SignOutReason? reason, void Function(User user)? onSignedIn, VoidCallback? onRetry}) =>
      MaterialApp(
        home: LoginScreen(
          title: 'BoardGame Booking',
          sessions: _Sessions(),
          onSignedIn: onSignedIn ?? (_) {},
          onRetry: onRetry ?? () {},
          roleNotAllowedMessage: mobileRoleNotAllowedMessage,
          reason: reason,
        ),
      );

  Future<void> submit(WidgetTester tester, {required String username, required String password}) async {
    await tester.enterText(find.widgetWithText(TextField, 'Korisničko ime'), username);
    await tester.enterText(find.widgetWithText(TextField, 'Lozinka'), password);
    await tester.tap(find.text('Prijavi se'));
    await tester.pumpAndSettle();
  }

  testWidgets('says why the previous session ended', (tester) async {
    await tester.pumpWidget(loginScreen(reason: SignOutReason.roleNotAllowed));
    expect(find.text('Aplikacija je za članove biblioteke.'), findsOneWidget);
  });

  testWidgets('shows an expired login', (tester) async {
    await tester.pumpWidget(loginScreen(reason: SignOutReason.expired));
    expect(find.text('Prijava je istekla. Prijavite se ponovo.'), findsOneWidget);
    expect(find.text('Pokušaj ponovo'), findsNothing);
  });

  testWidgets('an unreachable server offers a retry that restores the saved login', (tester) async {
    var retries = 0;
    await tester.pumpWidget(loginScreen(reason: SignOutReason.unreachable, onRetry: () => retries++));

    expect(find.text('Nema veze sa serverom.'), findsOneWidget);
    await tester.tap(find.text('Pokušaj ponovo'));
    expect(retries, 1);
  });

  testWidgets('wrong credentials show a message and do not sign in', (tester) async {
    User? signedIn;
    await tester.pumpWidget(loginScreen(onSignedIn: (user) => signedIn = user));
    await submit(tester, username: 'clan1', password: 'pogresna');
    expect(find.text('Pogrešno korisničko ime ili lozinka.'), findsOneWidget);
    expect(signedIn, isNull);
  });

  testWidgets('correct credentials hand the user to the app', (tester) async {
    User? signedIn;
    await tester.pumpWidget(loginScreen(onSignedIn: (user) => signedIn = user));
    await submit(tester, username: 'clan1', password: 'demo');
    expect(signedIn, _member);
  });
}
