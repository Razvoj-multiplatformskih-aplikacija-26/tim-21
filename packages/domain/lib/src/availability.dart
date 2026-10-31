import 'identifiers.dart';
import 'inventory/game_copy.dart';
import 'loan/loan.dart';

List<GameCopy> freeCopiesOf({required BoardGameId game, required List<GameCopy> copies, required List<Loan> loans}) {
  final held = {
    for (final loan in loans)
      if (loan.status.isActive && loan.copyId != null) loan.copyId,
  };
  return [
    for (final copy in copies)
      if (copy.gameId == game && copy.condition == CopyCondition.usable && !held.contains(copy.id)) copy,
  ];
}
