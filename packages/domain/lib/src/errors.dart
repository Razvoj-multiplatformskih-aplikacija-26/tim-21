import 'package:meta/meta.dart';

import 'loan/loan_status.dart';

sealed class DomainError {
  const DomainError();
}

@immutable
final class InvalidLoanDuration extends DomainError {
  const InvalidLoanDuration(this.days);

  final int days;

  @override
  bool operator ==(Object other) => other is InvalidLoanDuration && other.days == days;

  @override
  int get hashCode => Object.hash(InvalidLoanDuration, days);

  @override
  String toString() => 'InvalidLoanDuration($days)';
}

@immutable
final class TooManyActiveLoans extends DomainError {
  const TooManyActiveLoans(this.active);

  final int active;

  @override
  bool operator ==(Object other) => other is TooManyActiveLoans && other.active == active;

  @override
  int get hashCode => Object.hash(TooManyActiveLoans, active);

  @override
  String toString() => 'TooManyActiveLoans($active)';
}

final class MemberHasOverdueLoan extends DomainError {
  const MemberHasOverdueLoan();

  @override
  String toString() => 'MemberHasOverdueLoan';
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
