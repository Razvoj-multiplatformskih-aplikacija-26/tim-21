import 'package:domain/domain.dart';

extension DomainErrorMessage on DomainError {
  String get message => switch (this) {
    InvalidLoanDuration() => 'Pozajmica traje od ${LoanDuration.minDays} do ${LoanDuration.maxDays} dana.',
    TooManyActiveLoans() => 'Možete imati najviše $maxActiveLoans aktivne pozajmice.',
    MemberHasOverdueLoan() => 'Imate pozajmicu koja kasni. Vratite je pre novog zahteva.',
    InvalidTransition() => 'Ova promena stanja pozajmice više nije moguća.',
  };
}
