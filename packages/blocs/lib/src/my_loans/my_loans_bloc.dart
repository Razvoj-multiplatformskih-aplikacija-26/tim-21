import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'my_loans_event.dart';
part 'my_loans_state.dart';

final class MyLoansBloc extends Bloc<MyLoansEvent, MyLoansState> {
  MyLoansBloc({required this.repository, required this.clock}) : super(const MyLoansLoading()) {
    on<MyLoansMemberChanged>((event, emit) async {
      _member = event.member;
      if (event.member == null) return emit(const MyLoansSignedOut());
      emit(const MyLoansLoading());
      await _reload(emit);
    });
    on<MyLoansRequested>((event, emit) async {
      emit(const MyLoansLoading());
      await _reload(emit);
    });
    on<LoanCancellationRequested>(_onCancellationRequested);
    on<LoanRequestSubmitted>(_onRequestSubmitted);
    on<MyLoansNoticeAcknowledged>((event, emit) {
      final current = state;
      if (current is MyLoansLoaded && current.notice != null) emit(current.withNotice(null));
    });
  }

  final LoanRepository repository;
  final Clock clock;
  User? _member;

  Future<void> _onCancellationRequested(LoanCancellationRequested event, Emitter<MyLoansState> emit) async {
    final current = state;
    if (current is! MyLoansLoaded || current.isBusy || _member == null) return;
    emit(current.withCancelling(event.id));
    final Result<Loan> result;
    try {
      result = await repository.cancel(event.id);
    } on RepositoryException catch (cause) {
      emit(current.withNotice(CancellationFailed(cause)));
      return;
    }
    final notice = switch (result) {
      Success() => const LoanCancelled(),
      Failure(:final error) => CancellationRejected(error),
    };
    await _reload(emit, notice: notice);
  }

  Future<void> _onRequestSubmitted(LoanRequestSubmitted event, Emitter<MyLoansState> emit) async {
    final member = _member;
    if (member == null) return;
    final Result<Loan> result;
    try {
      result = await repository.request(member: _memberId(member), game: event.game, duration: event.duration);
    } on RepositoryException catch (cause) {
      final current = state;
      if (current is MyLoansLoaded) emit(current.withNotice(LoanRequestFailed(cause)));
      return;
    }
    final notice = switch (result) {
      Success() => const LoanRequestSent(),
      Failure(:final error) => LoanRequestRejected(error),
    };
    await _reload(emit, notice: notice);
  }

  Future<void> _reload(Emitter<MyLoansState> emit, {MyLoansNotice? notice}) async {
    final member = _member;
    if (member == null) return emit(const MyLoansSignedOut());
    try {
      final loans = await repository.loansOf(_memberId(member));
      if (member != _member) return;
      if (loans.isEmpty) {
        emit(const MyLoansEmpty());
        return;
      }
      final games = await repository.games();
      if (member != _member) return;
      emit(MyLoansLoaded(items: _itemsFrom(member, loans, games), notice: notice));
    } on RepositoryException catch (cause) {
      if (member == _member) emit(MyLoansFailure(cause));
    }
  }

  List<LoanItem> _itemsFrom(User member, List<Loan> loans, List<BoardGame> games) {
    final titles = {for (final game in games) game.id: game.title};
    final now = clock.now();
    final newestFirst = [...loans]..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return [
      for (final loan in newestFirst)
        LoanItem(
          loan: loan,
          gameTitle: titles[loan.gameId] ?? loan.gameId.value,
          status: loan.statusAt(now),
          canCancel: AccessPolicy.canCancel(member, loan) && canTransition(loan.statusAt(now), const Cancelled()),
        ),
    ];
  }

  static MemberId _memberId(User member) => MemberId(member.id.value);
}
