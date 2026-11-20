import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

extension LoanStatusMapping on LoanStatus {
  LoanStatusDto toDto() => switch (this) {
    Pending() => const LoanStatusDto(kind: LoanStatusDto.pending),
    Approved(:final pickupDeadline) => LoanStatusDto(kind: LoanStatusDto.approved, pickupDeadline: pickupDeadline),
    PickedUp(:final dueAt) || Overdue(:final dueAt) => LoanStatusDto(kind: LoanStatusDto.pickedUp, dueAt: dueAt),
    Returned(:final returnedAt) => LoanStatusDto(kind: LoanStatusDto.returned, returnedAt: returnedAt),
    Rejected() => const LoanStatusDto(kind: LoanStatusDto.rejected),
    Cancelled() => const LoanStatusDto(kind: LoanStatusDto.cancelled),
  };
}

extension LoanStatusDtoMapping on LoanStatusDto {
  LoanStatus toDomain() => switch (this) {
    LoanStatusDto(kind: LoanStatusDto.pending) => const Pending(),
    LoanStatusDto(kind: LoanStatusDto.approved, :final pickupDeadline?) => Approved(pickupDeadline: pickupDeadline),
    LoanStatusDto(kind: LoanStatusDto.pickedUp, :final dueAt?) => PickedUp(dueAt: dueAt),
    LoanStatusDto(kind: LoanStatusDto.returned, :final returnedAt?) => Returned(returnedAt: returnedAt),
    LoanStatusDto(kind: LoanStatusDto.rejected) => const Rejected(),
    LoanStatusDto(kind: LoanStatusDto.cancelled) => const Cancelled(),
    _ => throw FormatException('Unknown loan status or a missing date', kind),
  };
}

extension LoanMapping on Loan {
  LoanDto toDto() => LoanDto(
    id: id.value,
    memberId: memberId.value,
    gameId: gameId.value,
    durationDays: duration.days,
    requestedAt: requestedAt,
    status: status.toDto(),
    copyId: copyId?.value,
  );
}

extension LoanDtoMapping on LoanDto {
  Loan toDomain() => Loan(
    id: LoanId(id),
    memberId: MemberId(memberId),
    gameId: BoardGameId(gameId),
    duration: LoanDuration.existing(durationDays),
    requestedAt: requestedAt,
    status: status.toDomain(),
    copyId: copyId == null ? null : GameCopyId(copyId!),
  );
}
