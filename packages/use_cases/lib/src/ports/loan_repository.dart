import 'package:domain/domain.dart';

abstract interface class LoanRepository {
  Future<List<Loan>> loansOf(MemberId member);

  Future<List<BoardGame>> games();

  Future<Result<Loan>> cancel(LoanId id);
}
