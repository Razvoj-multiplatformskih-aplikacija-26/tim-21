import 'package:api_client/api_client.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_loan_desk_repository.dart';
import 'data/fake_sessions.dart';
import 'data/seed.dart';

final class AppDependencies {
  AppDependencies({required this.loans, required this.sessions, required this.clock, this.fakeLoans});

  factory AppDependencies.server({
    required Uri baseUri,
    required TokenStore tokens,
    Clock clock = const SystemClock(),
  }) {
    final api = ApiClient(baseUri: baseUri, tokens: tokens);
    return AppDependencies(loans: HttpLoanDeskRepository(api), sessions: HttpSessionRepository(api), clock: clock);
  }

  factory AppDependencies.fake({
    Clock clock = const SystemClock(),
    Duration? latency,
    User user = fakeLibrarian,
    bool signedIn = true,
  }) {
    final loans = latency == null
        ? FakeLoanDeskRepository(clock: clock)
        : FakeLoanDeskRepository(clock: clock, latency: latency);
    return AppDependencies(
      loans: loans,
      sessions: FakeSessions(user, signedIn: signedIn),
      clock: clock,
      fakeLoans: loans,
    );
  }

  final LoanDeskRepository loans;
  final SessionRepository sessions;
  final Clock clock;

  final FakeLoanDeskRepository? fakeLoans;
}
