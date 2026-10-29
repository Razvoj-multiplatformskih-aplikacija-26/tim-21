import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';

void main() {
  testWidgets('app starts with its title', (tester) async {
    await tester.pumpWidget(const BoardGameApp());

    expect(find.text('BoardGame Booking'), findsOneWidget);
  });
}
