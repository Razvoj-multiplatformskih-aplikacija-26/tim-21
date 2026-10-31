import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  const first = GameCopy(id: GameCopyId('catan-1'), gameId: catan);
  const second = GameCopy(id: GameCopyId('catan-2'), gameId: catan);
  const otherGame = GameCopy(id: GameCopyId('azul-1'), gameId: azul);

  List<GameCopy> free(List<GameCopy> copies, List<Loan> loans) =>
      freeCopiesOf(game: catan, copies: copies, loans: loans);

  test('without loans every usable copy of the game is free', () {
    expect(free([first, second, otherGame], []), [first, second]);
  });

  test('approved, picked up and overdue loans hold their copy', () {
    final holding = [Approved(pickupDeadline: wednesday), PickedUp(dueAt: wednesday), Overdue(dueAt: wednesday)];

    for (final status in holding) {
      expect(free([first, second], [loanOf(ana, status: status, copy: first.id)]), [second], reason: '$status');
    }
  });

  test('a pending loan holds no copy', () {
    expect(free([first], [loanOf(ana)]), [first]);
  });

  test('a returned loan releases its copy', () {
    final returned = loanOf(
      ana,
      status: Returned(returnedAt: wednesday),
      copy: first.id,
    );

    expect(free([first], [returned]), [first]);
  });

  test('copies in inspection or damaged are not free', () {
    const inspected = GameCopy(id: GameCopyId('catan-3'), gameId: catan, condition: CopyCondition.inInspection);
    const damaged = GameCopy(id: GameCopyId('catan-4'), gameId: catan, condition: CopyCondition.damaged);

    expect(free([first, inspected, damaged], []), [first]);
  });
}
