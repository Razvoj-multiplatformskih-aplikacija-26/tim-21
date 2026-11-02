import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'seed.dart';

final class FakeLoanDeskRepository implements LoanDeskRepository {
  FakeLoanDeskRepository({required Clock clock, this.latency = const Duration(milliseconds: 700)})
    : _clock = clock,
      _loans = seedLoans(clock.now());

  final Duration latency;
  final Clock _clock;
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
  Future<List<Loan>> allLoans() async {
    await _roundTrip();
    if (emptyResponses > 0) {
      emptyResponses--;
      return const [];
    }
    return List.of(_loans);
  }

  @override
  Future<List<BoardGame>> games() async {
    await _roundTrip();
    return fakeGames;
  }

  @override
  Future<Result<Loan>> approve(LoanId id) => _apply(id, (loan) => approveLoan(loan, _clock.now()));

  @override
  Future<Result<Loan>> reject(LoanId id) => _apply(id, rejectLoan);

  Future<Result<Loan>> _apply(LoanId id, Result<Loan> Function(Loan loan) change) async {
    await _roundTrip();
    final index = _loans.indexWhere((loan) => loan.id == id);
    if (index < 0) throw RepositoryException('Unknown loan ${id.value}');
    final result = change(_loans[index]);
    if (result case Success(:final value)) _loans[index] = value;
    return result;
  }
}
