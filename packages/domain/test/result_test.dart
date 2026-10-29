import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test('Success carries its value and compares by value', () {
    const result = Success(3);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 3);
    expect(result.errorOrNull, isNull);
    expect(result, const Success(3));
  });
}
