import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  testWidgets('app starts on the loans of the signed-in member', (tester) async {
    await tester.pumpWidget(appWith(fakeDependencies()));
    await tester.pumpAndSettle();

    expect(find.text('Moje pozajmice'), findsOneWidget);
    expect(find.text('Na čekanju'), findsOneWidget);
    expect(find.text('Otkaži'), findsNWidgets(2));
  });

  testWidgets('loan request form checks the duration rule from the domain', (tester) async {
    await tester.pumpWidget(appWith(fakeDependencies()));
    await tester.pumpAndSettle();
    await goTo(tester, '/pozajmice/loan-1/nova');

    await tester.enterText(find.byType(TextFormField), '9');
    await tester.tap(find.text('Pošalji zahtev'));
    await tester.pump();

    expect(find.text('Pozajmica traje od 1 do 7 dana.'), findsOneWidget);
  });

  testWidgets('the duration is checked while typing, before the form is sent', (tester) async {
    await tester.pumpWidget(appWith(fakeDependencies()));
    await tester.pumpAndSettle();
    await goTo(tester, '/pozajmice/loan-1/nova');

    await tester.enterText(find.byType(TextFormField), '9');
    await tester.pump();

    expect(find.text('Pozajmica traje od 1 do 7 dana.'), findsOneWidget);
  });

  testWidgets('a rule the repository enforces is shown from the domain error and the list is reloaded', (tester) async {
    await tester.pumpWidget(appWith(fakeDependencies()));
    await tester.pumpAndSettle();
    await goTo(tester, '/pozajmice/loan-1/nova');

    await tester.enterText(find.byType(TextFormField), '3');
    await tester.tap(find.text('Pošalji zahtev'));
    await tester.pumpAndSettle();

    expect(find.text('Imate pozajmicu koja kasni. Vratite je pre novog zahteva.'), findsOneWidget);
    expect(find.text('Moje pozajmice'), findsOneWidget);
    expect(find.text('Na čekanju'), findsOneWidget);
  });

  testWidgets('an unreachable server is reported and the retry button loads again', (tester) async {
    final dependencies = fakeDependencies();
    await tester.pumpWidget(appWith(dependencies));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Simulacija'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simuliraj grešku'));
    await tester.pumpAndSettle();
    expect(find.text('Sledeći zahtev neće uspeti.'), findsOneWidget);
    expect(find.text('Na čekanju'), findsOneWidget);

    await tester.tap(find.byTooltip('Osveži'));
    await tester.pumpAndSettle();
    expect(find.text('Nema veze sa serverom.'), findsOneWidget);

    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pumpAndSettle();
    expect(find.text('Na čekanju'), findsOneWidget);
  });
}
