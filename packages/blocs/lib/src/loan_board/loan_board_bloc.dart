import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'loan_board_event.dart';
part 'loan_board_state.dart';

final class LoanBoardBloc extends Bloc<LoanBoardEvent, LoanBoardState> {
  LoanBoardBloc({required this.repository, required this.clock}) : super(const LoanBoardLoading()) {
    on<LoanBoardRequested>((event, emit) async {
      final keep = _selectedId;
      final filter = _filter;
      emit(const LoanBoardLoading());
      await _reload(emit, keep: keep, filter: filter);
    });
    on<LoanBoardSelected>((event, emit) {
      final current = state;
      if (current is! LoanBoardLoaded || !current.items.any((item) => item.loan.id == event.id)) return;
      emit(current.copyWith(selectedId: event.id));
    });
    on<LoanBoardSelectionMoved>((event, emit) {
      final current = state;
      if (current is! LoanBoardLoaded || current.items.isEmpty) return;
      final from = current.items.indexWhere((item) => item.loan.id == current.selectedId);
      final to = (from + event.delta).clamp(0, current.items.length - 1);
      emit(current.copyWith(selectedId: current.items[to].loan.id));
    });
    on<LoanBoardFilterChanged>((event, emit) {
      final current = state;
      if (current is! LoanBoardLoaded || current.filter == event.filter) return;
      emit(
        _loaded(
          current.allItems,
          event.filter,
          keep: current.selectedId,
          busyId: current.busyId,
          notice: current.notice,
        ),
      );
    });
    on<LoanApprovalRequested>((event, emit) => _act(emit, event.id, () => repository.approve(event.id)));
    on<LoanRejectionRequested>((event, emit) => _act(emit, event.id, () => repository.reject(event.id)));
    on<LoanBoardNoticeAcknowledged>((event, emit) {
      final current = state;
      if (current is LoanBoardLoaded && current.notice != null) emit(current.copyWith(clearNotice: true));
    });
  }

  final LoanDeskRepository repository;
  final Clock clock;

  LoanId? get _selectedId => switch (state) {
    LoanBoardLoaded(:final selectedId) => selectedId,
    _ => null,
  };

  LoanFilter get _filter => switch (state) {
    LoanBoardLoaded(:final filter) => filter,
    _ => LoanFilter.none,
  };

  Future<void> _act(Emitter<LoanBoardState> emit, LoanId id, Future<Result<Loan>> Function() action) async {
    final current = state;
    if (current is! LoanBoardLoaded || current.isBusy) return;
    emit(current.copyWith(busyId: id, clearNotice: true));
    final Result<Loan> result;
    try {
      result = await action();
    } on RepositoryException {
      final latest = state;
      if (latest is LoanBoardLoaded) emit(latest.copyWith(clearBusy: true, notice: const LoanBoardActionFailed()));
      return;
    }
    final notice = switch (result) {
      Success(:final value) => LoanBoardActionSucceeded(value),
      Failure(:final error) => LoanBoardActionRejected(error),
    };
    await _reload(emit, keep: _selectedId, filter: _filter, notice: notice);
  }

  Future<void> _reload(
    Emitter<LoanBoardState> emit, {
    required LoanFilter filter,
    LoanId? keep,
    LoanBoardNotice? notice,
  }) async {
    try {
      final loans = await repository.allLoans();
      if (loans.isEmpty) {
        emit(const LoanBoardEmpty());
        return;
      }
      final games = await repository.games();
      emit(_loaded(_itemsFrom(loans, games), filter, keep: keep, notice: notice));
    } on RepositoryException {
      emit(const LoanBoardFailure());
    }
  }

  LoanBoardLoaded _loaded(
    List<LoanBoardItem> allItems,
    LoanFilter filter, {
    LoanId? keep,
    LoanId? busyId,
    LoanBoardNotice? notice,
  }) {
    final passing = {
      for (final loan in filterLoans([for (final item in allItems) item.loan], filter, clock.now())) loan.id,
    };
    final items = [
      for (final item in allItems)
        if (passing.contains(item.loan.id)) item,
    ];
    return LoanBoardLoaded(
      allItems: allItems,
      items: items,
      filter: filter,
      selectedId: passing.contains(keep) ? keep : null,
      busyId: busyId,
      notice: notice,
    );
  }

  List<LoanBoardItem> _itemsFrom(List<Loan> loans, List<BoardGame> games) {
    final titles = {for (final game in games) game.id: game.title};
    final now = clock.now();
    final newestFirst = [...loans]..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return [for (final loan in newestFirst) _itemFor(loan, titles[loan.gameId] ?? loan.gameId.value, now)];
  }

  LoanBoardItem _itemFor(Loan loan, String gameTitle, DateTime now) {
    final status = loan.statusAt(now);
    return LoanBoardItem(
      loan: loan,
      gameTitle: gameTitle,
      status: status,
      canApprove: canTransition(status, Approved(pickupDeadline: now)),
      canReject: canTransition(status, const Rejected()),
    );
  }
}
