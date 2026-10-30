import 'package:domain/domain.dart';

const ana = MemberId('ana');
const marko = MemberId('marko');
const catan = BoardGameId('catan');
const azul = BoardGameId('azul');

final monday = DateTime.utc(2026, 11, 2, 12);
final wednesday = DateTime.utc(2026, 11, 4, 12);

Loan loanOf(MemberId member, {LoanStatus status = const Pending(), BoardGameId game = catan, GameCopyId? copy}) => Loan(
  id: LoanId('loan-${member.value}'),
  memberId: member,
  gameId: game,
  duration: LoanDuration.parse(7).valueOrNull!,
  requestedAt: monday,
  status: status,
  copyId: copy,
);
