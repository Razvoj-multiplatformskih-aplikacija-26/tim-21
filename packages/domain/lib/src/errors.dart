import 'package:meta/meta.dart';

import 'loan/loan_status.dart';

sealed class DomainError {
  const DomainError();
}

@immutable
final class InvalidLoanDuration extends DomainError {
  const InvalidLoanDuration(this.days, {required this.min, required this.max});

  final int days;
  final int min;
  final int max;

  @override
  bool operator ==(Object other) =>
      other is InvalidLoanDuration && other.days == days && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(InvalidLoanDuration, days, min, max);

  @override
  String toString() => 'InvalidLoanDuration($days, min: $min, max: $max)';
}

@immutable
final class TooManyActiveLoans extends DomainError {
  const TooManyActiveLoans(this.active, {required this.max});

  final int active;
  final int max;

  @override
  bool operator ==(Object other) => other is TooManyActiveLoans && other.active == active && other.max == max;

  @override
  int get hashCode => Object.hash(TooManyActiveLoans, active, max);

  @override
  String toString() => 'TooManyActiveLoans($active, max: $max)';
}

final class MemberHasOverdueLoan extends DomainError {
  const MemberHasOverdueLoan();

  @override
  String toString() => 'MemberHasOverdueLoan';
}

final class NoFreeCopy extends DomainError {
  const NoFreeCopy();

  @override
  String toString() => 'NoFreeCopy';
}

@immutable
final class InvalidTransition extends DomainError {
  const InvalidTransition({required this.from, required this.to});

  final LoanStatus from;
  final LoanStatus to;

  @override
  bool operator ==(Object other) => other is InvalidTransition && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(InvalidTransition, from, to);

  @override
  String toString() => 'InvalidTransition($from -> $to)';
}

final class NotAllowed extends DomainError {
  const NotAllowed();

  @override
  String toString() => 'NotAllowed';
}

final class LoanNotFound extends DomainError {
  const LoanNotFound();

  @override
  String toString() => 'LoanNotFound';
}
