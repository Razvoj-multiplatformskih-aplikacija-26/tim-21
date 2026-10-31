part of 'my_loans_bloc.dart';

sealed class MyLoansState extends Equatable {
  const MyLoansState();

  bool get isBusy => false;

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class MyLoansLoading extends MyLoansState {
  const MyLoansLoading();

  @override
  bool get isBusy => true;
}

final class MyLoansFailure extends MyLoansState {
  const MyLoansFailure();
}

final class MyLoansEmpty extends MyLoansState {
  const MyLoansEmpty();
}

final class MyLoansLoaded extends MyLoansState {
  const MyLoansLoaded({required this.items, this.notice, this.cancellingId});

  final List<LoanItem> items;
  final MyLoansNotice? notice;
  final LoanId? cancellingId;

  @override
  bool get isBusy => cancellingId != null;

  bool isCancelling(LoanItem item) => cancellingId == item.loan.id;

  MyLoansLoaded withNotice(MyLoansNotice? notice) => MyLoansLoaded(items: items, notice: notice);

  MyLoansLoaded withCancelling(LoanId id) => MyLoansLoaded(items: items, cancellingId: id);

  @override
  List<Object?> get props => [items, notice, cancellingId];

  @override
  String toString() => 'MyLoansLoaded(${items.length} loans, notice: $notice, cancelling: $cancellingId)';
}

final class LoanItem extends Equatable {
  const LoanItem({required this.loan, required this.gameTitle, required this.status, required this.canCancel});

  final Loan loan;
  final String gameTitle;
  final LoanStatus status;
  final bool canCancel;

  @override
  List<Object?> get props => [loan, gameTitle, status, canCancel];
}

sealed class MyLoansNotice extends Equatable {
  const MyLoansNotice();

  @override
  List<Object?> get props => const [];
}

final class LoanCancelled extends MyLoansNotice {
  const LoanCancelled();
}

final class CancellationRejected extends MyLoansNotice {
  const CancellationRejected(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

final class CancellationFailed extends MyLoansNotice {
  const CancellationFailed();
}
