import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

import 'loan_mapping.dart';

extension DomainErrorMapping on DomainError {
  ProblemDto toProblem() => switch (this) {
    InvalidLoanDuration(:final days, :final min, :final max) => ProblemDto(
      status: 422,
      code: ErrorCodes.invalidLoanDuration,
      title: 'Invalid loan duration',
      value: days,
      min: min,
      max: max,
    ),
    TooManyActiveLoans(:final active, :final max) => ProblemDto(
      status: 422,
      code: ErrorCodes.tooManyActiveLoans,
      title: 'Too many active loans',
      value: active,
      max: max,
    ),
    MemberHasOverdueLoan() => const ProblemDto(
      status: 422,
      code: ErrorCodes.memberHasOverdueLoan,
      title: 'Member has an overdue loan',
    ),
    NoFreeCopy() => const ProblemDto(status: 409, code: ErrorCodes.noFreeCopy, title: 'No free copy'),
    InvalidTransition(:final from, :final to) => ProblemDto(
      status: 409,
      code: ErrorCodes.invalidTransition,
      title: 'Invalid transition',
      from: from.toDto(),
      to: to.toDto(),
    ),
    NotAllowed() => const ProblemDto(status: 403, code: ErrorCodes.notAllowed, title: 'Not allowed'),
    LoanNotFound() => const ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'Not found'),
  };
}

extension ProblemMapping on ProblemDto {
  DomainError? toDomainError() => switch (this) {
    ProblemDto(code: ErrorCodes.invalidLoanDuration, :final value?, :final min?, :final max?) => InvalidLoanDuration(
      value,
      min: min,
      max: max,
    ),
    ProblemDto(code: ErrorCodes.tooManyActiveLoans, :final value?, :final max?) => TooManyActiveLoans(value, max: max),
    ProblemDto(code: ErrorCodes.memberHasOverdueLoan) => const MemberHasOverdueLoan(),
    ProblemDto(code: ErrorCodes.noFreeCopy) => const NoFreeCopy(),
    ProblemDto(code: ErrorCodes.invalidTransition, :final from?, :final to?) => InvalidTransition(
      from: from.toDomain(),
      to: to.toDomain(),
    ),
    ProblemDto(code: ErrorCodes.notAllowed) => const NotAllowed(),
    ProblemDto(code: ErrorCodes.notFound) => const LoanNotFound(),
    _ => null,
  };
}
