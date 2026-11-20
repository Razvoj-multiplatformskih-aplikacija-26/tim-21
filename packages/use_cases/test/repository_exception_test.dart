import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  test('RepositoryException names its message', () {
    expect(const RepositoryException('Simulated outage').toString(), 'RepositoryException: Simulated outage');
  });

  test('RepositoryException is unavailable unless told otherwise', () {
    expect(const RepositoryException('Simulated outage').failure, RepositoryFailure.unavailable);
    expect(
      const RepositoryException('No answer', failure: RepositoryFailure.unreachable).failure,
      RepositoryFailure.unreachable,
    );
  });
}
