import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

final _tuesday = DateTime.utc(2026, 11, 3, 12);
final _friday = DateTime.utc(2026, 11, 6, 12);

Loan _loan(String id, {MemberId member = ana, BoardGameId game = catan, LoanStatus status = const Pending()}) => Loan(
  id: LoanId(id),
  memberId: member,
  gameId: game,
  duration: LoanDuration.parse(7).valueOrNull!,
  requestedAt: monday,
  status: status,
);

void main() {
  final pending = _loan('pending');
  final approved = _loan(
    'approved',
    member: marko,
    status: Approved(pickupDeadline: _friday),
  );
  final pickedUp = _loan(
    'picked-up',
    game: azul,
    status: PickedUp(dueAt: _friday),
  );
  final pastDue = _loan(
    'past-due',
    member: marko,
    game: azul,
    status: PickedUp(dueAt: _tuesday),
  );
  final overdue = _loan('overdue', status: Overdue(dueAt: monday));
  final returned = _loan(
    'returned',
    member: marko,
    status: Returned(returnedAt: monday),
  );
  final rejected = _loan('rejected', game: azul, status: const Rejected());
  final cancelled = _loan('cancelled', status: const Cancelled());
  final loans = [pending, approved, pickedUp, pastDue, overdue, returned, rejected, cancelled];

  List<String> idsOf(LoanFilter filter) => [for (final loan in filterLoans(loans, filter, wednesday)) loan.id.value];

  test('each status reports its stage', () {
    expect(
      [for (final loan in loans) loan.status.stage],
      [
        LoanStage.pending,
        LoanStage.approved,
        LoanStage.pickedUp,
        LoanStage.pickedUp,
        LoanStage.overdue,
        LoanStage.returned,
        LoanStage.rejected,
        LoanStage.cancelled,
      ],
    );
  });

  test('the empty filter keeps every loan in order', () {
    expect(LoanFilter.none.isEmpty, isTrue);
    expect(filterLoans(loans, LoanFilter.none, wednesday), loans);
  });

  group('stages', () {
    test('keeps only the chosen stages', () {
      expect(idsOf(const LoanFilter(stages: {LoanStage.pending, LoanStage.returned})), ['pending', 'returned']);
    });

    test('judges the stage at now, so a picked-up loan past its due date is overdue', () {
      expect(idsOf(const LoanFilter(stages: {LoanStage.pickedUp})), ['picked-up']);
      expect(idsOf(const LoanFilter(stages: {LoanStage.overdue})), ['past-due', 'overdue']);
    });
  });

  test('game keeps only loans of that game', () {
    expect(idsOf(const LoanFilter(gameId: azul)), ['picked-up', 'past-due', 'rejected']);
  });

  test('member keeps only loans of that member', () {
    expect(idsOf(const LoanFilter(memberId: marko)), ['approved', 'past-due', 'returned']);
  });

  test('the overdue chip catches a picked-up loan once its due date has passed', () {
    const overdueChip = LoanFilter(stages: {LoanStage.overdue});
    expect(filterLoans([pastDue], overdueChip, wednesday), [pastDue]);
    expect(filterLoans([pastDue], overdueChip, monday), isEmpty);
  });

  test('criteria combine, and every one of them must match', () {
    const filter = LoanFilter(stages: {LoanStage.overdue}, gameId: azul, memberId: marko);
    expect(idsOf(filter), ['past-due']);
    expect(idsOf(filter.copyWith(memberId: ana)), isEmpty);
  });

  group('changing a filter', () {
    test('withStage adds and removes a stage', () {
      final added = LoanFilter.none.withStage(LoanStage.pending, selected: true);
      expect(added.stages, {LoanStage.pending});
      expect(added.withStage(LoanStage.pending, selected: false), LoanFilter.none);
    });

    test('copyWith clears the game and the member', () {
      const filter = LoanFilter(gameId: catan, memberId: ana);
      expect(filter.copyWith(clearGame: true, clearMember: true), LoanFilter.none);
    });

    test('filters with the same stages are equal regardless of order', () {
      expect(
        const LoanFilter(stages: {LoanStage.pending, LoanStage.approved}),
        const LoanFilter(stages: {LoanStage.approved, LoanStage.pending}),
      );
    });
  });
}
