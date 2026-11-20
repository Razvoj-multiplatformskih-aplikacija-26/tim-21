import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';

import 'cors.dart';
import 'handlers.dart';
import 'http.dart';
import 'sessions.dart';

Handler buildHandler(LoanHandlers handlers, SessionHandlers sessions, {required List<String> corsOrigins}) {
  final signedIn = sessions.signedIn;
  final router = RelicRouter()
    ..get(ApiPaths.health, (request) => Response.ok(body: Body.fromString('ok')))
    ..post(ApiPaths.sessions, sessions.logIn)
    ..get(ApiPaths.currentSession, signedIn(sessions.current))
    ..delete(ApiPaths.currentSession, signedIn(sessions.logOut))
    ..get(ApiPaths.games, signedIn(handlers.games))
    ..get(ApiPaths.myLoans, signedIn(handlers.myLoans))
    ..post(ApiPaths.loans, signedIn(handlers.request))
    ..post(ApiPaths.cancellation(':id'), signedIn(handlers.cancel))
    ..get(ApiPaths.deskLoans, signedIn(handlers.desk))
    ..post(ApiPaths.approval(':id'), signedIn(handlers.approve))
    ..post(ApiPaths.rejection(':id'), signedIn(handlers.reject))
    ..fallback = respondWith((request) => problemResponse(notFoundRoute));
  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(allowOrigins(corsOrigins))
      .addMiddleware(handleErrors())
      .addHandler(router.asHandler);
}

const notFoundRoute = ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'No such route');
