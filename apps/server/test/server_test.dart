@Tags(['db'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:domain/domain.dart'
    show Approved, BoardGameId, GameCopyId, LoanDuration, LoanStatus, MemberId, Rejected;
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

const testDatabase = 'boardgame_http_test';

late Pool<void> database;
late RelicServer server;
late Uri base;
late String demoPassword;
late String jwtSecret;

Uri path(String path) => base.replace(path: path);

Future<http.Response> signIn(String login, {String? password, bool cookie = false}) => http.post(
  path(ApiPaths.sessions),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode(LoginDto(username: login, password: password ?? demoPassword, cookie: cookie).toJson()),
);

Future<String> tokenOf(String login) async => SessionDto.fromJson(jsonOf(await signIn(login))).token!;

Map<String, String> as(String token) => {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};

Map<String, Object?> jsonOf(http.Response response) => jsonDecode(response.body) as Map<String, Object?>;

String codeOf(http.Response response) => jsonOf(response)['code']! as String;

List<LoanDto> loansOf(http.Response response) => [
  for (final loan in jsonDecode(response.body) as List<Object?>) LoanDto.fromJson(loan! as Map<String, Object?>),
];

Future<http.Response> requestLoan(String token, Map<String, Object?> body) =>
    http.post(path(ApiPaths.loans), headers: as(token), body: jsonEncode(body));

Future<LoanDto> pendingOf(String member, String game) async {
  final desk = await http.get(path(ApiPaths.deskLoans), headers: as(await tokenOf('bibliotekar1')));
  return loansOf(
    desk,
  ).firstWhere((loan) => loan.memberId == member && loan.gameId == game && loan.status.kind == LoanStatusDto.pending);
}

Future<void> migrateWithDbmate(Uri databaseUrl) async {
  final insideCompose = databaseUrl.replace(host: 'db', port: 5432, path: '/$testDatabase');
  final result = await Process.run('docker', [
    'compose',
    'run',
    '--rm',
    '-e',
    'DATABASE_URL=$insideCompose',
    'migrate',
  ], workingDirectory: '../..');
  if (result.exitCode != 0) throw StateError('dbmate failed: ${result.stderr}');
}

void main() {
  setUpAll(() async {
    final config = ServerConfig.fromEnvironment(serverEnvironment());
    demoPassword = config.demoPassword!;
    jwtSecret = config.jwtSecret;
    final url = Uri.parse(config.databaseUrl);
    final admin = Pool<void>.withUrl(config.databaseUrl);
    await admin.execute('DROP DATABASE IF EXISTS $testDatabase WITH (FORCE)');
    await admin.execute('CREATE DATABASE $testDatabase');
    await admin.close();
    await migrateWithDbmate(url);
    database = Pool<void>.withUrl(
      url
          .replace(path: '/$testDatabase', queryParameters: {...url.queryParameters, 'max_connection_count': '4'})
          .toString(),
    );
    const clock = SystemClock();
    await seedDemoData(database, now: clock.now(), demoPassword: demoPassword);
    final handlers = LoanHandlers(loans: PostgresLoans(LoanStore(database), clock: clock));
    final sessions = SessionHandlers(
      accounts: AccountStore(database),
      secret: jwtSecret,
      ttl: const Duration(hours: 1),
    );
    server = RelicServer(() => IOAdapter.bind(InternetAddress.loopbackIPv4, port: 0));
    await server.mountAndStart(buildHandler(handlers, sessions, corsOrigins: const []));
    base = Uri.parse('http://localhost:${server.port}');
  });

  tearDownAll(() async {
    await server.close();
    await database.close();
  });

  test('a member and a librarian sign in; a wrong password gets 401 invalid-credentials', () async {
    final member = await signIn('clan1');
    final librarian = await signIn('bibliotekar1');
    final wrong = await signIn('clan1', password: 'wrong');
    final unknown = await signIn('nobody');

    expect([member.statusCode, librarian.statusCode], [201, 201]);
    expect(SessionDto.fromJson(jsonOf(member)).user.role, 'member');
    expect(SessionDto.fromJson(jsonOf(librarian)).user.role, 'librarian');
    final current = await http.get(
      path(ApiPaths.currentSession),
      headers: as(SessionDto.fromJson(jsonOf(member)).token!),
    );
    expect(current.statusCode, 200);
    expect(UserDto.fromJson(jsonOf(current)).id, 'clan1');
    expect([wrong.statusCode, unknown.statusCode], [401, 401]);
    expect([codeOf(wrong), codeOf(unknown)], everyElement(ErrorCodes.invalidCredentials));
  });

  test('a browser sign-in gets the HttpOnly cookie and no token in the body; the cookie alone signs in', () async {
    final answer = await signIn('clan1', cookie: true);

    expect(answer.statusCode, 201);
    expect(SessionDto.fromJson(jsonOf(answer)).token, isNull);
    final cookie = answer.headers['set-cookie']!;
    expect(cookie, allOf(startsWith('${ApiCookies.session}='), contains('HttpOnly'), contains('SameSite=Lax')));
    final current = await http.get(path(ApiPaths.currentSession), headers: {'Cookie': cookie.split(';').first});
    expect(UserDto.fromJson(jsonOf(current)).id, 'clan1');
  });

  test('a request for 8 days gets 422 invalid-loan-duration with the limits from the domain', () async {
    final answer = await requestLoan(
      await tokenOf('clan1'),
      const NewLoanDto(gameId: 'azul', durationDays: 8).toJson(),
    );

    expect(answer.statusCode, 422);
    final problem = ProblemDto.fromJson(jsonOf(answer));
    expect([problem.code, problem.value, problem.min, problem.max], [ErrorCodes.invalidLoanDuration, 8, 1, 7]);
  });

  test('a memberId in the body is ignored: the loan belongs to whoever signed in', () async {
    final answer = await requestLoan(await tokenOf('clan1'), {
      ...const NewLoanDto(gameId: 'azul', durationDays: 2).toJson(),
      'memberId': 'clan2',
    });

    expect(answer.statusCode, 201);
    expect(LoanDto.fromJson(jsonOf(answer)).memberId, 'clan1');
  });

  test('a member sees only own loans and gets 404 for cancelling another member\'s loan', () async {
    final token = await tokenOf('clan1');
    final others = await pendingOf('clan2', 'carcassonne');

    final mine = await http.get(path(ApiPaths.myLoans), headers: as(token));
    final cancelled = await http.post(path(ApiPaths.cancellation(others.id)), headers: as(token));

    expect(loansOf(mine).map((loan) => loan.memberId), everyElement('clan1'));
    expect(cancelled.statusCode, 404);
    expect(codeOf(cancelled), ErrorCodes.notFound);
    expect((await pendingOf('clan2', 'carcassonne')).status.kind, LoanStatusDto.pending);
  });

  test('a member approving own loan gets 403 not-allowed', () async {
    final own = await pendingOf('clan1', 'carcassonne');

    final answer = await http.post(path(ApiPaths.approval(own.id)), headers: as(await tokenOf('clan1')));

    expect(answer.statusCode, 403);
    expect(codeOf(answer), ErrorCodes.notAllowed);
  });

  test('no token gets 401 sign-in-required; an expired token gets 401 session-expired', () async {
    final expired = JWT({
      'name': 'Ana',
      'role': 'member',
      'exp': DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
    }, subject: 'clan1').sign(SecretKey(jwtSecret), noIssueAt: true);

    final none = await http.get(path(ApiPaths.myLoans));
    final old = await http.get(path(ApiPaths.myLoans), headers: as(expired));

    expect([none.statusCode, old.statusCode], [401, 401]);
    expect([codeOf(none), codeOf(old)], [ErrorCodes.signInRequired, ErrorCodes.sessionExpired]);
    expect(none.headers['www-authenticate'], 'Bearer');
  });

  test('two approvals at once for the last copy: one gets 200, the other 409 no-free-copy', () async {
    final first = await pendingOf('clan1', 'carcassonne');
    final second = await pendingOf('clan2', 'carcassonne');
    final librarian = as(await tokenOf('bibliotekar1'));

    final answers = await Future.wait([
      http.post(path(ApiPaths.approval(first.id)), headers: librarian),
      http.post(path(ApiPaths.approval(second.id)), headers: librarian),
    ]);

    expect(answers.map((answer) => answer.statusCode), unorderedEquals([200, 409]));
    expect(codeOf(answers.firstWhere((answer) => answer.statusCode == 409)), ErrorCodes.noFreeCopy);
  });

  test('approving an approved or a rejected loan of a game without a free copy gets 409 invalid-transition', () async {
    await database.execute("INSERT INTO board_games (id, title) VALUES ('one-copy', 'One copy')");
    await database.execute(
      "INSERT INTO game_copies (id, game_id, condition) VALUES ('one-copy-1', 'one-copy', 'usable')",
    );
    final now = DateTime.now().toUtc();
    Future<String> loanIn(LoanStatus status, {String? copy}) async => (await LoanStore(database).insert(
      member: const MemberId('clan3'),
      game: const BoardGameId('one-copy'),
      duration: const LoanDuration.existing(2),
      requestedAt: now,
      status: status,
      copyId: copy == null ? null : GameCopyId(copy),
    )).id.value;
    final approved = await loanIn(Approved(pickupDeadline: now.add(const Duration(days: 1))), copy: 'one-copy-1');
    final rejected = await loanIn(const Rejected());
    final librarian = as(await tokenOf('bibliotekar1'));

    final answers = [
      for (final id in [approved, rejected]) await http.post(path(ApiPaths.approval(id)), headers: librarian),
    ];

    expect(answers.map((answer) => answer.statusCode), [409, 409]);
    expect(answers.map(codeOf), everyElement(ErrorCodes.invalidTransition));
    expect(answers.map((answer) => ProblemDto.fromJson(jsonOf(answer)).from?.kind), [
      LoanStatusDto.approved,
      LoanStatusDto.rejected,
    ]);
  });
}
