import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:test/test.dart';

Map<String, Object?> overTheWire(Map<String, Object?> json) => jsonDecode(jsonEncode(json)) as Map<String, Object?>;

final requestedAt = DateTime.utc(2026, 11, 20, 12);

LoanDto loanWith(LoanStatusDto status, {String? copyId}) => LoanDto(
  id: 'loan-1',
  memberId: 'clan1',
  gameId: 'catan',
  durationDays: 5,
  requestedAt: requestedAt,
  status: status,
  copyId: copyId,
);

void main() {
  group('every DTO survives the trip over the wire', () {
    test('login', () {
      for (final login in const [
        LoginDto(username: 'clan1', password: 'tajna'),
        LoginDto(username: 'bibliotekar1', password: 'tajna', cookie: true),
      ]) {
        final back = LoginDto.fromJson(overTheWire(login.toJson()));
        expect((back.username, back.password, back.cookie), (login.username, login.password, login.cookie));
      }
    });

    test('user', () {
      const user = UserDto(id: 'clan1', name: 'Ana Petrović', role: 'member');
      final back = UserDto.fromJson(overTheWire(user.toJson()));
      expect((back.id, back.name, back.role), (user.id, user.name, user.role));
    });

    test('session, with the token and without it (cookie)', () {
      for (final token in ['header.payload.signature', null]) {
        final session = SessionDto(
          user: const UserDto(id: 'clan1', name: 'Ana', role: 'member'),
          expiresAt: DateTime.utc(2026, 11, 21, 12),
          token: token,
        );
        final json = overTheWire(session.toJson());
        final back = SessionDto.fromJson(json);
        expect((back.user.id, back.expiresAt, back.token), ('clan1', session.expiresAt, token));
        expect(json.containsKey('token'), token != null);
      }
    });

    test('board game', () {
      const game = BoardGameDto(id: 'catan', title: 'Catan');
      final back = BoardGameDto.fromJson(overTheWire(game.toJson()));
      expect((back.id, back.title), ('catan', 'Catan'));
    });

    test('new loan', () {
      const request = NewLoanDto(gameId: 'catan', durationDays: 3);
      final back = NewLoanDto.fromJson(overTheWire(request.toJson()));
      expect((back.gameId, back.durationDays), ('catan', 3));
    });

    test('loan in every status kind, with and without a copy', () {
      final day = DateTime.utc(2026, 11, 22);
      final statuses = [
        const LoanStatusDto(kind: LoanStatusDto.pending),
        LoanStatusDto(kind: LoanStatusDto.approved, pickupDeadline: day),
        LoanStatusDto(kind: LoanStatusDto.pickedUp, dueAt: day),
        LoanStatusDto(kind: LoanStatusDto.returned, returnedAt: day),
        const LoanStatusDto(kind: LoanStatusDto.rejected),
        const LoanStatusDto(kind: LoanStatusDto.cancelled),
      ];
      for (final status in statuses) {
        for (final copyId in ['catan-1', null]) {
          final loan = loanWith(status, copyId: copyId);
          final back = LoanDto.fromJson(overTheWire(loan.toJson()));
          expect(
            (back.id, back.memberId, back.gameId, back.durationDays, back.requestedAt, back.copyId),
            (loan.id, loan.memberId, loan.gameId, loan.durationDays, loan.requestedAt, copyId),
          );
          expect(
            (back.status.kind, back.status.pickupDeadline, back.status.dueAt, back.status.returnedAt),
            (status.kind, status.pickupDeadline, status.dueAt, status.returnedAt),
          );
        }
      }
    });

    test('the picked-up kind is spelled as in the contract', () {
      final json = overTheWire(LoanStatusDto(kind: LoanStatusDto.pickedUp, dueAt: requestedAt).toJson());
      expect(json, {'kind': 'picked_up', 'dueAt': '2026-11-20T12:00:00.000Z'});
    });

    test('problem with every field', () {
      final problem = ProblemDto(
        status: 409,
        code: ErrorCodes.invalidTransition,
        title: 'Invalid transition',
        value: 8,
        min: 1,
        max: 7,
        from: const LoanStatusDto(kind: LoanStatusDto.rejected),
        to: LoanStatusDto(kind: LoanStatusDto.approved, pickupDeadline: requestedAt),
      );
      final json = overTheWire(problem.toJson());
      final back = ProblemDto.fromJson(json);

      expect(json['type'], ProblemDto.typeOf(ErrorCodes.invalidTransition));
      expect(
        (back.status, back.code, back.title, back.value, back.min, back.max),
        (409, ErrorCodes.invalidTransition, 'Invalid transition', 8, 1, 7),
      );
      expect((back.from?.kind, back.to?.kind, back.to?.pickupDeadline), ('rejected', 'approved', requestedAt));
    });
  });

  test('an older client reads a loan that carries a field it does not know yet', () {
    final fromNewerServer = {
      ...overTheWire(loanWith(const LoanStatusDto(kind: LoanStatusDto.pending)).toJson()),
      'extendedTwice': false,
    };

    final loan = LoanDto.fromJson(fromNewerServer);

    expect((loan.id, loan.durationDays), ('loan-1', 5));
  });

  test('a missing required field is rejected', () {
    final json = overTheWire(loanWith(const LoanStatusDto(kind: LoanStatusDto.pending)).toJson());

    expect(() => LoanDto.fromJson({...json}..remove('requestedAt')), throwsFormatException);
    expect(() => LoanDto.fromJson({...json, 'durationDays': '5'}), throwsFormatException);
  });

  group('time on the wire', () {
    final json = overTheWire(loanWith(const LoanStatusDto(kind: LoanStatusDto.pending)).toJson());

    test('a time without a zone is rejected', () {
      expect(() => LoanDto.fromJson({...json, 'requestedAt': '2026-11-20T12:00:00'}), throwsFormatException);
      expect(
        () => LoanStatusDto.fromJson({'kind': 'picked_up', 'dueAt': '2026-11-27T12:00:00'}),
        throwsFormatException,
      );
    });

    test('a time with an offset is the same instant in UTC', () {
      final loan = LoanDto.fromJson({...json, 'requestedAt': '2026-11-20T13:00:00+01:00'});

      expect(loan.requestedAt, requestedAt);
      expect(loan.requestedAt.isUtc, isTrue);
    });

    test('a local time is sent in UTC', () {
      final local = LoanStatusDto(kind: LoanStatusDto.pickedUp, dueAt: requestedAt.toLocal());

      expect(local.toJson()['dueAt'], '2026-11-20T12:00:00.000Z');
    });
  });

  test('paths follow the contract table', () {
    expect(ApiPaths.cancellation('loan-1'), '/api/v1/loans/loan-1/cancellation');
    expect(ApiPaths.approval('loan-1'), '/api/v1/desk/loans/loan-1/approval');
    expect(ApiPaths.rejection('loan-1'), '/api/v1/desk/loans/loan-1/rejection');
    expect(ApiPaths.myLoans, '/api/v1/me/loans');
    expect(ApiCookies.session, 'bgb_session');
  });
}
