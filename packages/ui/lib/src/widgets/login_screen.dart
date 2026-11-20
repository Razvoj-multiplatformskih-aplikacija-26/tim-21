import 'package:blocs/blocs.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:use_cases/use_cases.dart' show SessionRepository;

import '../text/failures.dart';
import '../text/sign_out_messages.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.title,
    required this.sessions,
    required this.onSignedIn,
    required this.onRetry,
    required this.roleNotAllowedMessage,
    this.reason,
  });

  final String title;
  final SessionRepository sessions;
  final void Function(User user) onSignedIn;
  final VoidCallback onRetry;
  final String roleNotAllowedMessage;
  final SignOutReason? reason;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginFormBloc(sessions: sessions),
      child: BlocListener<LoginFormBloc, LoginFormState>(
        listener: (context, state) {
          if (state case LoginSucceeded(:final user)) onSignedIn(user);
        },
        child: Scaffold(
          body: _LoginForm(
            title: title,
            reason: reason,
            roleNotAllowedMessage: roleNotAllowedMessage,
            onRetry: onRetry,
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({required this.title, required this.roleNotAllowedMessage, required this.onRetry, this.reason});

  final String title;
  final String roleNotAllowedMessage;
  final VoidCallback onRetry;
  final SignOutReason? reason;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() =>
      context.read<LoginFormBloc>().add(LoginSubmitted(username: _username.text, password: _password.text));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<LoginFormBloc>().state;
    final busy = state is LoginSubmitting;
    final message = switch (state) {
      LoginRejected() => 'Pogrešno korisničko ime ili lozinka.',
      LoginFailed(:final cause) => failureMessage(cause),
      _ => signOutMessage(widget.reason, roleNotAllowed: widget.roleNotAllowedMessage),
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.casino_outlined, size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: Spacing.lg),
                Semantics(
                  header: true,
                  child: Text(widget.title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                ),
                const SizedBox(height: Spacing.xxl),
                if (message != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      message,
                      style: TextStyle(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                ],
                if (widget.reason == SignOutReason.unreachable) ...[
                  OutlinedButton.icon(
                    onPressed: busy ? null : widget.onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Pokušaj ponovo'),
                  ),
                  const SizedBox(height: Spacing.lg),
                ],
                TextField(
                  controller: _username,
                  enabled: !busy,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Korisničko ime'),
                ),
                const SizedBox(height: Spacing.md),
                TextField(
                  controller: _password,
                  enabled: !busy,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(labelText: 'Lozinka'),
                ),
                const SizedBox(height: Spacing.xxl),
                FilledButton(
                  onPressed: busy ? null : _submit,
                  child: busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Prijava u toku'),
                        )
                      : const Text('Prijavi se'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
