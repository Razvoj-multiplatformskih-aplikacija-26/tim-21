import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

extension UserMapping on User {
  UserDto toDto() => UserDto(id: id.value, name: name, role: role.name);
}

extension UserDtoMapping on UserDto {
  User toDomain() => User(
    id: UserId(id),
    name: name,
    role: Role.values.asNameMap()[role] ?? (throw FormatException('Unknown role', role)),
  );
}
