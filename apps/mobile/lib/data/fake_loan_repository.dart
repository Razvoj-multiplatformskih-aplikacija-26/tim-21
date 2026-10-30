import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'seed.dart';

final class FakeLoanRepository implements LoanRepository {
  FakeLoanRepository({required Clock clock, this.latency = const Duration(milliseconds: 500)})
    : _loans = seedLoans(clock.now());

  final Duration latency;
  final List<Loan> _loans;
  int failingRequests = 0;
  int emptyResponses = 0;

  Future<void> _roundTrip() async {
    await Future<void>.delayed(latency);
    if (failingRequests > 0) {
      failingRequests--;
      throw const RepositoryException('Simulated outage');
    }
  }

  @override
  Future<List<Loan>> loansOf(MemberId member) async {
    await _roundTrip();
    if (emptyResponses > 0) {
      emptyResponses--;
      return const [];
    }
    return _loans.where((loan) => loan.memberId == member).toList();
  }

  @override
  Future<List<BoardGame>> games() async {
    await _roundTrip();
    return fakeGames;
  }

  @override
  Future<Result<Loan>> cancel(LoanId id) async {
    await _roundTrip();
    final index = _loans.indexWhere((loan) => loan.id == id);
    if (index < 0) throw RepositoryException('Unknown loan ${id.value}');
    final result = changeLoanStatus(_loans[index], const Cancelled());
    if (result case Success(:final value)) _loans[index] = value;
    return result;
  }
}
