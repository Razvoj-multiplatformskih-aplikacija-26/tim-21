import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

const _member = User(id: UserId('clan1'), name: 'Ana Petrović', role: Role.member);
const _outage = RepositoryException('Simulated outage', failure: RepositoryFailure.unreachable);

final class _Sessions implements SessionRepository {
  bool unreachable = false;
  final usernames = <String>[];

  @override
  Future<User?> logIn({required String username, required String password}) async {
    usernames.add(username);
    if (unreachable) throw _outage;
    return username == 'clan1' && password == 'demo' ? _member : null;
  }

  @override
  Future<User?> current() async => null;

  @override
  Future<void> logOut() async {}

  @override
  Stream<void> get expirations => const Stream.empty();
}

void main() {
  late _Sessions sessions;

  setUp(() => sessions = _Sessions());

  blocTest<LoginFormBloc, LoginFormState>(
    'correct credentials sign the user in and surrounding spaces in the username are ignored',
    build: () => LoginFormBloc(sessions: sessions),
    act: (bloc) => bloc.add(const LoginSubmitted(username: '  clan1 ', password: 'demo')),
    expect: () => [const LoginSubmitting(), const LoginSucceeded(_member)],
    verify: (_) => expect(sessions.usernames, ['clan1']),
  );

  blocTest<LoginFormBloc, LoginFormState>(
    'wrong credentials are rejected',
    build: () => LoginFormBloc(sessions: sessions),
    act: (bloc) => bloc.add(const LoginSubmitted(username: 'clan1', password: 'pogresna')),
    expect: () => [const LoginSubmitting(), const LoginRejected()],
  );

  blocTest<LoginFormBloc, LoginFormState>(
    'an unreachable server is a failure, not a rejection',
    build: () => LoginFormBloc(sessions: sessions..unreachable = true),
    act: (bloc) => bloc.add(const LoginSubmitted(username: 'clan1', password: 'demo')),
    expect: () => [const LoginSubmitting(), const LoginFailed(_outage)],
  );
}
