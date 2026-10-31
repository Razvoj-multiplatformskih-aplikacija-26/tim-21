import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

const _member = MemberId('ana');
const _catan = BoardGame(id: BoardGameId('catan'), title: 'Catan');
final _now = DateTime.utc(2026, 11, 2, 12);

final class _FixedClock implements Clock {
  @override
  DateTime now() => _now;
}

final class _Repository implements LoanRepository {
  _Repository(this.loans);

  List<Loan> loans;
  bool failLoad = false;
  bool failCancel = false;
  DomainError? refuseCancel;
  final requestedMembers = <MemberId>[];

  @override
  Future<List<Loan>> loansOf(MemberId member) async {
    requestedMembers.add(member);
    if (failLoad) throw const RepositoryException('Simulated outage');
    return loans;
  }

  @override
  Future<List<BoardGame>> games() async => const [_catan];

  @override
  Future<Result<Loan>> cancel(LoanId id) async {
    if (failCancel) throw const RepositoryException('Simulated outage');
    if (refuseCancel case final error?) return Failure(error);
    final loan = loans.single;
    loans = [loan.copyWith(status: const Cancelled())];
    return Success(loans.single);
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

MyLoansBloc _blocOver(_Repository repository) =>
    MyLoansBloc(repository: repository, clock: _FixedClock(), member: _member);

void main() {
  group('loading', () {
    blocTest<MyLoansBloc, MyLoansState>(
      'emits loading and then the loans of this member with game titles',
      build: () => _blocOver(_Repository([_loan()])),
      act: (bloc) => bloc.add(const MyLoansRequested()),
      expect: () => [
        const MyLoansLoading(),
        isA<MyLoansLoaded>().having((s) => s.items.single.gameTitle, 'title', 'Catan'),
      ],
      verify: (bloc) => expect((bloc.repository as _Repository).requestedMembers, [_member]),
    );

    blocTest<MyLoansBloc, MyLoansState>(
      'emits empty when the member has no loans',
      build: () => _blocOver(_Repository([])),
      act: (bloc) => bloc.add(const MyLoansRequested()),
      expect: () => const [MyLoansLoading(), MyLoansEmpty()],
    );

    blocTest<MyLoansBloc, MyLoansState>(
      'emits failure when the repository cannot be reached',
      build: () => _blocOver(_Repository([_loan()])..failLoad = true),
      act: (bloc) => bloc.add(const MyLoansRequested()),
      expect: () => const [MyLoansLoading(), MyLoansFailure()],
    );

    blocTest<MyLoansBloc, MyLoansState>(
      'lists the newest request first',
      build: () => _blocOver(
        _Repository([_loan(id: 'old', requestedAt: _now.subtract(const Duration(days: 3))), _loan(id: 'new')]),
      ),
      act: (bloc) => bloc.add(const MyLoansRequested()),
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
      act: (bloc) => bloc.add(const MyLoansRequested()),
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
      act: (bloc) => bloc.add(const MyLoansRequested()),
      skip: 1,
      expect: () => [isA<MyLoansLoaded>().having((s) => s.items.single.canCancel, 'canCancel', isTrue)],
    );
  });

  group('cancellation', () {
    Future<void> loadThenCancel(MyLoansBloc bloc) async {
      bloc.add(const MyLoansRequested());
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
            .having((s) => s.notice, 'notice', const CancellationFailed()),
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
}
