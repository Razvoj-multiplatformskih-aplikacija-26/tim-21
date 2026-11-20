import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

const _member = MemberId('ana');
const _ana = User(id: UserId('ana'), name: 'Ana', role: Role.member);
const _marko = User(id: UserId('marko'), name: 'Marko', role: Role.member);
const _catan = BoardGame(id: BoardGameId('catan'), title: 'Catan');
final _now = DateTime.utc(2026, 11, 2, 12);
const _outage = RepositoryException('Simulated outage', failure: RepositoryFailure.unreachable);

final class _FixedClock implements Clock {
  @override
  DateTime now() => _now;
}

final class _Repository implements LoanRepository {
  _Repository(this.loans);

  List<Loan> loans;
  bool failLoad = false;
  bool failCancel = false;
  bool failRequest = false;
  DomainError? refuseCancel;
  DomainError? refuseRequest;
  final requestedMembers = <MemberId>[];

  @override
  Future<List<Loan>> loansOf(MemberId member) async {
    requestedMembers.add(member);
    if (failLoad) throw _outage;
    return loans;
  }

  @override
  Future<List<BoardGame>> games() async => const [_catan];

  @override
  Future<Result<Loan>> cancel(LoanId id) async {
    if (failCancel) throw _outage;
    if (refuseCancel case final error?) return Failure(error);
    final loan = loans.single;
    loans = [loan.copyWith(status: const Cancelled())];
    return Success(loans.single);
  }

  @override
  Future<Result<Loan>> request({
    required MemberId member,
    required BoardGameId game,
    required LoanDuration duration,
  }) async {
    if (failRequest) throw _outage;
    if (refuseRequest case final error?) return Failure(error);
    final loan = Loan(
      id: LoanId('l-${loans.length + 1}'),
      memberId: member,
      gameId: game,
      duration: duration,
      requestedAt: _now,
    );
    loans = [...loans, loan];
    return Success(loan);
  }
}

Loan _loan({String id = 'l-1', LoanStatus status = const Pending(), DateTime? requestedAt}) => Loan(
  id: LoanId(id),
  memberId: _member,
  gameId: _catan.id,
  duration: LoanDuration.parse(7).valueOrNull!,
  requestedAt: requestedAt ?? _now,
  status: status,
);

MyLoansBloc _blocOver(_Repository repository) => MyLoansBloc(repository: repository, clock: _FixedClock());

void main() {
  group('member from the session', () {
    blocTest<MyLoansBloc, MyLoansState>(
      'is signed out until the session names a member',
      build: () => _blocOver(_Repository([_loan()])),
      act: (bloc) => bloc.add(const MyLoansRequested()),
      expect: () => const [MyLoansLoading(), MyLoansSignedOut()],
      verify: (bloc) => expect((bloc.repository as _Repository).requestedMembers, isEmpty),
    );

    blocTest<MyLoansBloc, MyLoansState>(
      'asks the repository for the loans of the member who signed in',
      build: () => _blocOver(_Repository([])),
      act: (bloc) async {
        bloc.add(const MyLoansMemberChanged(_ana));
        await bloc.stream.firstWhere((state) => state is MyLoansEmpty);
        bloc.add(const MyLoansMemberChanged(_marko));
      },
      verify: (bloc) =>
          expect((bloc.repository as _Repository).requestedMembers, const [MemberId('ana'), MemberId('marko')]),
    );

    blocTest<MyLoansBloc, MyLoansState>(
      'forgets the loans when the member signs out',
      build: () => _blocOver(_Repository([_loan()])),
      act: (bloc) async {
        bloc.add(const MyLoansMemberChanged(_ana));
        await bloc.stream.firstWhere((state) => state is MyLoansLoaded);
        bloc.add(const MyLoansMemberChanged(null));
      },
      skip: 2,
      expect: () => const [MyLoansSignedOut()],
    );

    blocTest<MyLoansBloc, MyLoansState>(
      'reloads the same member on request',
      build: () => _blocOver(_Repository([_loan()])),
      act: (bloc) async {
        bloc.add(const MyLoansMemberChanged(_ana));
        await bloc.stream.firstWhere((state) => state is MyLoansLoaded);
        bloc.add(const MyLoansRequested());
      },
      skip: 2,
      expect: () => [const MyLoansLoading(), isA<MyLoansLoaded>()],
      verify: (bloc) => expect((bloc.repository as _Repository).requestedMembers, [_member, _member]),
    );
  });

  group('loading', () {
    blocTest<MyLoansBloc, MyLoansState>(
      'emits loading and then the loans of this member with game titles',
      build: () => _blocOver(_Repository([_loan()])),
      act: (bloc) => bloc.add(const MyLoansMemberChanged(_ana)),
      expect: () => [
        const MyLoansLoading(),
        isA<MyLoansLoaded>().having((s) => s.items.single.gameTitle, 'title', 'Catan'),
      ],
      verify: (bloc) => expect((bloc.repository as _Repository).requestedMembers, [_member]),
    );

    blocTest<MyLoansBloc, MyLoansState>(
      'emits empty when the member has no loans',
      build: () => _blocOver(_Repository([])),
      act: (bloc) => bloc.add(const MyLoansMemberChanged(_ana)),
      expect: () => const [MyLoansLoading(), MyLoansEmpty()],
    );

    blocTest<MyLoansBloc, MyLoansState>(
      'emits failure with its cause when the repository cannot be reached',
      build: () => _blocOver(_Repository([_loan()])..failLoad = true),
      act: (bloc) => bloc.add(const MyLoansMemberChanged(_ana)),
      expect: () => const [MyLoansLoading(), MyLoansFailure(_outage)],
    );

    blocTest<MyLoansBloc, MyLoansState>(
      'lists the newest request first',
      build: () => _blocOver(
        _Repository([_loan(id: 'old', requestedAt: _now.subtract(const Duration(days: 3))), _loan(id: 'new')]),
      ),
      act: (bloc) => bloc.add(const MyLoansMemberChanged(_ana)),
      skip: 1,
      expect: () => [
        isA<MyLoansLoaded>().having((s) => s.items.map((i) => i.loan.id.value), 'ids', ['new', 'old']),
      ],
    );
  });

  group('items', () {
    blocTest<MyLoansBloc, MyLoansState>(
      'a loan past its due date is shown as overdue and cannot be cancelled',
      build: () => _blocOver(_Repository([_loan(status: PickedUp(dueAt: _now.subtract(const Duration(days: 1))))])),
      act: (bloc) => bloc.add(const MyLoansMemberChanged(_ana)),
      skip: 1,
      expect: () => [
        isA<MyLoansLoaded>()
            .having((s) => s.items.single.status, 'status', isA<Overdue>())
            .having((s) => s.items.single.canCancel, 'canCancel', isFalse),
      ],
    );

    blocTest<MyLoansBloc, MyLoansState>(
      'a pending loan can be cancelled',
      build: () => _blocOver(_Repository([_loan()])),
      act: (bloc) => bloc.add(const MyLoansMemberChanged(_ana)),
      skip: 1,
      expect: () => [isA<MyLoansLoaded>().having((s) => s.items.single.canCancel, 'canCancel', isTrue)],
    );

    blocTest<MyLoansBloc, MyLoansState>(
      'a loan of another member cannot be cancelled, as AccessPolicy says',
      build: () => _blocOver(_Repository([_loan()])),
      act: (bloc) => bloc.add(const MyLoansMemberChanged(_marko)),
      skip: 1,
      expect: () => [isA<MyLoansLoaded>().having((s) => s.items.single.canCancel, 'canCancel', isFalse)],
    );
  });

  group('cancellation', () {
    Future<void> loadThenCancel(MyLoansBloc bloc) async {
      bloc.add(const MyLoansMemberChanged(_ana));
      await bloc.stream.firstWhere((state) => state is MyLoansLoaded);
      bloc.add(const LoanCancellationRequested(LoanId('l-1')));
    }

    blocTest<MyLoansBloc, MyLoansState>(
      'marks the loan in flight, then reloads and reports success',
      build: () => _blocOver(_Repository([_loan()])),
      act: loadThenCancel,
      skip: 2,
      expect: () => [
        isA<MyLoansLoaded>().having((s) => s.cancellingId, 'cancelling', const LoanId('l-1')),
        isA<MyLoansLoaded>()
            .having((s) => s.items.single.status, 'status', const Cancelled())
            .having((s) => s.notice, 'notice', const LoanCancelled())
            .having((s) => s.isBusy, 'busy', isFalse),
      ],
    );

    blocTest<MyLoansBloc, MyLoansState>(
      'reloads and names the error when the repository refuses',
      build: () {
        final refusal = InvalidTransition(
          from: PickedUp(dueAt: _now),
          to: const Cancelled(),
        );
        return _blocOver(_Repository([_loan()])..refuseCancel = refusal);
      },
      act: loadThenCancel,
      skip: 3,
      expect: () => [isA<MyLoansLoaded>().having((s) => s.notice, 'notice', isA<CancellationRejected>())],
    );

    blocTest<MyLoansBloc, MyLoansState>(
      'keeps the list and reports the failure when the repository cannot be reached',
      build: () => _blocOver(_Repository([_loan()])..failCancel = true),
      act: loadThenCancel,
      skip: 3,
      expect: () => [
        isA<MyLoansLoaded>()
            .having((s) => s.items.single.status, 'status', const Pending())
            .having((s) => s.notice, 'notice', const CancellationFailed(_outage)),
      ],
    );

    blocTest<MyLoansBloc, MyLoansState>(
      'clears the notice once the screen has shown it',
      build: () => _blocOver(_Repository([_loan()])),
      act: (bloc) async {
        await loadThenCancel(bloc);
        await bloc.stream.firstWhere((state) => state is MyLoansLoaded && state.notice != null);
        bloc.add(const MyLoansNoticeAcknowledged());
      },
      skip: 4,
      expect: () => [isA<MyLoansLoaded>().having((s) => s.notice, 'notice', isNull)],
    );
  });

  group('request', () {
    Future<void> loadThenRequest(MyLoansBloc bloc) async {
      bloc.add(const MyLoansMemberChanged(_ana));
      await bloc.stream.firstWhere((state) => state is MyLoansLoaded);
      bloc.add(LoanRequestSubmitted(game: _catan.id, duration: LoanDuration.parse(3).valueOrNull!));
    }

    blocTest<MyLoansBloc, MyLoansState>(
      'adds a pending loan and reports that the request was sent',
      build: () => _blocOver(_Repository([_loan()])),
      act: loadThenRequest,
      skip: 2,
      expect: () => [
        isA<MyLoansLoaded>()
            .having((s) => s.items.length, 'items', 2)
            .having((s) => s.notice, 'notice', const LoanRequestSent()),
      ],
    );

    blocTest<MyLoansBloc, MyLoansState>(
      'reports the domain error when a rule refuses the request',
      build: () => _blocOver(_Repository([_loan()])..refuseRequest = const MemberHasOverdueLoan()),
      act: loadThenRequest,
      skip: 2,
      expect: () => [
        isA<MyLoansLoaded>()
            .having((s) => s.items.length, 'items', 1)
            .having((s) => s.notice, 'notice', const LoanRequestRejected(MemberHasOverdueLoan())),
      ],
    );

    blocTest<MyLoansBloc, MyLoansState>(
      'reports a failure when the repository cannot be reached',
      build: () => _blocOver(_Repository([_loan()])..failRequest = true),
      act: loadThenRequest,
      skip: 2,
      expect: () => [isA<MyLoansLoaded>().having((s) => s.notice, 'notice', const LoanRequestFailed(_outage))],
    );
  });
}
