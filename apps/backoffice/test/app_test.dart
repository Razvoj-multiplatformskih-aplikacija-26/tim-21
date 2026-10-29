import 'package:backoffice/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('backoffice starts with its title', (tester) async {
    await tester.pumpWidget(const BackofficeApp());

    expect(find.text('BoardGame Booking · Backoffice'), findsOneWidget);
  });
}
