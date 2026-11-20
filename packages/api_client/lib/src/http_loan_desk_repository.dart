import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'api_client.dart';

final class HttpLoanDeskRepository implements LoanDeskRepository {
  const HttpLoanDeskRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Loan>> allLoans() async {
    final answer = await _api.get(ApiPaths.deskLoans);
    return accepted(answer, (json) => [for (final item in jsonObjects(json)) LoanDto.fromJson(item).toDomain()]);
  }

  @override
  Future<List<BoardGame>> games() async {
    final answer = await _api.get(ApiPaths.games);
    return accepted(answer, (json) => [for (final item in jsonObjects(json)) BoardGameDto.fromJson(item).toDomain()]);
  }

  @override
  Future<Result<Loan>> approve(LoanId id) async => resultOf(await _api.post(ApiPaths.approval(id.value)), _loan);

  @override
  Future<Result<Loan>> reject(LoanId id) async => resultOf(await _api.post(ApiPaths.rejection(id.value)), _loan);

  Loan _loan(Object? json) => LoanDto.fromJson(jsonObject(json)).toDomain();
}
