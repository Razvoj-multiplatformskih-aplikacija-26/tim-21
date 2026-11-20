abstract final class BrandColors {
  static const blue = 0xFF2E6BB8;
}

final class StatusColorTokens {
  const StatusColorTokens({
    required this.pending,
    required this.onPending,
    required this.approved,
    required this.onApproved,
    required this.pickedUp,
    required this.onPickedUp,
    required this.overdue,
    required this.onOverdue,
    required this.returned,
    required this.onReturned,
    required this.rejected,
    required this.onRejected,
    required this.cancelled,
    required this.onCancelled,
  });

  final int pending;
  final int onPending;
  final int approved;
  final int onApproved;
  final int pickedUp;
  final int onPickedUp;
  final int overdue;
  final int onOverdue;
  final int returned;
  final int onReturned;
  final int rejected;
  final int onRejected;
  final int cancelled;
  final int onCancelled;

  static const light = StatusColorTokens(
    pending: 0xFFF6E3C4,
    onPending: 0xFF7D5313,
    approved: 0xFFD5E8DA,
    onApproved: 0xFF2E6B45,
    pickedUp: 0xFFC6D6EA,
    onPickedUp: 0xFF245693,
    overdue: 0xFFF9DEDC,
    onOverdue: 0xFF8C1D18,
    returned: 0xFFD3ECEA,
    onReturned: 0xFF1F5E58,
    rejected: 0xFFECD6D6,
    onRejected: 0xFF8A4A4A,
    cancelled: 0xFFE4E7EB,
    onCancelled: 0xFF4F5D6E,
  );

  static const dark = StatusColorTokens(
    pending: 0xFF4F3A10,
    onPending: 0xFFF0C27A,
    approved: 0xFF1F4A30,
    onApproved: 0xFF8FD1A5,
    pickedUp: 0xFF24436B,
    onPickedUp: 0xFFA9CBF0,
    overdue: 0xFF8C1D18,
    onOverdue: 0xFFF9DEDC,
    returned: 0xFF17423E,
    onReturned: 0xFF8ED3CB,
    rejected: 0xFF4E2626,
    onRejected: 0xFFE3A3A3,
    cancelled: 0xFF33404F,
    onCancelled: 0xFFC6D5E6,
  );
}
