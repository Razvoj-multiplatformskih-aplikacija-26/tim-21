import 'package:domain/domain.dart';

const fakeMember = MemberId('member-1');
const _otherMember = MemberId('member-2');

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
    BoardGameId game,
    LoanStatus status, {
    required int requestedDaysAgo,
    MemberId member = fakeMember,
    int days = 7,
    String? copy,
  }) => Loan(
    id: LoanId('loan-${nextId++}'),
    memberId: member,
    gameId: game,
    duration: LoanDuration.parse(days).valueOrNull!,
    requestedAt: daysAgo(requestedDaysAgo),
    status: status,
    copyId: copy == null ? null : GameCopyId(copy),
  );

  return [
    loan(_catan, const Pending(), requestedDaysAgo: 0, days: 3),
    loan(_azul, Approved(pickupDeadline: inDays(2)), requestedDaysAgo: 1, copy: 'azul-1'),
    loan(_carcassonne, PickedUp(dueAt: inDays(4)), requestedDaysAgo: 4, copy: 'carcassonne-1'),
    loan(_ticketToRide, PickedUp(dueAt: daysAgo(2)), requestedDaysAgo: 10, copy: 'ticket-to-ride-1'),
    loan(_dixit, Returned(returnedAt: daysAgo(12)), requestedDaysAgo: 20, days: 5, copy: 'dixit-1'),
    loan(_wingspan, Returned(returnedAt: daysAgo(25)), requestedDaysAgo: 33, copy: 'wingspan-1'),
    loan(_catan, Returned(returnedAt: daysAgo(40)), requestedDaysAgo: 46, days: 4, copy: 'catan-1'),
    loan(_azul, Returned(returnedAt: daysAgo(55)), requestedDaysAgo: 60, days: 3, copy: 'azul-2'),
    loan(_wingspan, const Rejected(), requestedDaysAgo: 15),
    loan(_dixit, const Rejected(), requestedDaysAgo: 28, days: 2),
    loan(_carcassonne, const Cancelled(), requestedDaysAgo: 18),
    loan(_ticketToRide, const Cancelled(), requestedDaysAgo: 37, days: 5),
    loan(
      _catan,
      PickedUp(dueAt: inDays(3)),
      requestedDaysAgo: 2,
      member: _otherMember,
      copy: 'catan-2',
    ),
    loan(_azul, const Pending(), requestedDaysAgo: 0, member: _otherMember),
  ];
}
