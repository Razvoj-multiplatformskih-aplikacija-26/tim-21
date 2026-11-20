import 'package:backoffice/app.dart';
import 'package:backoffice/data/seed.dart';
import 'package:backoffice/dependencies.dart';
import 'package:backoffice/screens/loan_board_screen.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _member = User(id: UserId('clan1'), name: 'Član', role: Role.member);

void main() {
  Future<void> pumpApp(WidgetTester tester, AppDependencies dependencies) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(BackofficeApp(dependencies: dependencies));
    await tester.pumpAndSettle();
  }

  AppDependencies fake({User user = fakeLibrarian, bool signedIn = true}) =>
      AppDependencies.fake(latency: Duration.zero, user: user, signedIn: signedIn);

  Future<void> logIn(WidgetTester tester, {String username = 'bibliotekar1'}) async {
    await tester.enterText(find.byType(TextField).at(0), username);
    await tester.enterText(find.byType(TextField).at(1), 'lozinka');
    await tester.tap(find.text('Prijavi se'));
    await tester.pumpAndSettle();
  }

  final loginButton = find.widgetWithText(FilledButton, 'Prijavi se');

  testWidgets('without a session the backoffice opens on the login, and a librarian gets the board', (tester) async {
    await pumpApp(tester, fake(signedIn: false));

    expect(loginButton, findsOneWidget);
    expect(find.text('Tabla pozajmica'), findsNothing);

    await logIn(tester);

    expect(find.text('Tabla pozajmica'), findsOneWidget);
    expect(find.text('Izaberite pozajmicu u tabeli.'), findsOneWidget);
  });

  testWidgets('a member is not let into the backoffice', (tester) async {
    await pumpApp(tester, fake(user: _member, signedIn: false));

    await logIn(tester, username: 'clan1');

    expect(find.text('Backoffice je za osoblje biblioteke.'), findsOneWidget);
    expect(find.text('Tabla pozajmica'), findsNothing);
  });

  testWidgets('logging out from the app bar returns to the login', (tester) async {
    await pumpApp(tester, fake());

    await tester.tap(find.byTooltip('Odjavi se'));
    await tester.pumpAndSettle();

    expect(loginButton, findsOneWidget);
    expect(find.text('Tabla pozajmica'), findsNothing);
  });

  testWidgets('an expired session shows the login with its reason, and signing in again shows the board', (
    tester,
  ) async {
    await pumpApp(tester, fake());

    tester.element(find.byType(LoanBoardScreen)).read<SessionBloc>().add(const SessionExpired());
    await tester.pumpAndSettle();

    expect(find.text('Prijava je istekla. Prijavite se ponovo.'), findsOneWidget);
    expect(find.text('Tabla pozajmica'), findsNothing);

    await logIn(tester);

    expect(find.text('Tabla pozajmica'), findsOneWidget);
  });

  testWidgets('an unreachable server shows the failure view, and refresh stays available', (tester) async {
    final dependencies = fake();
    await pumpApp(tester, dependencies);

    dependencies.fakeLoans!.failingRequests = 1;
    await tester.tap(find.byTooltip('Osveži'));
    await tester.pumpAndSettle();

    expect(find.text('Nema veze sa serverom.'), findsOneWidget);
    expect(find.text('Pokušaj ponovo'), findsOneWidget);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.refresh)).onPressed, isNotNull);

    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pumpAndSettle();
    expect(find.text('Izaberite pozajmicu u tabeli.'), findsOneWidget);
  });
}
