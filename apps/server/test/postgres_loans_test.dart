@Tags(['db'])
library;

import 'dart:io';

import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';
import 'package:server/server.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

const testDatabase = 'boardgame_test';

late Pool<void> database;
late LoanStore store;
late PostgresLoans loans;

final now = DateTime.now().toUtc();

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

Future<MemberId> addMember(String id) async {
  await database.execute(
    Sql.named("INSERT INTO users (id, name, role, login, password_hash) VALUES (@id, @id, 'member', @id, 'unused')"),
    parameters: {'id': id},
  );
  return MemberId(id);
}

Future<BoardGameId> addGame(String id, {required int copies}) async {
  await database.execute(Sql.named('INSERT INTO board_games (id, title) VALUES (@id, @id)'), parameters: {'id': id});
  for (var n = 1; n <= copies; n++) {
    await database.execute(
      Sql.named("INSERT INTO game_copies (id, game_id, condition) VALUES (@id, @game, 'usable')"),
      parameters: {'id': '$id-$n', 'game': id},
    );
  }
  return BoardGameId(id);
}

Future<Loan> addLoan(MemberId member, BoardGameId game, LoanStatus status, {String? copy}) => store.insert(
  member: member,
  game: game,
  duration: LoanDuration.parse(3).valueOrNull!,
  requestedAt: now.subtract(const Duration(days: 1)),
  status: status,
  copyId: copy == null ? null : GameCopyId(copy),
);

Future<int> approvedCount(BoardGameId game) async {
  final rows = await database.execute(
    Sql.named("SELECT count(*) FROM loans WHERE game_id = @game AND status IN ('approved', 'picked_up')"),
    parameters: {'game': game.value},
  );
  return rows.single[0]! as int;
}

Matcher failsWith<E extends DomainError>() =>
    isA<Failure<Loan>>().having((failure) => failure.error, 'error', isA<E>());

void main() {
  setUpAll(() async {
    final config = ServerConfig.fromEnvironment(serverEnvironment());
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
    await Future.wait([for (var n = 0; n < 4; n++) database.execute('SELECT pg_sleep(0.05)')]);
    store = LoanStore(database);
    loans = PostgresLoans(store, clock: const SystemClock());
  });

  tearDownAll(() => database.close());

  test('two approvals at once for the last free copy: one is approved, the other gets NoFreeCopy', () async {
    final game = await addGame('last-copy', copies: 1);
    final first = await addLoan(await addMember('last-copy-a'), game, const Pending());
    final second = await addLoan(await addMember('last-copy-b'), game, const Pending());

    final results = await Future.wait([loans.approve(first.id), loans.approve(second.id)]);

    expect(results, unorderedEquals([isA<Success<Loan>>(), failsWith<NoFreeCopy>()]));
    expect(await approvedCount(game), 1);
    final shared = await database.execute(
      "SELECT copy_id FROM loans WHERE status IN ('approved', 'picked_up') GROUP BY copy_id HAVING count(*) > 1",
    );
    expect(shared, isEmpty);
    final waiting = results.indexWhere((result) => result is Failure);
    expect((await store.find([first, second][waiting].id))!.status, const Pending());
  });

  test('two approvals at once of the same loan: one is approved, the other gets InvalidTransition', () async {
    final game = await addGame('same-loan', copies: 2);
    final loan = await addLoan(await addMember('same-loan-a'), game, const Pending());

    final results = await Future.wait([loans.approve(loan.id), loans.approve(loan.id)]);

    expect(
      results,
      unorderedEquals([
        isA<Success<Loan>>(),
        isA<Failure<Loan>>().having(
          (failure) => failure.error,
          'error',
          isA<InvalidTransition>().having((error) => error.from, 'from', isA<Approved>()),
        ),
      ]),
    );
    expect(await approvedCount(game), 1);
  });

  test('a request over the active limit gets TooManyActiveLoans with the limit from the domain', () async {
    final game = await addGame('limit', copies: 2);
    final member = await addMember('limit-a');
    await addLoan(member, game, const Pending());
    await addLoan(member, game, Approved(pickupDeadline: now.add(const Duration(days: 1))), copy: 'limit-1');
    await addLoan(member, game, PickedUp(dueAt: now.add(const Duration(days: 2))), copy: 'limit-2');

    final result = await loans.request(member: member, game: game, duration: LoanDuration.parse(2).valueOrNull!);

    expect(result, const Failure<Loan>(TooManyActiveLoans(3, max: maxActiveLoans)));
    expect(await store.loansOf(member), hasLength(3));
  });

  test('a request from a member with an overdue loan gets MemberHasOverdueLoan', () async {
    final game = await addGame('overdue', copies: 1);
    final member = await addMember('overdue-a');
    await addLoan(member, game, PickedUp(dueAt: now.subtract(const Duration(days: 1))), copy: 'overdue-1');

    final result = await loans.request(member: member, game: game, duration: LoanDuration.parse(2).valueOrNull!);

    expect(result, failsWith<MemberHasOverdueLoan>());
    expect(await store.loansOf(member), hasLength(1));
  });

  test('a request within the rules is stored as pending', () async {
    final game = await addGame('accepted', copies: 1);
    final member = await addMember('accepted-a');

    final result = await loans.request(member: member, game: game, duration: LoanDuration.parse(2).valueOrNull!);

    final stored = await store.find(result.valueOrNull!.id);
    expect(stored, result.valueOrNull);
    expect(stored!.status, const Pending());
  });

  test('the unique index refuses a second active loan of one copy even when code skips assignCopy', () async {
    final game = await addGame('index', copies: 1);
    await addLoan(await addMember('index-a'), game, Approved(pickupDeadline: now), copy: 'index-1');
    final second = await addLoan(await addMember('index-b'), game, const Pending());
    final sameCopy = second.copyWith(
      status: Approved(pickupDeadline: now),
      copyId: const GameCopyId('index-1'),
    );

    expect(
      store.changeStatus(sameCopy, from: const Pending()),
      throwsA(
        isA<ServerException>()
            .having((error) => error.code, 'code', uniqueViolation)
            .having((error) => error.constraintName, 'constraint', copyConstraint),
      ),
    );
  });

  test('two cancellations at once: one cancels, the other gets InvalidTransition from Cancelled', () async {
    final game = await addGame('cancel', copies: 1);
    final loan = await addLoan(await addMember('cancel-a'), game, const Pending());

    final results = await Future.wait([loans.cancel(loan.id), loans.cancel(loan.id)]);

    expect(
      results,
      unorderedEquals([
        isA<Success<Loan>>(),
        const Failure<Loan>(InvalidTransition(from: Cancelled(), to: Cancelled())),
      ]),
    );
  });

  test('a rejection of a pending loan is stored; of an unknown id it gets LoanNotFound', () async {
    final game = await addGame('reject', copies: 1);
    final loan = await addLoan(await addMember('reject-a'), game, const Pending());

    expect(await loans.reject(loan.id), isA<Success<Loan>>());
    expect((await store.find(loan.id))!.status, const Rejected());
    expect(await loans.reject(const LoanId('00000000-0000-0000-0000-000000000000')), failsWith<LoanNotFound>());
    expect(await loans.reject(const LoanId('not-a-uuid')), failsWith<LoanNotFound>());
  });
}
