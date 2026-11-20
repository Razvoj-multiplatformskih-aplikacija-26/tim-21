import 'dart:async';
import 'dart:convert';

import 'package:api_client/api_client.dart';
import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

ApiClient clientOver(MockClient server, {TokenStore? tokens, Duration timeout = const Duration(seconds: 10)}) =>
    ApiClient(
      baseUri: Uri.parse('http://localhost:8080'),
      tokens: tokens,
      httpClient: server,
      keepsSessionInCookie: false,
      timeout: timeout,
    );

http.Response problemResponse(ProblemDto problem) =>
    http.Response(jsonEncode(problem.toJson()), problem.status, headers: {'content-type': ProblemDto.mediaType});

http.Response jsonResponse(Object? json, {int status = 200}) =>
    http.Response(jsonEncode(json), status, headers: {'content-type': 'application/json'});

LoanDto pendingLoanDto() => LoanDto(
  id: 'l-1',
  memberId: 'clan1',
  gameId: 'g-catan',
  durationDays: 3,
  requestedAt: DateTime.utc(2026, 11, 20, 12),
  status: const LoanStatusDto(kind: LoanStatusDto.pending),
);

Future<Result<Loan>> requestCatan(ApiClient api, {int days = 3}) => HttpLoanRepository(
  api,
).request(member: const MemberId('clan1'), game: const BoardGameId('g-catan'), duration: LoanDuration.existing(days));

Matcher throwsFailure(RepositoryFailure failure) =>
    throwsA(isA<RepositoryException>().having((e) => e.failure, 'failure', failure));

void main() {
  group('2xx', () {
    test('a loan request sends the token and only the game and duration, and returns the domain loan', () async {
      final tokens = MemoryTokenStore();
      await tokens.write('token-of-clan1');
      final server = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, ApiPaths.loans);
        expect(request.headers['Authorization'], 'Bearer token-of-clan1');
        expect(jsonDecode(request.body), {'gameId': 'g-catan', 'durationDays': 3});
        return jsonResponse(pendingLoanDto().toJson(), status: 201);
      });

      final result = await requestCatan(clientOver(server, tokens: tokens));

      final loan = result.valueOrNull!;
      expect(loan.id, const LoanId('l-1'));
      expect(loan.memberId, const MemberId('clan1'));
      expect(loan.duration, const LoanDuration.existing(3));
      expect(loan.status, isA<Pending>());
    });

    test('the member\'s loans come from /me/loans, without the member in the request', () async {
      final server = MockClient((request) async {
        expect(request.url.path, ApiPaths.myLoans);
        expect(request.url.query, isEmpty);
        return jsonResponse([pendingLoanDto().toJson()]);
      });

      final loans = await HttpLoanRepository(clientOver(server)).loansOf(const MemberId('clan1'));

      expect(loans.map((loan) => loan.id), [const LoanId('l-1')]);
    });

    test('the desk approves through its own path and reads the approved loan', () async {
      final deadline = DateTime.utc(2026, 11, 22, 12);
      final server = MockClient((request) async {
        expect(request.url.path, ApiPaths.approval('l-1'));
        final approved = LoanDto(
          id: 'l-1',
          memberId: 'clan1',
          gameId: 'g-catan',
          durationDays: 3,
          requestedAt: DateTime.utc(2026, 11, 20, 12),
          status: LoanStatusDto(kind: LoanStatusDto.approved, pickupDeadline: deadline),
          copyId: 'c-catan-1',
        );
        return jsonResponse(approved.toJson());
      });

      final result = await HttpLoanDeskRepository(clientOver(server)).approve(const LoanId('l-1'));

      expect(result.valueOrNull!.status, Approved(pickupDeadline: deadline));
      expect(result.valueOrNull!.copyId, const GameCopyId('c-catan-1'));
    });
  });

  group('a rule that said no', () {
    test('422 invalid-loan-duration carries the server\'s limits, not the client\'s constants', () async {
      final server = MockClient(
        (request) async => problemResponse(
          const ProblemDto(status: 422, code: ErrorCodes.invalidLoanDuration, title: 'x', value: 6, min: 1, max: 5),
        ),
      );

      final result = await requestCatan(clientOver(server), days: 6);

      expect(result, const Failure<Loan>(InvalidLoanDuration(6, min: 1, max: 5)));
    });

    test('422 too-many-active-loans carries the server\'s max', () async {
      final server = MockClient(
        (request) async => problemResponse(
          const ProblemDto(status: 422, code: ErrorCodes.tooManyActiveLoans, title: 'x', value: 2, max: 2),
        ),
      );

      final result = await requestCatan(clientOver(server));

      expect(result, const Failure<Loan>(TooManyActiveLoans(2, max: 2)));
    });

    test('409 no-free-copy reaches the late librarian as NoFreeCopy', () async {
      final server = MockClient(
        (request) async => problemResponse(const ProblemDto(status: 409, code: ErrorCodes.noFreeCopy, title: 'x')),
      );

      final result = await HttpLoanDeskRepository(clientOver(server)).approve(const LoanId('l-1'));

      expect(result, const Failure<Loan>(NoFreeCopy()));
    });
  });

  group('everything else is a RepositoryException', () {
    test('an unknown error code is refused, never guessed into a domain error', () async {
      final server = MockClient(
        (request) async => problemResponse(const ProblemDto(status: 422, code: 'loan-limit-v3', title: 'x')),
      );

      expect(requestCatan(clientOver(server)), throwsFailure(RepositoryFailure.refused));
    });

    test('a known code without its rule data is refused too', () async {
      final server = MockClient(
        (request) async =>
            problemResponse(const ProblemDto(status: 422, code: ErrorCodes.invalidLoanDuration, title: 'x')),
      );

      expect(requestCatan(clientOver(server)), throwsFailure(RepositoryFailure.refused));
    });

    test('401 session-expired is sessionExpired and one event on expirations', () async {
      final server = MockClient(
        (request) async => problemResponse(const ProblemDto(status: 401, code: ErrorCodes.sessionExpired, title: 'x')),
      );
      final api = clientOver(server);
      final expired = expectLater(api.expirations, emits(null));

      await expectLater(
        HttpLoanRepository(api).loansOf(const MemberId('clan1')),
        throwsFailure(RepositoryFailure.sessionExpired),
      );
      await expired;
    });

    test('a 500 is a server error', () async {
      final server = MockClient(
        (request) async => problemResponse(const ProblemDto(status: 500, code: ErrorCodes.serverError, title: 'x')),
      );

      expect(HttpLoanDeskRepository(clientOver(server)).allLoans(), throwsFailure(RepositoryFailure.serverError));
    });

    test('a server that cannot be reached is unreachable', () async {
      final server = MockClient((request) async => throw http.ClientException('Connection refused', request.url));

      expect(requestCatan(clientOver(server)), throwsFailure(RepositoryFailure.unreachable));
    });

    test('a server that does not answer in time is unreachable', () async {
      final server = MockClient((request) => Completer<http.Response>().future);
      final api = clientOver(server, timeout: const Duration(milliseconds: 50));

      expect(HttpLoanDeskRepository(api).allLoans(), throwsFailure(RepositoryFailure.unreachable));
    });
  });

  group('session', () {
    const ana = UserDto(id: 'clan1', name: 'Ana', role: 'member');

    test('signing in keeps the token from the body and returns the domain user', () async {
      final tokens = MemoryTokenStore();
      final server = MockClient((request) async {
        expect(jsonDecode(request.body), {'username': 'clan1', 'password': 'secret', 'cookie': false});
        final session = SessionDto(user: ana, expiresAt: DateTime.utc(2026, 11, 21), token: 'token-of-clan1');
        return jsonResponse(session.toJson(), status: 201);
      });

      final user = await HttpSessionRepository(clientOver(server, tokens: tokens))
          .logIn(username: 'clan1', password: 'secret');

      expect(user, const User(id: UserId('clan1'), name: 'Ana', role: Role.member));
      expect(await tokens.read(), 'token-of-clan1');
    });

    test('wrong credentials give no user and no expiration event', () async {
      final server = MockClient(
        (request) async =>
            problemResponse(const ProblemDto(status: 401, code: ErrorCodes.invalidCredentials, title: 'x')),
      );
      final api = clientOver(server);
      var expirations = 0;
      final subscription = api.expirations.listen((_) => expirations++);

      final user = await HttpSessionRepository(api).logIn(username: 'clan1', password: 'wrong');

      expect(user, isNull);
      expect(expirations, 0);
      await subscription.cancel();
    });

    test('the current session is read as a UserDto', () async {
      final tokens = MemoryTokenStore();
      await tokens.write('token-of-clan1');
      final server = MockClient((request) async {
        expect(request.url.path, ApiPaths.currentSession);
        return jsonResponse(ana.toJson());
      });

      final user = await HttpSessionRepository(clientOver(server, tokens: tokens)).current();

      expect(user, const User(id: UserId('clan1'), name: 'Ana', role: Role.member));
    });

    test('an expired current session clears the token and gives no user', () async {
      final tokens = MemoryTokenStore();
      await tokens.write('old-token');
      final server = MockClient(
        (request) async => problemResponse(const ProblemDto(status: 401, code: ErrorCodes.sessionExpired, title: 'x')),
      );

      final user = await HttpSessionRepository(clientOver(server, tokens: tokens)).current();

      expect(user, isNull);
      expect(await tokens.read(), isNull);
    });
  });
}
