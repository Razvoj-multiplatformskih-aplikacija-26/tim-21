import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_loan_repository.dart';
import 'data/seed.dart';

final class AppDependencies {
  AppDependencies({required this.loans, required this.clock, required this.member, this.fakeLoans});

  factory AppDependencies.fake({Clock clock = const SystemClock(), Duration? latency}) {
    final loans = latency == null
        ? FakeLoanRepository(clock: clock)
        : FakeLoanRepository(clock: clock, latency: latency);
    return AppDependencies(loans: loans, clock: clock, member: fakeMember, fakeLoans: loans);
  }

  final LoanRepository loans;
  final Clock clock;
  final MemberId member;

  final FakeLoanRepository? fakeLoans;
}
