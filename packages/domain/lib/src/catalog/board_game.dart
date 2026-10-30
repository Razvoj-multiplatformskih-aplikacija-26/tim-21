import 'package:meta/meta.dart';

import '../identifiers.dart';

@immutable
final class BoardGame {
  const BoardGame({required this.id, required this.title});

  final BoardGameId id;
  final String title;

  @override
  bool operator ==(Object other) => other is BoardGame && other.id == id && other.title == title;

  @override
  int get hashCode => Object.hash(id, title);

  @override
  String toString() => 'BoardGame($id, $title)';
}
