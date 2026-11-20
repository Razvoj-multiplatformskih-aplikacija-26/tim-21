import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' show ServerException;
import 'package:use_cases/use_cases.dart';

import 'loan_store.dart';

final class PostgresLoans implements LoanRepository, LoanDeskRepository {
  PostgresLoans(this._store, {required this.clock});

  static const deskHistory = Duration(days: 30);

  final LoanStore _store;
  final Clock clock;

  @override
  Future<List<BoardGame>> games() => _store.games();

  @override
  Future<List<Loan>> loansOf(MemberId member) => _store.loansOf(member);

  @override
  Future<List<Loan>> allLoans() => _store.deskLoans(since: clock.now().subtract(deskHistory));

  Future<Loan?> find(LoanId id) => _store.find(id);

  @override
  Future<Result<Loan>> request({
    required MemberId member,
    required BoardGameId game,
    required LoanDuration duration,
  }) async {
    final now = clock.now();
    final check = checkMemberMayRequest(member: member, loans: await _store.loansOf(member), now: now);
    if (check case Failure(:final error)) return Failure(error);
    return Success(await _store.insert(member: member, game: game, duration: duration, requestedAt: now));
  }

  @override
  Future<Result<Loan>> cancel(LoanId id) => _change(id, (loan) => changeLoanStatus(loan, const Cancelled()));

  @override
  Future<Result<Loan>> reject(LoanId id) => _change(id, rejectLoan);

  @override
  Future<Result<Loan>> approve(LoanId id) async {
    final found = await _store.find(id);
    if (found == null) return const Failure(LoanNotFound());
    var loan = found;
    final copies = await _store.copiesOf(loan.gameId);
    for (var attempt = 0; attempt <= copies.length; attempt++) {
      final approved = approveWithCopy(
        loan: loan,
        copies: copies,
        loans: await _store.activeLoansOfGame(loan.gameId),
        now: clock.now(),
      );
      if (approved case Failure()) return approved;
      try {
        return await _save(approved.valueOrNull!, from: loan.status);
      } on ServerException catch (error) {
        if (error.code != uniqueViolation || error.constraintName != copyConstraint) rethrow;
      }
      final fresh = await _store.find(id);
      if (fresh == null) return const Failure(LoanNotFound());
      loan = fresh;
    }
    return const Failure(NoFreeCopy());
  }

  Future<Result<Loan>> _change(LoanId id, Result<Loan> Function(Loan loan) rule) async {
    final loan = await _store.find(id);
    if (loan == null) return const Failure(LoanNotFound());
    return switch (rule(loan)) {
      Success(value: final changed) => _save(changed, from: loan.status),
      final Failure<Loan> failure => failure,
    };
  }

  Future<Result<Loan>> _save(Loan changed, {required LoanStatus from}) async {
    if (await _store.changeStatus(changed, from: from)) return Success(changed);
    final current = await _store.find(changed.id);
    if (current == null) return const Failure(LoanNotFound());
    return Failure(InvalidTransition(from: current.status, to: changed.status));
  }
}
