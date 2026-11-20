import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

extension BoardGameMapping on BoardGame {
  BoardGameDto toDto() => BoardGameDto(id: id.value, title: title);
}

extension BoardGameDtoMapping on BoardGameDto {
  BoardGame toDomain() => BoardGame(id: BoardGameId(id), title: title);
}
