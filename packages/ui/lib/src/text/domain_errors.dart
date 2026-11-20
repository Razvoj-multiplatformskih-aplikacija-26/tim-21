import 'package:domain/domain.dart';

extension DomainErrorMessage on DomainError {
  String get message => switch (this) {
    InvalidLoanDuration(:final min, :final max) => 'Pozajmica traje od $min do $max dana.',
    TooManyActiveLoans(:final max) => 'Najveći dozvoljeni broj aktivnih pozajmica je $max.',
    MemberHasOverdueLoan() => 'Imate pozajmicu koja kasni. Vratite je pre novog zahteva.',
    InvalidTransition() => 'Ova promena stanja pozajmice više nije moguća.',
    NoFreeCopy() => 'Nema slobodne kopije ove igre.',
    NotAllowed() => 'Nemate pravo na ovu radnju.',
    LoanNotFound() => 'Pozajmica nije pronađena.',
  };
}
