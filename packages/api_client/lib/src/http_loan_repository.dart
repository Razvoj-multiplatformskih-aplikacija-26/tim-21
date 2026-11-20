import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'api_client.dart';

final class HttpLoanRepository implements LoanRepository {
  const HttpLoanRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Loan>> loansOf(MemberId member) async {
    final answer = await _api.get(ApiPaths.myLoans);
    return accepted(answer, (json) => [for (final item in jsonObjects(json)) LoanDto.fromJson(item).toDomain()]);
  }

  @override
  Future<List<BoardGame>> games() async {
    final answer = await _api.get(ApiPaths.games);
    return accepted(answer, (json) => [for (final item in jsonObjects(json)) BoardGameDto.fromJson(item).toDomain()]);
  }

  @override
  Future<Result<Loan>> cancel(LoanId id) async => resultOf(await _api.post(ApiPaths.cancellation(id.value)), _loan);

  @override
  Future<Result<Loan>> request({
    required MemberId member,
    required BoardGameId game,
    required LoanDuration duration,
  }) async {
    final body = NewLoanDto(gameId: game.value, durationDays: duration.days);
    return resultOf(await _api.post(ApiPaths.loans, body: body.toJson()), _loan);
  }

  Loan _loan(Object? json) => LoanDto.fromJson(jsonObject(json)).toDomain();
}
