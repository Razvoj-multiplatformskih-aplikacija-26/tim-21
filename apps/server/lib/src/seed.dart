import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';

import 'loan_store.dart';
import 'passwords.dart';

const _ana = User(id: UserId('clan1'), name: 'Ana Petrović', role: Role.member);
const _marko = User(id: UserId('clan2'), name: 'Marko Jovanović', role: Role.member);
const _jelena = User(id: UserId('clan3'), name: 'Jelena Nikolić', role: Role.member);
const _librarian = User(id: UserId('bibliotekar1'), name: 'Milica Stojanović', role: Role.librarian);
const _users = [_ana, _marko, _jelena, _librarian];

const _catan = BoardGame(id: BoardGameId('catan'), title: 'Catan');
const _azul = BoardGame(id: BoardGameId('azul'), title: 'Azul');
const _carcassonne = BoardGame(id: BoardGameId('carcassonne'), title: 'Carcassonne');
const _ticketToRide = BoardGame(id: BoardGameId('ticket-to-ride'), title: 'Ticket to Ride');
const _dixit = BoardGame(id: BoardGameId('dixit'), title: 'Dixit');
const _wingspan = BoardGame(id: BoardGameId('wingspan'), title: 'Wingspan');
const _games = [_catan, _azul, _carcassonne, _ticketToRide, _dixit, _wingspan];

const _copies = [
  GameCopy(id: GameCopyId('catan-1'), gameId: BoardGameId('catan')),
  GameCopy(id: GameCopyId('catan-2'), gameId: BoardGameId('catan')),
  GameCopy(id: GameCopyId('catan-3'), gameId: BoardGameId('catan')),
  GameCopy(id: GameCopyId('azul-1'), gameId: BoardGameId('azul')),
  GameCopy(id: GameCopyId('azul-2'), gameId: BoardGameId('azul')),
  GameCopy(id: GameCopyId('carcassonne-1'), gameId: BoardGameId('carcassonne')),
  GameCopy(id: GameCopyId('ticket-to-ride-1'), gameId: BoardGameId('ticket-to-ride')),
  GameCopy(id: GameCopyId('ticket-to-ride-2'), gameId: BoardGameId('ticket-to-ride')),
  GameCopy(id: GameCopyId('dixit-1'), gameId: BoardGameId('dixit')),
  GameCopy(id: GameCopyId('dixit-2'), gameId: BoardGameId('dixit')),
  GameCopy(id: GameCopyId('dixit-3'), gameId: BoardGameId('dixit'), condition: CopyCondition.inInspection),
  GameCopy(id: GameCopyId('wingspan-1'), gameId: BoardGameId('wingspan')),
  GameCopy(id: GameCopyId('wingspan-2'), gameId: BoardGameId('wingspan')),
];

Future<void> seedDemoData(Pool<void> database, {required DateTime now, required String? demoPassword}) async {
  if (!await LoanStore(database).isEmpty()) return;
  if (demoPassword == null) throw StateError('DEMO_PASSWORD is not set. Copy .env.example to .env.');
  final hashes = await Future.wait([for (final _ in _users) hashPassword(demoPassword)]);
  await database.runTx((session) => _seed(session, now: now.toUtc(), hashes: hashes));
}

Future<void> _seed(Session database, {required DateTime now, required List<String> hashes}) async {
  for (final (index, user) in _users.indexed) {
    await database.execute(
      Sql.named('INSERT INTO users (id, name, role, login, password_hash) VALUES (@id, @name, @role, @login, @hash)'),
      parameters: {
        'id': user.id.value,
        'name': user.name,
        'role': user.role.name,
        'login': user.id.value,
        'hash': hashes[index],
      },
    );
  }
  for (final game in _games) {
    await database.execute(
      Sql.named('INSERT INTO board_games (id, title) VALUES (@id, @title)'),
      parameters: {'id': game.id.value, 'title': game.title},
    );
  }
  for (final copy in _copies) {
    await database.execute(
      Sql.named('INSERT INTO game_copies (id, game_id, condition) VALUES (@id, @game, @condition)'),
      parameters: {'id': copy.id.value, 'game': copy.gameId.value, 'condition': conditionColumn(copy.condition)},
    );
  }

  final store = LoanStore(database);
  DateTime ago(Duration duration) => now.subtract(duration);
  DateTime inDays(int days) => now.add(Duration(days: days));
  DateTime daysAgo(int days) => ago(Duration(days: days));

  Future<void> loan(
    User member,
    BoardGame game,
    LoanStatus status, {
    required DateTime requestedAt,
    int days = 7,
    String? copy,
  }) => store.insert(
    member: MemberId(member.id.value),
    game: game.id,
    duration: LoanDuration.parse(days).valueOrNull!,
    requestedAt: requestedAt,
    status: status,
    copyId: copy == null ? null : GameCopyId(copy),
  );

  await loan(_ana, _carcassonne, const Pending(), requestedAt: ago(const Duration(hours: 2)), days: 3);
  await loan(
    _ana,
    _catan,
    Approved(pickupDeadline: inDays(1)),
    requestedAt: daysAgo(2),
    days: 5,
    copy: 'catan-1',
  );
  await loan(
    _ana,
    _dixit,
    Returned(returnedAt: daysAgo(12)),
    requestedAt: daysAgo(20),
    days: 5,
    copy: 'dixit-1',
  );
  await loan(_ana, _azul, const Rejected(), requestedAt: daysAgo(15));
  await loan(_ana, _wingspan, const Cancelled(), requestedAt: daysAgo(9), days: 4);

  await loan(_marko, _carcassonne, const Pending(), requestedAt: ago(const Duration(hours: 1)));
  await loan(
    _marko,
    _ticketToRide,
    PickedUp(dueAt: inDays(4)),
    requestedAt: daysAgo(4),
    days: 6,
    copy: 'ticket-to-ride-1',
  );
  await loan(
    _marko,
    _catan,
    Returned(returnedAt: daysAgo(5)),
    requestedAt: daysAgo(14),
    copy: 'catan-2',
  );
  await loan(_marko, _dixit, const Cancelled(), requestedAt: daysAgo(3), days: 2);
  await loan(
    _marko,
    _wingspan,
    Returned(returnedAt: daysAgo(45)),
    requestedAt: daysAgo(53),
    copy: 'wingspan-2',
  );

  await loan(
    _jelena,
    _azul,
    PickedUp(dueAt: daysAgo(2)),
    requestedAt: daysAgo(10),
    copy: 'azul-1',
  );
  await loan(_jelena, _dixit, const Pending(), requestedAt: daysAgo(3), days: 4);
  await loan(
    _jelena,
    _wingspan,
    Approved(pickupDeadline: inDays(2)),
    requestedAt: daysAgo(1),
    copy: 'wingspan-1',
  );
  await loan(
    _jelena,
    _carcassonne,
    Returned(returnedAt: daysAgo(20)),
    requestedAt: daysAgo(28),
    days: 6,
    copy: 'carcassonne-1',
  );
  await loan(_jelena, _catan, const Rejected(), requestedAt: daysAgo(25), days: 3);
}
