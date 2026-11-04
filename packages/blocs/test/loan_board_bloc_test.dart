import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

const _catan = BoardGame(id: BoardGameId('catan'), title: 'Catan');
const _ana = MemberId('ana');
const _marko = MemberId('marko');
final _now = DateTime.utc(2026, 11, 2, 12);

final class _FixedClock implements Clock {
  @override
  DateTime now() => _now;
}

final class _Desk implements LoanDeskRepository {
  _Desk(this.loans);

  List<Loan> loans;
  bool failLoad = false;
  bool failAction = false;
  DomainError? refuse;
  int actionCalls = 0;

  @override
  Future<List<Loan>> allLoans() async {
    if (failLoad) throw const RepositoryException('Simulated outage');
    return loans;
  }

  @override
  Future<List<BoardGame>> games() async => const [_catan];

  @override
  Future<Result<Loan>> approve(LoanId id) =>
      _change(id, (loan) => approveLoan(loan, const GameCopyId('catan-1'), _now));

  @override
  Future<Result<Loan>> reject(LoanId id) => _change(id, rejectLoan);

  Future<Result<Loan>> _change(LoanId id, Result<Loan> Function(Loan) decide) async {
    actionCalls++;
    if (failAction) throw const RepositoryException('Simulated outage');
    if (refuse case final error?) return Failure(error);
    final index = loans.indexWhere((loan) => loan.id == id);
    final result = decide(loans[index]);
    if (result case Success(:final value)) loans = [...loans]..[index] = value;
    return result;
  }
}

Loan _loan(String id, {LoanStatus status = const Pending(), int daysAgo = 0, MemberId member = _ana}) => Loan(
  id: LoanId(id),
  memberId: member,
  gameId: _catan.id,
  duration: LoanDuration.parse(7).valueOrNull!,
  requestedAt: _now.subtract(Duration(days: daysAgo)),
  status: status,
);

List<Loan> _fourMixedLoans() => [
  _loan(
    'd',
    daysAgo: 3,
    member: _marko,
    status: Returned(returnedAt: _now.subtract(const Duration(days: 1))),
  ),
  _loan('c', daysAgo: 2, status: PickedUp(dueAt: _now.subtract(const Duration(days: 1)))),
  _loan('b', daysAgo: 1, member: _marko),
  _loan('a'),
];

List<String> _ids(List<LoanBoardItem> items) => [for (final item in items) item.loan.id.value];

List<Loan> _threeLoans() => [_loan('c', daysAgo: 2), _loan('a'), _loan('b', daysAgo: 1)];

LoanBoardBloc _blocOver(_Desk desk) => LoanBoardBloc(repository: desk, clock: _FixedClock());

Future<void> _load(LoanBoardBloc bloc) async {
  bloc.add(const LoanBoardRequested());
  await bloc.stream.firstWhere((state) => state is LoanBoardLoaded);
}

void main() {
  group('loading', () {
    blocTest<LoanBoardBloc, LoanBoardState>(
      'emits loading and then every loan with its game title and allowed actions',
      build: () => _blocOver(_Desk(_threeLoans())),
      act: (bloc) => bloc.add(const LoanBoardRequested()),
      expect: () => [
        const LoanBoardLoading(),
        isA<LoanBoardLoaded>()
            .having((s) => s.items.map((i) => i.loan.id.value), 'newest first', ['a', 'b', 'c'])
            .having((s) => s.items.first.gameTitle, 'title', 'Catan')
            .having((s) => s.items.first.canApprove, 'canApprove', isTrue)
            .having((s) => s.items.first.canReject, 'canReject', isTrue)
            .having((s) => s.selectedId, 'selected', isNull),
      ],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'a loan past its due date is shown as overdue and offers no staff action',
      build: () => _blocOver(_Desk([_loan('a', status: PickedUp(dueAt: _now.subtract(const Duration(days: 1))))])),
      act: (bloc) => bloc.add(const LoanBoardRequested()),
      skip: 1,
      expect: () => [
        isA<LoanBoardLoaded>()
            .having((s) => s.items.single.status, 'status', isA<Overdue>())
            .having((s) => s.items.single.canApprove, 'canApprove', isFalse)
            .having((s) => s.items.single.canReject, 'canReject', isFalse),
      ],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'emits failure when the repository cannot be reached',
      build: () => _blocOver(_Desk(_threeLoans())..failLoad = true),
      act: (bloc) => bloc.add(const LoanBoardRequested()),
      expect: () => const [LoanBoardLoading(), LoanBoardFailure()],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'emits empty when the library has no loans',
      build: () => _blocOver(_Desk([])),
      act: (bloc) => bloc.add(const LoanBoardRequested()),
      expect: () => const [LoanBoardLoading(), LoanBoardEmpty()],
    );
  });

  group('selection', () {
    blocTest<LoanBoardBloc, LoanBoardState>(
      'selecting a loan remembers it',
      build: () => _blocOver(_Desk(_threeLoans())),
      act: (bloc) async {
        await _load(bloc);
        bloc.add(const LoanBoardSelected(LoanId('b')));
      },
      skip: 2,
      expect: () => [isA<LoanBoardLoaded>().having((s) => s.selected?.loan.id, 'selected', const LoanId('b'))],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'selecting an unknown loan is ignored',
      build: () => _blocOver(_Desk(_threeLoans())),
      act: (bloc) async {
        await _load(bloc);
        bloc.add(const LoanBoardSelected(LoanId('missing')));
      },
      skip: 2,
      expect: () => <LoanBoardState>[],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'the first move without a selection picks the first loan',
      build: () => _blocOver(_Desk(_threeLoans())),
      act: (bloc) async {
        await _load(bloc);
        bloc.add(const LoanBoardSelectionMoved(1));
      },
      skip: 2,
      expect: () => [isA<LoanBoardLoaded>().having((s) => s.selectedId, 'selected', const LoanId('a'))],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'moving stops at the last loan and can go back',
      build: () => _blocOver(_Desk(_threeLoans())),
      act: (bloc) async {
        await _load(bloc);
        bloc
          ..add(const LoanBoardSelected(LoanId('b')))
          ..add(const LoanBoardSelectionMoved(5))
          ..add(const LoanBoardSelectionMoved(-1));
      },
      skip: 2,
      expect: () => [
        isA<LoanBoardLoaded>().having((s) => s.selectedId, 'selected', const LoanId('b')),
        isA<LoanBoardLoaded>().having((s) => s.selectedId, 'selected', const LoanId('c')),
        isA<LoanBoardLoaded>().having((s) => s.selectedId, 'selected', const LoanId('b')),
      ],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'reloading keeps the selection',
      build: () => _blocOver(_Desk(_threeLoans())),
      act: (bloc) async {
        await _load(bloc);
        bloc.add(const LoanBoardSelected(LoanId('c')));
        await bloc.stream.firstWhere((state) => state is LoanBoardLoaded && state.selectedId != null);
        bloc.add(const LoanBoardRequested());
      },
      skip: 3,
      expect: () => [
        const LoanBoardLoading(),
        isA<LoanBoardLoaded>().having((s) => s.selectedId, 'selected', const LoanId('c')),
      ],
    );
  });

  group('approval', () {
    Future<void> loadSelectThenApprove(LoanBoardBloc bloc) async {
      await _load(bloc);
      bloc
        ..add(const LoanBoardSelected(LoanId('a')))
        ..add(const LoanApprovalRequested(LoanId('a')));
    }

    blocTest<LoanBoardBloc, LoanBoardState>(
      'marks the loan in flight, then reloads, reports success and keeps the selection',
      build: () => _blocOver(_Desk(_threeLoans())),
      act: loadSelectThenApprove,
      skip: 3,
      expect: () => [
        isA<LoanBoardLoaded>().having((s) => s.busyId, 'busy', const LoanId('a')),
        isA<LoanBoardLoaded>()
            .having((s) => s.items.first.status, 'status', Approved(pickupDeadline: _now.add(pickupWindow)))
            .having((s) => s.items.first.loan.copyId, 'copy', const GameCopyId('catan-1'))
            .having((s) => s.items.first.canApprove, 'canApprove', isFalse)
            .having((s) => s.notice, 'notice', isA<LoanBoardActionSucceeded>())
            .having((s) => s.selectedId, 'selected', const LoanId('a'))
            .having((s) => s.isBusy, 'busy', isFalse),
      ],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'ignores a second action while the first one is in flight',
      build: () => _blocOver(_Desk(_threeLoans())),
      act: (bloc) async {
        await _load(bloc);
        bloc
          ..add(const LoanApprovalRequested(LoanId('a')))
          ..add(const LoanRejectionRequested(LoanId('b')));
      },
      skip: 2,
      expect: () => [
        isA<LoanBoardLoaded>().having((s) => s.busyId, 'busy', const LoanId('a')),
        isA<LoanBoardLoaded>().having((s) => s.items[1].status, 'other loan', const Pending()),
      ],
      verify: (bloc) => expect((bloc.repository as _Desk).actionCalls, 1),
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'reloads and names the error when the repository refuses',
      build: () => _blocOver(_Desk(_threeLoans())..refuse = const MemberHasOverdueLoan()),
      act: loadSelectThenApprove,
      skip: 4,
      expect: () => [
        isA<LoanBoardLoaded>()
            .having((s) => s.notice, 'notice', const LoanBoardActionRejected(MemberHasOverdueLoan()))
            .having((s) => s.isBusy, 'busy', isFalse),
      ],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'keeps the list and reports the failure when the repository cannot be reached',
      build: () => _blocOver(_Desk(_threeLoans())..failAction = true),
      act: loadSelectThenApprove,
      skip: 4,
      expect: () => [
        isA<LoanBoardLoaded>()
            .having((s) => s.items.first.status, 'status', const Pending())
            .having((s) => s.notice, 'notice', const LoanBoardActionFailed())
            .having((s) => s.selectedId, 'selected', const LoanId('a'))
            .having((s) => s.isBusy, 'busy', isFalse),
      ],
    );
  });

  group('rejection', () {
    blocTest<LoanBoardBloc, LoanBoardState>(
      'marks the loan in flight, then reloads it as rejected',
      build: () => _blocOver(_Desk(_threeLoans())),
      act: (bloc) async {
        await _load(bloc);
        bloc.add(const LoanRejectionRequested(LoanId('b')));
      },
      skip: 2,
      expect: () => [
        isA<LoanBoardLoaded>().having((s) => s.busyId, 'busy', const LoanId('b')),
        isA<LoanBoardLoaded>()
            .having((s) => s.items[1].status, 'status', const Rejected())
            .having((s) => s.items[1].canReject, 'canReject', isFalse)
            .having((s) => s.notice, 'notice', isA<LoanBoardActionSucceeded>()),
      ],
    );
  });

  group('notice', () {
    blocTest<LoanBoardBloc, LoanBoardState>(
      'is cleared once the screen has shown it',
      build: () => _blocOver(_Desk(_threeLoans())),
      act: (bloc) async {
        await _load(bloc);
        bloc.add(const LoanRejectionRequested(LoanId('b')));
        await bloc.stream.firstWhere((state) => state is LoanBoardLoaded && state.notice != null);
        bloc.add(const LoanBoardNoticeAcknowledged());
      },
      skip: 4,
      expect: () => [isA<LoanBoardLoaded>().having((s) => s.notice, 'notice', isNull)],
    );
  });

  group('filter', () {
    const onlyMarko = LoanFilter(memberId: _marko);

    blocTest<LoanBoardBloc, LoanBoardState>(
      'exposes only the matching loans and still holds every loan',
      build: () => _blocOver(_Desk(_fourMixedLoans())),
      act: (bloc) async {
        await _load(bloc);
        bloc.add(const LoanBoardFilterChanged(onlyMarko));
      },
      skip: 2,
      expect: () => [
        isA<LoanBoardLoaded>()
            .having((s) => s.filter, 'filter', onlyMarko)
            .having((s) => _ids(s.items), 'items', ['b', 'd'])
            .having((s) => _ids(s.allItems), 'allItems', ['a', 'b', 'c', 'd']),
      ],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'judges the stage at the clock, so a picked-up loan past its due date passes the overdue chip',
      build: () => _blocOver(_Desk(_fourMixedLoans())),
      act: (bloc) async {
        await _load(bloc);
        bloc.add(const LoanBoardFilterChanged(LoanFilter(stages: {LoanStage.overdue})));
      },
      skip: 2,
      expect: () => [
        isA<LoanBoardLoaded>().having((s) => _ids(s.items), 'items', ['c']),
      ],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'the same filter again changes nothing',
      build: () => _blocOver(_Desk(_fourMixedLoans())),
      act: (bloc) async {
        await _load(bloc);
        bloc
          ..add(const LoanBoardFilterChanged(onlyMarko))
          ..add(const LoanBoardFilterChanged(LoanFilter(memberId: _marko)));
      },
      skip: 2,
      expect: () => [isA<LoanBoardLoaded>().having((s) => s.filter, 'filter', onlyMarko)],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'clears the selection when the selected loan drops out of the filter',
      build: () => _blocOver(_Desk(_fourMixedLoans())),
      act: (bloc) async {
        await _load(bloc);
        bloc
          ..add(const LoanBoardSelected(LoanId('a')))
          ..add(const LoanBoardFilterChanged(onlyMarko));
      },
      skip: 2,
      expect: () => [
        isA<LoanBoardLoaded>().having((s) => s.selectedId, 'selected', const LoanId('a')),
        isA<LoanBoardLoaded>()
            .having((s) => s.selectedId, 'selected', isNull)
            .having((s) => s.selected, 'selected item', isNull),
      ],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'keeps the selection while the selected loan still matches',
      build: () => _blocOver(_Desk(_fourMixedLoans())),
      act: (bloc) async {
        await _load(bloc);
        bloc
          ..add(const LoanBoardSelected(LoanId('b')))
          ..add(const LoanBoardFilterChanged(onlyMarko));
      },
      skip: 3,
      expect: () => [isA<LoanBoardLoaded>().having((s) => s.selectedId, 'selected', const LoanId('b'))],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'the cursor walks only the filtered loans',
      build: () => _blocOver(_Desk(_fourMixedLoans())),
      act: (bloc) async {
        await _load(bloc);
        bloc
          ..add(const LoanBoardFilterChanged(onlyMarko))
          ..add(const LoanBoardSelectionMoved(1))
          ..add(const LoanBoardSelectionMoved(1))
          ..add(const LoanBoardSelectionMoved(1));
      },
      skip: 3,
      expect: () => [
        isA<LoanBoardLoaded>().having((s) => s.selectedId, 'selected', const LoanId('b')),
        isA<LoanBoardLoaded>().having((s) => s.selectedId, 'selected', const LoanId('d')),
      ],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'selecting a loan hidden by the filter is ignored',
      build: () => _blocOver(_Desk(_fourMixedLoans())),
      act: (bloc) async {
        await _load(bloc);
        bloc
          ..add(const LoanBoardFilterChanged(onlyMarko))
          ..add(const LoanBoardSelected(LoanId('a')));
      },
      skip: 3,
      expect: () => <LoanBoardState>[],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'with no matching loans the cursor does nothing, and the state stays loaded, not empty',
      build: () => _blocOver(_Desk(_fourMixedLoans())),
      act: (bloc) async {
        await _load(bloc);
        bloc
          ..add(const LoanBoardFilterChanged(LoanFilter(stages: {LoanStage.cancelled})))
          ..add(const LoanBoardSelectionMoved(1));
      },
      skip: 2,
      expect: () => [
        isA<LoanBoardLoaded>()
            .having((s) => s.items, 'items', isEmpty)
            .having((s) => s.allItems, 'allItems', hasLength(4)),
      ],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'reloading keeps the filter',
      build: () => _blocOver(_Desk(_fourMixedLoans())),
      act: (bloc) async {
        await _load(bloc);
        bloc.add(const LoanBoardFilterChanged(onlyMarko));
        await bloc.stream.firstWhere((state) => state is LoanBoardLoaded && state.filter == onlyMarko);
        bloc.add(const LoanBoardRequested());
      },
      skip: 3,
      expect: () => [
        const LoanBoardLoading(),
        isA<LoanBoardLoaded>().having((s) => s.filter, 'filter', onlyMarko).having((s) => _ids(s.items), 'items', [
          'b',
          'd',
        ]),
      ],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'an action keeps the filter, and an approved loan leaves the pending filter and the selection',
      build: () => _blocOver(_Desk(_fourMixedLoans())),
      act: (bloc) async {
        await _load(bloc);
        bloc
          ..add(const LoanBoardFilterChanged(LoanFilter(stages: {LoanStage.pending})))
          ..add(const LoanBoardSelected(LoanId('a')))
          ..add(const LoanApprovalRequested(LoanId('a')));
      },
      skip: 5,
      expect: () => [
        isA<LoanBoardLoaded>()
            .having((s) => s.filter, 'filter', const LoanFilter(stages: {LoanStage.pending}))
            .having((s) => _ids(s.items), 'items', ['b'])
            .having((s) => s.selectedId, 'selected', isNull)
            .having((s) => s.notice, 'notice', isA<LoanBoardActionSucceeded>()),
      ],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'a failed load resets the filter, just like the selection',
      build: () => _blocOver(_Desk(_fourMixedLoans())),
      act: (bloc) async {
        await _load(bloc);
        bloc.add(const LoanBoardFilterChanged(onlyMarko));
        await bloc.stream.firstWhere((state) => state is LoanBoardLoaded && state.filter == onlyMarko);
        (bloc.repository as _Desk).failLoad = true;
        bloc.add(const LoanBoardRequested());
        await bloc.stream.firstWhere((state) => state is LoanBoardFailure);
        (bloc.repository as _Desk).failLoad = false;
        bloc.add(const LoanBoardRequested());
      },
      skip: 5,
      expect: () => [
        const LoanBoardLoading(),
        isA<LoanBoardLoaded>()
            .having((s) => s.filter, 'filter', LoanFilter.none)
            .having((s) => s.items, 'items', hasLength(4)),
      ],
    );

    blocTest<LoanBoardBloc, LoanBoardState>(
      'offers the games and members of the loaded loans',
      build: () => _blocOver(_Desk(_fourMixedLoans())),
      act: _load,
      skip: 1,
      expect: () => [
        isA<LoanBoardLoaded>().having((s) => s.gameOptions, 'games', [(id: _catan.id, title: 'Catan')]).having(
          (s) => s.memberOptions,
          'members',
          [_ana, _marko],
        ),
      ],
    );
  });
}
