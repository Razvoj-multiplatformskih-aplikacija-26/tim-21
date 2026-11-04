import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/dependencies.dart';
import 'package:mobile/router.dart';

void main() {
  testWidgets('app starts on the loans of the fake member', (tester) async {
    await tester.pumpWidget(BoardGameApp(dependencies: AppDependencies.fake(latency: Duration.zero)));
    await tester.pumpAndSettle();

    expect(find.text('Moje pozajmice'), findsOneWidget);
    expect(find.text('Na čekanju'), findsOneWidget);
    expect(find.text('Otkaži'), findsNWidgets(2));
  });

  testWidgets('loan request form checks the duration rule from the domain', (tester) async {
    await tester.pumpWidget(BoardGameApp(dependencies: AppDependencies.fake(latency: Duration.zero)));
    await tester.pumpAndSettle();
    router.go('/pozajmice/loan-1/nova');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '9');
    await tester.tap(find.text('Pošalji zahtev'));
    await tester.pump();

    expect(find.text('Pozajmica traje od 1 do 7 dana.'), findsOneWidget);
  });

  testWidgets('the duration is checked while typing, before the form is sent', (tester) async {
    await tester.pumpWidget(BoardGameApp(dependencies: AppDependencies.fake(latency: Duration.zero)));
    await tester.pumpAndSettle();
    router.go('/pozajmice/loan-1/nova');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '9');
    await tester.pump();

    expect(find.text('Pozajmica traje od 1 do 7 dana.'), findsOneWidget);
  });

  testWidgets('a simulated failure waits for the next request', (tester) async {
    await tester.pumpWidget(BoardGameApp(dependencies: AppDependencies.fake(latency: Duration.zero)));
    router.go('/');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Simulacija'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simuliraj grešku'));
    await tester.pumpAndSettle();
    expect(find.text('Sledeći zahtev neće uspeti.'), findsOneWidget);
    expect(find.text('Na čekanju'), findsOneWidget);

    await tester.tap(find.byTooltip('Osveži'));
    await tester.pumpAndSettle();
    expect(find.text('Podaci trenutno nisu dostupni.'), findsOneWidget);
  });
}
