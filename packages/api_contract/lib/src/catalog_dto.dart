import 'json.dart';

final class BoardGameDto {
  const BoardGameDto({required this.id, required this.title});

  final String id;
  final String title;

  Map<String, Object?> toJson() => {'id': id, 'title': title};

  factory BoardGameDto.fromJson(Map<String, Object?> json) =>
      BoardGameDto(id: jsonString(json, 'id'), title: jsonString(json, 'title'));
}
