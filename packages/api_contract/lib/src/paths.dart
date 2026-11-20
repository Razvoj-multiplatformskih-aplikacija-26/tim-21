abstract final class ApiPaths {
  static const health = '/health';
  static const sessions = '/api/v1/sessions';
  static const currentSession = '/api/v1/sessions/current';
  static const games = '/api/v1/games';
  static const myLoans = '/api/v1/me/loans';
  static const loans = '/api/v1/loans';
  static const deskLoans = '/api/v1/desk/loans';

  static String loan(String id) => '$loans/$id';

  static String cancellation(String id) => '${loan(id)}/cancellation';

  static String deskLoan(String id) => '$deskLoans/$id';

  static String approval(String id) => '${deskLoan(id)}/approval';

  static String rejection(String id) => '${deskLoan(id)}/rejection';
}

abstract final class ApiCookies {
  static const session = 'bgb_session';
}
