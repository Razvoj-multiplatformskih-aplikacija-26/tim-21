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

final class LoanRequestSubmitted extends MyLoansEvent {
  const LoanRequestSubmitted({required this.game, required this.duration});

  final BoardGameId game;
  final LoanDuration duration;
}

final class MyLoansNoticeAcknowledged extends MyLoansEvent {
  const MyLoansNoticeAcknowledged();
}
