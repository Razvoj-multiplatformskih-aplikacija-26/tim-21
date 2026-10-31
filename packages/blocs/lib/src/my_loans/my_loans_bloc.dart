import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'my_loans_event.dart';
part 'my_loans_state.dart';

final class MyLoansBloc extends Bloc<MyLoansEvent, MyLoansState> {
  MyLoansBloc({required this.repository, required this.clock, required this.member}) : super(const MyLoansLoading()) {
    on<MyLoansRequested>((event, emit) async {
      emit(const MyLoansLoading());
      await _reload(emit);
    });
    on<LoanCancellationRequested>(_onCancellationRequested);
    on<MyLoansNoticeAcknowledged>((event, emit) {
      final current = state;
      if (current is MyLoansLoaded && current.notice != null) emit(current.withNotice(null));
    });
  }

  final LoanRepository repository;
  final Clock clock;
  final MemberId member;

  Future<void> _onCancellationRequested(LoanCancellationRequested event, Emitter<MyLoansState> emit) async {
    final current = state;
    if (current is! MyLoansLoaded || current.isBusy) return;
    emit(current.withCancelling(event.id));
    final Result<Loan> result;
    try {
      result = await repository.cancel(event.id);
    } on RepositoryException {
      emit(current.withNotice(const CancellationFailed()));
      return;
    }
    final notice = switch (result) {
      Success() => const LoanCancelled(),
      Failure(:final error) => CancellationRejected(error),
    };
    await _reload(emit, notice: notice);
  }

  Future<void> _reload(Emitter<MyLoansState> emit, {MyLoansNotice? notice}) async {
    try {
      final loans = await repository.loansOf(member);
      if (loans.isEmpty) {
        emit(const MyLoansEmpty());
        return;
      }
      final games = await repository.games();
      emit(MyLoansLoaded(items: _itemsFrom(loans, games), notice: notice));
    } on RepositoryException {
      emit(const MyLoansFailure());
    }
  }

  List<LoanItem> _itemsFrom(List<Loan> loans, List<BoardGame> games) {
    final titles = {for (final game in games) game.id: game.title};
    final now = clock.now();
    final newestFirst = [...loans]..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return [
      for (final loan in newestFirst)
        LoanItem(
          loan: loan,
          gameTitle: titles[loan.gameId] ?? loan.gameId.value,
          status: loan.statusAt(now),
          canCancel: canTransition(loan.statusAt(now), const Cancelled()),
        ),
    ];
  }
}
