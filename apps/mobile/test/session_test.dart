import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/my_loans_screen.dart';

import 'support.dart';

void main() {
  testWidgets('without a session the app opens on the login, and a member gets their loans', (tester) async {
    await tester.pumpWidget(appWith(fakeDependencies(signedIn: false)));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Prijavi se'), findsOneWidget);
    expect(find.text('Moje pozajmice'), findsNothing);

    await logIn(tester);

    expect(find.text('Moje pozajmice'), findsOneWidget);
    expect(find.text('Na čekanju'), findsOneWidget);
  });

  testWidgets('a librarian is not let into the mobile app', (tester) async {
    await tester.pumpWidget(appWith(fakeDependencies(user: librarian, signedIn: false)));
    await tester.pumpAndSettle();

    await logIn(tester, username: 'bibliotekar1');

    expect(find.text('Aplikacija je za članove biblioteke.'), findsOneWidget);
    expect(find.text('Moje pozajmice'), findsNothing);
  });

  testWidgets('logging out returns to the login', (tester) async {
    await tester.pumpWidget(appWith(fakeDependencies()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Odjavi se'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Prijavi se'), findsOneWidget);
    expect(find.text('Moje pozajmice'), findsNothing);
  });

  testWidgets('an expired session shows the login with its reason, and signing in again shows the loans', (
    tester,
  ) async {
    await tester.pumpWidget(appWith(fakeDependencies()));
    await tester.pumpAndSettle();

    tester.element(find.byType(MyLoansScreen)).read<SessionBloc>().add(const SessionExpired());
    await tester.pumpAndSettle();

    expect(find.text('Prijava je istekla. Prijavite se ponovo.'), findsOneWidget);

    await logIn(tester);

    expect(find.text('Moje pozajmice'), findsOneWidget);
    expect(find.text('Na čekanju'), findsOneWidget);
  });
}
