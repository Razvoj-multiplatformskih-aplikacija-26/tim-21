part of 'loan_board_bloc.dart';

sealed class LoanBoardState extends Equatable {
  const LoanBoardState();

  bool get isBusy => false;

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class LoanBoardLoading extends LoanBoardState {
  const LoanBoardLoading();

  @override
  bool get isBusy => true;
}

final class LoanBoardFailure extends LoanBoardState {
  const LoanBoardFailure();
}

final class LoanBoardEmpty extends LoanBoardState {
  const LoanBoardEmpty();
}

final class LoanBoardLoaded extends LoanBoardState {
  const LoanBoardLoaded({
    required this.allItems,
    required this.items,
    this.filter = LoanFilter.none,
    this.selectedId,
    this.busyId,
    this.notice,
  });

  final List<LoanBoardItem> allItems;

  final List<LoanBoardItem> items;
  final LoanFilter filter;
  final LoanId? selectedId;
  final LoanId? busyId;
  final LoanBoardNotice? notice;

  @override
  bool get isBusy => busyId != null;

  bool isBusyWith(LoanBoardItem item) => busyId == item.loan.id;

  LoanBoardItem? get selected => items.where((item) => item.loan.id == selectedId).firstOrNull;

  List<({BoardGameId id, String title})> get gameOptions {
    final titles = {for (final item in allItems) item.loan.gameId: item.gameTitle};
    return [for (final MapEntry(:key, :value) in titles.entries) (id: key, title: value)]
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  List<MemberId> get memberOptions =>
      {for (final item in allItems) item.loan.memberId}.toList()..sort((a, b) => a.value.compareTo(b.value));

  LoanBoardLoaded copyWith({
    LoanId? selectedId,
    LoanId? busyId,
    bool clearBusy = false,
    LoanBoardNotice? notice,
    bool clearNotice = false,
  }) => LoanBoardLoaded(
    allItems: allItems,
    items: items,
    filter: filter,
    selectedId: selectedId ?? this.selectedId,
    busyId: clearBusy ? null : (busyId ?? this.busyId),
    notice: clearNotice ? null : (notice ?? this.notice),
  );

  @override
  List<Object?> get props => [allItems, items, filter, selectedId, busyId, notice];

  @override
  String toString() => [
    'LoanBoardLoaded(${items.length} of ${allItems.length} loans',
    if (!filter.isEmpty) ', $filter',
    if (selectedId case final id?) ', selected ${id.value}',
    if (busyId case final id?) ', busy ${id.value}',
    if (notice case final notice?) ', ${notice.runtimeType}',
    ')',
  ].join();
}

final class LoanBoardItem extends Equatable {
  const LoanBoardItem({
    required this.loan,
    required this.gameTitle,
    required this.status,
    required this.canApprove,
    required this.canReject,
  });

  final Loan loan;
  final String gameTitle;
  final LoanStatus status;
  final bool canApprove;
  final bool canReject;

  @override
  List<Object?> get props => [loan, gameTitle, status, canApprove, canReject];
}

sealed class LoanBoardNotice extends Equatable {
  const LoanBoardNotice();

  @override
  List<Object?> get props => const [];
}

final class LoanBoardActionSucceeded extends LoanBoardNotice {
  const LoanBoardActionSucceeded(this.loan);

  final Loan loan;

  @override
  List<Object?> get props => [loan];
}

final class LoanBoardActionRejected extends LoanBoardNotice {
  const LoanBoardActionRejected(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

final class LoanBoardActionFailed extends LoanBoardNotice {
  const LoanBoardActionFailed();
}
