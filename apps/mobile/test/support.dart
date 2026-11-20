import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app.dart';
import 'package:mobile/data/seed.dart';
import 'package:mobile/dependencies.dart';
import 'package:mobile/screens/my_loans_screen.dart';

const librarian = User(id: UserId('bibliotekar1'), name: 'Bibliotekar', role: Role.librarian);

AppDependencies fakeDependencies({User user = fakeUser, bool signedIn = true}) =>
    AppDependencies.fake(latency: Duration.zero, user: user, signedIn: signedIn);

Widget appWith(AppDependencies dependencies) => BoardGameApp(dependencies: dependencies);

Future<void> goTo(WidgetTester tester, String location) async {
  GoRouter.of(tester.element(find.byType(MyLoansScreen))).go(location);
  await tester.pumpAndSettle();
}

Future<void> logIn(WidgetTester tester, {String username = 'clan1', String password = 'lozinka'}) async {
  await tester.enterText(find.byType(TextField).at(0), username);
  await tester.enterText(find.byType(TextField).at(1), password);
  await tester.tap(find.text('Prijavi se'));
  await tester.pumpAndSettle();
}
