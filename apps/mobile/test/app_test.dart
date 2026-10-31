import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/dependencies.dart';

void main() {
  testWidgets('app starts on the loans of the fake member', (tester) async {
    await tester.pumpWidget(BoardGameApp(dependencies: AppDependencies.fake(latency: Duration.zero)));
    await tester.pumpAndSettle();

    expect(find.text('Moje pozajmice'), findsOneWidget);
    expect(find.text('Na čekanju'), findsOneWidget);
    expect(find.text('Otkaži'), findsNWidgets(2));
  });
}
