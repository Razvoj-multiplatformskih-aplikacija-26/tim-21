import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';

const uniqueViolation = '23505';
const copyConstraint = 'loans_one_active_per_copy';
const _active = "status IN ('pending', 'approved', 'picked_up')";

final class LoanStore {
  const LoanStore(this._database);

  final Session _database;

  Future<bool> isEmpty() async {
    final rows = await _database.execute('SELECT count(*) FROM users');
    return rows.single[0] == 0;
  }

  Future<List<BoardGame>> games() async {
    final rows = await _database.execute('SELECT id, title FROM board_games ORDER BY title');
    return [for (final [id, title] in rows) BoardGame(id: BoardGameId(id! as String), title: title! as String)];
  }

  Future<List<GameCopy>> copiesOf(BoardGameId game) async {
    final rows = await _database.execute(
      Sql.named('SELECT id, game_id, condition FROM game_copies WHERE game_id = @game ORDER BY id'),
      parameters: {'game': game.value},
    );
    return [
      for (final [id, gameId, condition] in rows)
        GameCopy(
          id: GameCopyId(id! as String),
          gameId: BoardGameId(gameId! as String),
          condition: _condition(condition! as String),
        ),
    ];
  }

  Future<Loan?> find(LoanId id) async {
    if (!_uuid.hasMatch(id.value)) return null;
    final found = await _loans('id = @id::uuid', {'id': id.value});
    return found.isEmpty ? null : found.single;
  }

  Future<List<Loan>> loansOf(MemberId member) => _loans('member_id = @member', {'member': member.value});

  Future<List<Loan>> activeLoansOfGame(BoardGameId game) =>
      _loans('game_id = @game AND $_active', {'game': game.value});

  Future<List<Loan>> deskLoans({required DateTime since}) => _loans(
    "$_active OR returned_at >= @since OR (status IN ('rejected', 'cancelled') AND requested_at >= @since)",
    {'since': since.toUtc()},
  );

  Future<Loan> insert({
    required MemberId member,
    required BoardGameId game,
    required LoanDuration duration,
    required DateTime requestedAt,
    LoanStatus status = const Pending(),
    GameCopyId? copyId,
  }) async {
    final columns = _statusColumns(status);
    final rows = await _database.execute(
      Sql.named('''
        INSERT INTO loans (member_id, game_id, copy_id, duration_days, requested_at, status, pickup_deadline, due_at, returned_at)
        VALUES (@member, @game, @copy, @days, @requested, @status, @pickup, @due, @returned)
        RETURNING id::text
      '''),
      parameters: {
        'member': member.value,
        'game': game.value,
        'copy': copyId?.value,
        'days': duration.days,
        'requested': requestedAt.toUtc(),
        'status': columns.kind,
        'pickup': columns.pickupDeadline,
        'due': columns.dueAt,
        'returned': columns.returnedAt,
      },
    );
    return Loan(
      id: LoanId(rows.single[0]! as String),
      memberId: member,
      gameId: game,
      duration: duration,
      requestedAt: requestedAt.toUtc(),
      status: status,
      copyId: copyId,
    );
  }

  Future<bool> changeStatus(Loan changed, {required LoanStatus from}) async {
    final columns = _statusColumns(changed.status);
    final result = await _database.execute(
      Sql.named('''
        UPDATE loans
        SET status = @status, copy_id = @copy, pickup_deadline = @pickup, due_at = @due, returned_at = @returned
        WHERE id = @id::uuid AND status = @previous
      '''),
      parameters: {
        'id': changed.id.value,
        'status': columns.kind,
        'copy': changed.copyId?.value,
        'pickup': columns.pickupDeadline,
        'due': columns.dueAt,
        'returned': columns.returnedAt,
        'previous': _statusColumns(from).kind,
      },
    );
    return result.affectedRows == 1;
  }

  Future<List<Loan>> _loans(String where, Map<String, Object?> parameters) async {
    final rows = await _database.execute(
      Sql.named('''
        SELECT id::text, member_id, game_id, copy_id, duration_days, requested_at, status, pickup_deadline, due_at, returned_at
        FROM loans
        WHERE $where
        ORDER BY requested_at DESC
      '''),
      parameters: parameters,
    );
    return [for (final row in rows) _loan(row.toColumnMap())];
  }
}

final _uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

Loan _loan(Map<String, dynamic> row) => Loan(
  id: LoanId(row['id'] as String),
  memberId: MemberId(row['member_id'] as String),
  gameId: BoardGameId(row['game_id'] as String),
  duration: LoanDuration.existing(row['duration_days'] as int),
  requestedAt: (row['requested_at'] as DateTime).toUtc(),
  status: _status(row),
  copyId: switch (row['copy_id']) {
    final String id => GameCopyId(id),
    _ => null,
  },
);

LoanStatus _status(Map<String, dynamic> row) => switch (row['status']) {
  'approved' => Approved(pickupDeadline: (row['pickup_deadline'] as DateTime).toUtc()),
  'picked_up' => PickedUp(dueAt: (row['due_at'] as DateTime).toUtc()),
  'returned' => Returned(returnedAt: (row['returned_at'] as DateTime).toUtc()),
  'rejected' => const Rejected(),
  'cancelled' => const Cancelled(),
  'pending' => const Pending(),
  final other => throw StateError('Unknown loan status in the database: $other'),
};

({String kind, DateTime? pickupDeadline, DateTime? dueAt, DateTime? returnedAt}) _statusColumns(LoanStatus status) =>
    switch (status) {
      Pending() => (kind: 'pending', pickupDeadline: null, dueAt: null, returnedAt: null),
      Approved(:final pickupDeadline) => (
        kind: 'approved',
        pickupDeadline: pickupDeadline.toUtc(),
        dueAt: null,
        returnedAt: null,
      ),
      PickedUp(:final dueAt) ||
      Overdue(:final dueAt) => (kind: 'picked_up', pickupDeadline: null, dueAt: dueAt.toUtc(), returnedAt: null),
      Returned(:final returnedAt) => (
        kind: 'returned',
        pickupDeadline: null,
        dueAt: null,
        returnedAt: returnedAt.toUtc(),
      ),
      Rejected() => (kind: 'rejected', pickupDeadline: null, dueAt: null, returnedAt: null),
      Cancelled() => (kind: 'cancelled', pickupDeadline: null, dueAt: null, returnedAt: null),
    };

CopyCondition _condition(String value) => switch (value) {
  'usable' => CopyCondition.usable,
  'in_inspection' => CopyCondition.inInspection,
  'damaged' => CopyCondition.damaged,
  _ => throw StateError('Unknown copy condition in the database: $value'),
};

String conditionColumn(CopyCondition condition) => switch (condition) {
  CopyCondition.usable => 'usable',
  CopyCondition.inInspection => 'in_inspection',
  CopyCondition.damaged => 'damaged',
};
