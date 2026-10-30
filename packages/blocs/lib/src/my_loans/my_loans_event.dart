part of 'my_loans_bloc.dart';

sealed class MyLoansEvent {
  const MyLoansEvent();
}

final class MyLoansRequested extends MyLoansEvent {
  const MyLoansRequested();
}

final class LoanCancellationRequested extends MyLoansEvent {
  const LoanCancellationRequested(this.id);

  final LoanId id;
}

final class MyLoansNoticeAcknowledged extends MyLoansEvent {
  const MyLoansNoticeAcknowledged();
}
