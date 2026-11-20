import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import 'dependencies.dart';
import 'router.dart';

class BoardGameApp extends StatefulWidget {
  const BoardGameApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<BoardGameApp> createState() => _BoardGameAppState();
}

class _BoardGameAppState extends State<BoardGameApp> {
  late final SessionBloc _session = SessionBloc(
    sessions: widget.dependencies.sessions,
    admits: AccessPolicy.canUseMobile,
    expirations: widget.dependencies.sessions.expirations,
  )..add(const SessionRestoreRequested());
  late final MyLoansBloc _loans = MyLoansBloc(repository: widget.dependencies.loans, clock: widget.dependencies.clock);
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    _loans.close();
    _session.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepositoryProvider.value(
    value: widget.dependencies,
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _session),
        BlocProvider.value(value: _loans),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<SessionBloc, SessionState>(
            listenWhen: (previous, current) => current is! SessionUnknown,
            listener: (context, session) => _loans.add(
              MyLoansMemberChanged(switch (session) {
                SignedIn(:final user) => user,
                _ => null,
              }),
            ),
          ),
          BlocListener<SessionBloc, SessionState>(listener: (context, session) => _router.refresh()),
        ],
        child: MaterialApp.router(
          title: 'BoardGame Booking',
          theme: BoardGameTheme.light(),
          darkTheme: BoardGameTheme.dark(),
          routerConfig: _router,
        ),
      ),
    ),
  );
}
