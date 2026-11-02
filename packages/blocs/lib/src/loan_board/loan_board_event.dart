part of 'loan_board_bloc.dart';

sealed class LoanBoardEvent {
  const LoanBoardEvent();
}

final class LoanBoardRequested extends LoanBoardEvent {
  const LoanBoardRequested();
}

final class LoanBoardSelected extends LoanBoardEvent {
  const LoanBoardSelected(this.id);

  final LoanId id;
}

final class LoanBoardSelectionMoved extends LoanBoardEvent {
  const LoanBoardSelectionMoved(this.delta);

  final int delta;
}

final class LoanBoardFilterChanged extends LoanBoardEvent {
  const LoanBoardFilterChanged(this.filter);

  final LoanFilter filter;
}

final class LoanApprovalRequested extends LoanBoardEvent {
  const LoanApprovalRequested(this.id);

  final LoanId id;
}

final class LoanRejectionRequested extends LoanBoardEvent {
  const LoanRejectionRequested(this.id);

  final LoanId id;
}

final class LoanBoardNoticeAcknowledged extends LoanBoardEvent {
  const LoanBoardNoticeAcknowledged();
}
