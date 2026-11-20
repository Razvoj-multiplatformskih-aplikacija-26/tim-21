import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:relic/relic.dart' hide Result;

final _problemMimeType = MimeType.parse(ProblemDto.mediaType);

Response json(int status, Object? body) =>
    Response(status, body: Body.fromString(jsonEncode(body), mimeType: MimeType.json));

Response problem(DomainError error) => problemResponse(error.toProblem());

Response problemResponse(ProblemDto problem) =>
    Response(problem.status, body: Body.fromString(jsonEncode(problem.toJson()), mimeType: _problemMimeType));

Response badRequest(String title) =>
    problemResponse(ProblemDto(status: 400, code: ErrorCodes.badRequest, title: title));

const maxBodyBytes = 16 * 1024;

Future<Map<String, Object?>> readObject(Request request) async {
  if (request.mimeType != MimeType.json) throw const FormatException('Expected application/json');
  return switch (jsonDecode(await request.readAsString(maxLength: maxBodyBytes))) {
    final Map<String, Object?> object => object,
    _ => throw const FormatException('Expected a JSON object'),
  };
}

Response respond(Result<Loan> result, {int status = 200}) => switch (result) {
  Success(:final value) => json(status, value.toDto().toJson()),
  Failure(:final error) => problem(error),
};

Middleware handleErrors() =>
    (Handler next) => (Request request) async {
      try {
        return await next(request);
      } on FormatException catch (error) {
        return badRequest(error.message);
      } on MaxBodySizeExceeded {
        return badRequest('Request body too large');
      } catch (error, stackTrace) {
        stderr.writeln('${request.method} ${request.url.path}: $error\n$stackTrace');
        return problemResponse(serverError);
      }
    };

const serverError = ProblemDto(status: 500, code: ErrorCodes.serverError, title: 'Server error');
