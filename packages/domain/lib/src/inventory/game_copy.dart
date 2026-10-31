import 'package:meta/meta.dart';

import '../identifiers.dart';

enum CopyCondition { usable, inInspection, damaged }

@immutable
final class GameCopy {
  const GameCopy({required this.id, required this.gameId, this.condition = CopyCondition.usable});

  final GameCopyId id;
  final BoardGameId gameId;
  final CopyCondition condition;

  @override
  bool operator ==(Object other) =>
      other is GameCopy && other.id == id && other.gameId == gameId && other.condition == condition;

  @override
  int get hashCode => Object.hash(id, gameId, condition);

  @override
  String toString() => 'GameCopy($id, game $gameId, ${condition.name})';
}
