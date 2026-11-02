import 'package:domain/domain.dart';

abstract interface class LoanDeskRepository {
  Future<List<Loan>> allLoans();

  Future<List<BoardGame>> games();

  Future<Result<Loan>> approve(LoanId id);

  Future<Result<Loan>> reject(LoanId id);
}
