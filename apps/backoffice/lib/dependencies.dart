import 'package:use_cases/use_cases.dart';

import 'data/fake_loan_desk_repository.dart';

final class AppDependencies {
  AppDependencies({required this.loans, required this.clock, this.fakeLoans});

  factory AppDependencies.fake({Clock clock = const SystemClock(), Duration? latency}) {
    final loans = latency == null
        ? FakeLoanDeskRepository(clock: clock)
        : FakeLoanDeskRepository(clock: clock, latency: latency);
    return AppDependencies(loans: loans, clock: clock, fakeLoans: loans);
  }

  final LoanDeskRepository loans;
  final Clock clock;

  final FakeLoanDeskRepository? fakeLoans;
}
