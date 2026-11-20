import 'package:meta/meta.dart';

import '../errors.dart';
import '../result.dart';

@immutable
final class LoanDuration {
  const LoanDuration._(this.days);

  const LoanDuration.existing(int days) : this._(days);

  static const minDays = 1;
  static const maxDays = 7;

  final int days;

  static Result<LoanDuration> parse(int days) {
    if (days < minDays || days > maxDays) return Failure(InvalidLoanDuration(days, min: minDays, max: maxDays));
    return Success(LoanDuration._(days));
  }

  @override
  bool operator ==(Object other) => other is LoanDuration && other.days == days;

  @override
  int get hashCode => days.hashCode;

  @override
  String toString() => 'LoanDuration($days days)';
}
