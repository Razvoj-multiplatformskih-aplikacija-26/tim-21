import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

Map<String, Object?> overTheWire(Map<String, Object?> json) => jsonDecode(jsonEncode(json)) as Map<String, Object?>;

Loan sendAndReceive(Loan loan) => LoanDto.fromJson(overTheWire(loan.toDto().toJson())).toDomain();

void main() {
  final requestedAt = DateTime.utc(2026, 11, 20, 12);
  final loan = Loan(
    id: const LoanId('loan-1'),
    memberId: const MemberId('clan1'),
    gameId: const BoardGameId('catan'),
    duration: LoanDuration.parse(5).valueOrNull!,
    requestedAt: requestedAt,
  );

  test('a loan in every stored status survives the trip through the contract unchanged', () {
    final day = DateTime.utc(2026, 11, 22);
    for (final status in <LoanStatus>[
      const Pending(),
      Approved(pickupDeadline: day),
      PickedUp(dueAt: day),
      Returned(returnedAt: day),
      const Rejected(),
      const Cancelled(),
    ]) {
      final sent = loan.copyWith(status: status, copyId: status is Pending ? null : const GameCopyId('catan-1'));
      expect(sendAndReceive(sent), sent, reason: '$status');
    }
  });

  test('overdue is not sent: it goes out as picked up and the receiver derives it again', () {
    final dueAt = DateTime.utc(2026, 11, 18);
    final now = DateTime.utc(2026, 11, 20);
    final overdue = Overdue(dueAt: dueAt);

    expect(overdue.toDto().kind, LoanStatusDto.pickedUp);
    final received = sendAndReceive(loan.copyWith(status: PickedUp(dueAt: dueAt)));
    expect(received.status, PickedUp(dueAt: dueAt));
    expect(received.statusAt(now), overdue);
  });

  test('a loan longer than today\'s limit still arrives', () {
    final json = {...loan.toDto().toJson(), 'durationDays': 8};

    expect(LoanDto.fromJson(json).toDomain().duration.days, 8);
  });

  test('an unknown status kind is not accepted', () {
    expect(() => const LoanStatusDto(kind: 'overdue').toDomain(), throwsFormatException);
    expect(() => const LoanStatusDto(kind: LoanStatusDto.approved).toDomain(), throwsFormatException);
  });

  test('a board game and a user survive the trip', () {
    const game = BoardGame(id: BoardGameId('catan'), title: 'Catan');
    expect(BoardGameDto.fromJson(overTheWire(game.toDto().toJson())).toDomain(), game);

    for (final user in const [
      User(id: UserId('clan1'), name: 'Ana Petrović', role: Role.member),
      User(id: UserId('bibliotekar1'), name: 'Marko Marković', role: Role.librarian),
    ]) {
      expect(UserDto.fromJson(overTheWire(user.toDto().toJson())).toDomain(), user);
    }
    expect(() => const UserDto(id: 'x', name: 'X', role: 'manager').toDomain(), throwsFormatException);
  });

  test('every domain error has its status and code and comes back as the same error with the same limits', () {
    final transition = InvalidTransition(
      from: Returned(returnedAt: requestedAt),
      to: const Cancelled(),
    );
    final cases = <(DomainError, int, String)>[
      (const InvalidLoanDuration(9, min: 1, max: 7), 422, ErrorCodes.invalidLoanDuration),
      (const TooManyActiveLoans(3, max: 3), 422, ErrorCodes.tooManyActiveLoans),
      (const MemberHasOverdueLoan(), 422, ErrorCodes.memberHasOverdueLoan),
      (const NoFreeCopy(), 409, ErrorCodes.noFreeCopy),
      (transition, 409, ErrorCodes.invalidTransition),
      (const NotAllowed(), 403, ErrorCodes.notAllowed),
      (const LoanNotFound(), 404, ErrorCodes.notFound),
    ];

    for (final (error, status, code) in cases) {
      final problem = ProblemDto.fromJson(overTheWire(error.toProblem().toJson()));
      expect((problem.status, problem.code), (status, code), reason: '$error');
      expect(problem.toDomainError(), error, reason: '$error');
    }
  });

  test('a limit changed on the server reaches the client through the error', () {
    final problem = ProblemDto.fromJson(
      overTheWire(const InvalidLoanDuration(15, min: 1, max: 14).toProblem().toJson()),
    );

    expect(problem.toDomainError(), const InvalidLoanDuration(15, min: 1, max: 14));
  });

  test('an unknown code, or a known code without its data, is not turned into a domain error', () {
    expect(const ProblemDto(status: 422, code: 'loan-extension-limit', title: 'New rule').toDomainError(), isNull);
    expect(const ProblemDto(status: 401, code: ErrorCodes.sessionExpired, title: 'Expired').toDomainError(), isNull);
    expect(
      const ProblemDto(status: 422, code: ErrorCodes.tooManyActiveLoans, title: 'No data').toDomainError(),
      isNull,
    );
  });
}
