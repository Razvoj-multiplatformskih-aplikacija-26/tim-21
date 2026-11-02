import 'package:domain/domain.dart';

const _ana = MemberId('member-1');
const _marko = MemberId('member-2');
const _jelena = MemberId('member-3');
const _nikola = MemberId('member-4');
const _milica = MemberId('member-5');
const _stefan = MemberId('member-6');

const _catan = BoardGameId('catan');
const _azul = BoardGameId('azul');
const _carcassonne = BoardGameId('carcassonne');
const _ticketToRide = BoardGameId('ticket-to-ride');
const _dixit = BoardGameId('dixit');
const _wingspan = BoardGameId('wingspan');

const fakeGames = [
  BoardGame(id: _catan, title: 'Catan'),
  BoardGame(id: _azul, title: 'Azul'),
  BoardGame(id: _carcassonne, title: 'Carcassonne'),
  BoardGame(id: _ticketToRide, title: 'Ticket to Ride'),
  BoardGame(id: _dixit, title: 'Dixit'),
  BoardGame(id: _wingspan, title: 'Wingspan'),
];

List<Loan> seedLoans(DateTime now) {
  DateTime daysAgo(int days) => now.subtract(Duration(days: days));
  DateTime inDays(int days) => now.add(Duration(days: days));

  var nextId = 1;
  Loan loan(
    MemberId member,
    BoardGameId game,
    LoanStatus status, {
    required int requestedDaysAgo,
    int days = 7,
    String? copy,
  }) => Loan(
    id: LoanId('desk-${nextId++}'),
    memberId: member,
    gameId: game,
    duration: LoanDuration.parse(days).valueOrNull!,
    requestedAt: daysAgo(requestedDaysAgo),
    status: status,
    copyId: copy == null ? null : GameCopyId(copy),
  );

  return [
    loan(_ana, _catan, const Pending(), requestedDaysAgo: 0, days: 3),
    loan(_marko, _azul, const Pending(), requestedDaysAgo: 0, days: 5),
    loan(_jelena, _dixit, const Pending(), requestedDaysAgo: 0),
    loan(_nikola, _wingspan, const Pending(), requestedDaysAgo: 1, days: 4),
    loan(_ana, _carcassonne, const Pending(), requestedDaysAgo: 1, days: 2),
    loan(_marko, _ticketToRide, const Pending(), requestedDaysAgo: 1),

    loan(_ana, _azul, Approved(pickupDeadline: inDays(2)), requestedDaysAgo: 1, copy: 'azul-1'),
    loan(_jelena, _catan, Approved(pickupDeadline: inDays(1)), requestedDaysAgo: 2, days: 5, copy: 'catan-1'),
    loan(_nikola, _dixit, Approved(pickupDeadline: inDays(1)), requestedDaysAgo: 2, days: 3, copy: 'dixit-1'),

    loan(_marko, _carcassonne, PickedUp(dueAt: inDays(4)), requestedDaysAgo: 4, copy: 'carcassonne-1'),
    loan(_jelena, _wingspan, PickedUp(dueAt: inDays(2)), requestedDaysAgo: 5, days: 6, copy: 'wingspan-1'),
    loan(_nikola, _ticketToRide, PickedUp(dueAt: inDays(5)), requestedDaysAgo: 3, copy: 'ticket-to-ride-1'),
    loan(_milica, _catan, PickedUp(dueAt: inDays(1)), requestedDaysAgo: 6, copy: 'catan-2'),

    loan(_milica, _azul, PickedUp(dueAt: daysAgo(2)), requestedDaysAgo: 10, copy: 'azul-2'),
    loan(_stefan, _dixit, PickedUp(dueAt: daysAgo(1)), requestedDaysAgo: 7, days: 5, copy: 'dixit-2'),
    loan(_stefan, _wingspan, PickedUp(dueAt: daysAgo(4)), requestedDaysAgo: 12, copy: 'wingspan-2'),

    loan(_ana, _dixit, Returned(returnedAt: daysAgo(12)), requestedDaysAgo: 20, days: 5, copy: 'dixit-1'),
    loan(_marko, _wingspan, Returned(returnedAt: daysAgo(18)), requestedDaysAgo: 26, copy: 'wingspan-1'),
    loan(
      _milica,
      _ticketToRide,
      Returned(returnedAt: daysAgo(30)),
      requestedDaysAgo: 35,
      days: 4,
      copy: 'ticket-to-ride-1',
    ),
    loan(_stefan, _carcassonne, Returned(returnedAt: daysAgo(41)), requestedDaysAgo: 48, copy: 'carcassonne-1'),
    loan(_jelena, _azul, const Rejected(), requestedDaysAgo: 15),
    loan(_milica, _wingspan, const Rejected(), requestedDaysAgo: 22, days: 2),
    loan(_nikola, _catan, const Cancelled(), requestedDaysAgo: 9),
    loan(_stefan, _azul, const Cancelled(), requestedDaysAgo: 27, days: 3),
  ];
}
