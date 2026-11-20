import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

const _member = User(id: UserId('clan1'), name: 'Ana Petrović', role: Role.member);
const _librarian = User(id: UserId('bibliotekar1'), name: 'Marko Jovanović', role: Role.librarian);
const _outage = RepositoryException('Simulated outage', failure: RepositoryFailure.unreachable);

final class _Sessions implements SessionRepository {
  _Sessions(this.remembered);

  User? remembered;
  bool unreachable = false;
  int logOuts = 0;
  final _expirations = StreamController<void>.broadcast();

  void expire() => _expirations.add(null);

  @override
  Future<User?> logIn({required String username, required String password}) async => null;

  @override
  Future<User?> current() async {
    if (unreachable) throw _outage;
    return remembered;
  }

  @override
  Future<void> logOut() async {
    logOuts++;
    if (unreachable) throw _outage;
    remembered = null;
  }

  @override
  Stream<void> get expirations => _expirations.stream;
}

void main() {
  late _Sessions sessions;

  SessionBloc mobileSession() =>
      SessionBloc(sessions: sessions, admits: AccessPolicy.canUseMobile, expirations: sessions.expirations);

  group('restoring a saved login', () {
    blocTest<SessionBloc, SessionState>(
      'a remembered member survives a restart and ends with a reason when the server says it expired',
      setUp: () => sessions = _Sessions(_member),
      build: mobileSession,
      act: (bloc) async {
        bloc.add(const SessionRestoreRequested());
        await Future<void>.delayed(Duration.zero);
        sessions.expire();
      },
      expect: () => [const SignedIn(_member), const SignedOut(reason: SignOutReason.expired)],
    );

    blocTest<SessionBloc, SessionState>(
      'without a saved login the app asks for one and gives no reason',
      setUp: () => sessions = _Sessions(null),
      build: mobileSession,
      act: (bloc) => bloc.add(const SessionRestoreRequested()),
      expect: () => [const SignedOut()],
    );

    blocTest<SessionBloc, SessionState>(
      'an unreachable server signs out with that reason',
      setUp: () => sessions = _Sessions(_member)..unreachable = true,
      build: mobileSession,
      act: (bloc) => bloc.add(const SessionRestoreRequested()),
      expect: () => [const SignedOut(reason: SignOutReason.unreachable)],
    );

    blocTest<SessionBloc, SessionState>(
      'a retry after an outage restores the saved login without a password once the server is back',
      setUp: () => sessions = _Sessions(_member),
      build: mobileSession,
      seed: () => const SignedOut(reason: SignOutReason.unreachable),
      act: (bloc) => bloc.add(const SessionRestoreRequested()),
      expect: () => [const SessionUnknown(), const SignedIn(_member)],
    );

    blocTest<SessionBloc, SessionState>(
      'a retry while the server is still down shows the outage again',
      setUp: () => sessions = _Sessions(_member)..unreachable = true,
      build: mobileSession,
      seed: () => const SignedOut(reason: SignOutReason.unreachable),
      act: (bloc) => bloc.add(const SessionRestoreRequested()),
      expect: () => [const SessionUnknown(), const SignedOut(reason: SignOutReason.unreachable)],
    );
  });

  group('the role the app admits', () {
    blocTest<SessionBloc, SessionState>(
      'a librarian is not let into the mobile app and the server session is closed',
      setUp: () => sessions = _Sessions(_librarian),
      build: mobileSession,
      act: (bloc) => bloc.add(const SessionRestoreRequested()),
      expect: () => [const SignedOut(reason: SignOutReason.roleNotAllowed)],
      verify: (_) => expect(sessions.logOuts, 1),
    );

    blocTest<SessionBloc, SessionState>(
      'a member is not let into the backoffice',
      setUp: () => sessions = _Sessions(null),
      build: () =>
          SessionBloc(sessions: sessions, admits: AccessPolicy.canUseBackoffice, expirations: sessions.expirations),
      act: (bloc) => bloc.add(const SessionStarted(_member)),
      expect: () => [const SignedOut(reason: SignOutReason.roleNotAllowed)],
      verify: (_) => expect(sessions.logOuts, 1),
    );

    blocTest<SessionBloc, SessionState>(
      'a librarian is let into the backoffice',
      setUp: () => sessions = _Sessions(null),
      build: () =>
          SessionBloc(sessions: sessions, admits: AccessPolicy.canUseBackoffice, expirations: sessions.expirations),
      act: (bloc) => bloc.add(const SessionStarted(_librarian)),
      expect: () => [const SignedIn(_librarian)],
    );
  });

  group('logging out', () {
    blocTest<SessionBloc, SessionState>(
      'a fresh login signs in and logging out closes the server session',
      setUp: () => sessions = _Sessions(null),
      build: mobileSession,
      act: (bloc) async {
        bloc.add(const SessionStarted(_member));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SessionLogOutRequested());
      },
      expect: () => [const SignedIn(_member), const SignedOut(reason: SignOutReason.loggedOut)],
      verify: (_) => expect(sessions.logOuts, 1),
    );

    blocTest<SessionBloc, SessionState>(
      'logging out still signs out on the device when the server cannot be reached',
      setUp: () => sessions = _Sessions(null),
      build: mobileSession,
      seed: () => const SignedIn(_member),
      act: (bloc) {
        sessions.unreachable = true;
        bloc.add(const SessionLogOutRequested());
      },
      expect: () => [const SignedOut(reason: SignOutReason.loggedOut)],
      errors: () => [_outage],
    );

    blocTest<SessionBloc, SessionState>(
      'an expiration while nobody is signed in changes nothing',
      setUp: () => sessions = _Sessions(null),
      build: mobileSession,
      seed: () => const SignedOut(reason: SignOutReason.loggedOut),
      act: (_) => sessions.expire(),
      expect: () => const <SessionState>[],
    );
  });
}
