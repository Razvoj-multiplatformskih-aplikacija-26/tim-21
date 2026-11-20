import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:relic/relic.dart' hide Result;

import 'http.dart';
import 'postgres_loans.dart';
import 'sessions.dart';

final class LoanHandlers {
  const LoanHandlers({required this.loans});

  final PostgresLoans loans;

  Future<Response> games(Request request) async =>
      json(200, [for (final game in await loans.games()) game.toDto().toJson()]);

  Future<Response> myLoans(Request request) async {
    final actor = _actor(request);
    final mine = await loans.loansOf(MemberId(actor.id.value));
    return json(200, [
      for (final loan in mine)
        if (AccessPolicy.canView(actor, loan)) loan.toDto().toJson(),
    ]);
  }

  Future<Response> request(Request request) async {
    final actor = _actor(request);
    if (!AccessPolicy.canRequest(actor)) return problem(const NotAllowed());
    final body = NewLoanDto.fromJson(await readObject(request));
    final game = BoardGameId(body.gameId);
    if (!(await loans.games()).any((known) => known.id == game)) throw FormatException('Unknown game', body.gameId);
    final duration = LoanDuration.parse(body.durationDays);
    if (duration case Failure(:final error)) return problem(error);
    final created = await loans.request(member: MemberId(actor.id.value), game: game, duration: duration.valueOrNull!);
    return respond(created, status: 201);
  }

  Future<Response> cancel(Request request) => _change(request, allowed: AccessPolicy.canCancel, change: loans.cancel);

  Future<Response> desk(Request request) async {
    final actor = _actor(request);
    if (!AccessPolicy.canDecide(actor)) return problem(const NotAllowed());
    return json(200, [
      for (final loan in await loans.allLoans())
        if (AccessPolicy.canView(actor, loan)) loan.toDto().toJson(),
    ]);
  }

  Future<Response> approve(Request request) =>
      _change(request, allowed: (actor, _) => AccessPolicy.canDecide(actor), change: loans.approve);

  Future<Response> reject(Request request) =>
      _change(request, allowed: (actor, _) => AccessPolicy.canDecide(actor), change: loans.reject);

  Future<Response> _change(
    Request request, {
    required bool Function(User actor, Loan loan) allowed,
    required Future<Result<Loan>> Function(LoanId id) change,
  }) async {
    final actor = _actor(request);
    final id = LoanId(request.rawPathParameters[#id]!);
    final loan = await loans.find(id);
    if (loan == null || !AccessPolicy.canView(actor, loan)) return problem(const LoanNotFound());
    if (!allowed(actor, loan)) return problem(const NotAllowed());
    return respond(await change(id));
  }

  User _actor(Request request) => currentSession.get(request).user;
}
