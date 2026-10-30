import 'package:domain/domain.dart';

// Implementations throw RepositoryException when the data cannot be reached.
abstract interface class LoanRepository {
  Future<List<Loan>> loansOf(MemberId member);

  Future<List<BoardGame>> games();

  // Whoever holds the data decides, so a stale client still gets a refusal it can show.
  Future<Result<Loan>> cancel(LoanId id);
}
