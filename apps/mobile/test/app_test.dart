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
}
