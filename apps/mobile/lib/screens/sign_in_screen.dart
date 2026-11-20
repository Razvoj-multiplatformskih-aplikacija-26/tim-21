import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../dependencies.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<SessionBloc, SessionState>(
    builder: (context, session) => switch (session) {
      SessionUnknown() || SignedIn() => const Scaffold(body: LoadingView()),
      SignedOut(:final reason) => LoginScreen(
        key: ValueKey(reason),
        title: 'BoardGame Booking',
        sessions: context.read<AppDependencies>().sessions,
        reason: reason,
        roleNotAllowedMessage: mobileRoleNotAllowedMessage,
        onSignedIn: (user) => context.read<SessionBloc>().add(SessionStarted(user)),
        onRetry: () => context.read<SessionBloc>().add(const SessionRestoreRequested()),
      ),
    },
  );
}
