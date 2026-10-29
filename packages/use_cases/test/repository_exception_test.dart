import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  test('RepositoryException names its message', () {
    expect(const RepositoryException('Simulated outage').toString(), 'RepositoryException: Simulated outage');
  });
}
