import 'json.dart';

final class LoanStatusDto {
  const LoanStatusDto({required this.kind, this.pickupDeadline, this.dueAt, this.returnedAt});

  static const pending = 'pending';
  static const approved = 'approved';
  static const pickedUp = 'picked_up';
  static const returned = 'returned';
  static const rejected = 'rejected';
  static const cancelled = 'cancelled';

  final String kind;
  final DateTime? pickupDeadline;
  final DateTime? dueAt;
  final DateTime? returnedAt;

  Map<String, Object?> toJson() => {
    'kind': kind,
    if (pickupDeadline case final pickupDeadline?) 'pickupDeadline': instantToJson(pickupDeadline),
    if (dueAt case final dueAt?) 'dueAt': instantToJson(dueAt),
    if (returnedAt case final returnedAt?) 'returnedAt': instantToJson(returnedAt),
  };

  factory LoanStatusDto.fromJson(Map<String, Object?> json) => LoanStatusDto(
    kind: jsonString(json, 'kind'),
    pickupDeadline: jsonOptionalInstant(json, 'pickupDeadline'),
    dueAt: jsonOptionalInstant(json, 'dueAt'),
    returnedAt: jsonOptionalInstant(json, 'returnedAt'),
  );
}

final class LoanDto {
  const LoanDto({
    required this.id,
    required this.memberId,
    required this.gameId,
    required this.durationDays,
    required this.requestedAt,
    required this.status,
    this.copyId,
  });

  final String id;
  final String memberId;
  final String gameId;
  final int durationDays;
  final DateTime requestedAt;
  final LoanStatusDto status;
  final String? copyId;

  Map<String, Object?> toJson() => {
    'id': id,
    'memberId': memberId,
    'gameId': gameId,
    'durationDays': durationDays,
    'requestedAt': instantToJson(requestedAt),
    'status': status.toJson(),
    'copyId': ?copyId,
  };

  factory LoanDto.fromJson(Map<String, Object?> json) => LoanDto(
    id: jsonString(json, 'id'),
    memberId: jsonString(json, 'memberId'),
    gameId: jsonString(json, 'gameId'),
    durationDays: jsonInt(json, 'durationDays'),
    requestedAt: jsonInstant(json, 'requestedAt'),
    status: LoanStatusDto.fromJson(jsonObject(json['status'])),
    copyId: jsonOptionalString(json, 'copyId'),
  );
}

final class NewLoanDto {
  const NewLoanDto({required this.gameId, required this.durationDays});

  final String gameId;
  final int durationDays;

  Map<String, Object?> toJson() => {'gameId': gameId, 'durationDays': durationDays};

  factory NewLoanDto.fromJson(Map<String, Object?> json) =>
      NewLoanDto(gameId: jsonString(json, 'gameId'), durationDays: jsonInt(json, 'durationDays'));
}
