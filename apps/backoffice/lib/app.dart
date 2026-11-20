import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import 'dependencies.dart';
import 'screens/loan_board_screen.dart';

const _title = 'BoardGame Booking · Backoffice';

class BackofficeApp extends StatefulWidget {
  const BackofficeApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<BackofficeApp> createState() => _BackofficeAppState();
}

class _BackofficeAppState extends State<BackofficeApp> {
  late final SessionBloc _session = SessionBloc(
    sessions: widget.dependencies.sessions,
    admits: AccessPolicy.canUseBackoffice,
    expirations: widget.dependencies.sessions.expirations,
  )..add(const SessionRestoreRequested());

  @override
  void dispose() {
    _session.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;
    return RepositoryProvider.value(
      value: dependencies,
      child: BlocProvider.value(
        value: _session,
        child: BlocBuilder<SessionBloc, SessionState>(
          builder: (context, session) => switch (session) {
            SessionUnknown() => _material(
              key: const ValueKey('session-unknown'),
              home: const Scaffold(body: LoadingView()),
            ),
            SignedOut(:final reason) => _material(
              key: ValueKey('signed-out ${reason?.name}'),
              home: LoginScreen(
                title: _title,
                sessions: dependencies.sessions,
                reason: reason,
                roleNotAllowedMessage: backofficeRoleNotAllowedMessage,
                onSignedIn: (user) => _session.add(SessionStarted(user)),
                onRetry: () => _session.add(const SessionRestoreRequested()),
              ),
            ),
            SignedIn(:final user) => BlocProvider(
              key: ValueKey(user.id),
              create: (_) =>
                  LoanBoardBloc(repository: dependencies.loans, clock: dependencies.clock)
                    ..add(const LoanBoardRequested()),
              child: _material(key: ValueKey('signed-in ${user.id.value}'), home: const LoanBoardScreen()),
            ),
          },
        ),
      ),
    );
  }
}

Widget _material({required Key key, required Widget home}) =>
    MaterialApp(key: key, title: _title, theme: BoardGameTheme.light(), darkTheme: BoardGameTheme.dark(), home: home);
