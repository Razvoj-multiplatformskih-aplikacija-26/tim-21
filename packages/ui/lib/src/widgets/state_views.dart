import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(label: 'Učitavanje', liveRegion: true, child: const CircularProgressIndicator()),
  );
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Spacing.xxxl),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
    ),
  );
}

class FailureView extends StatelessWidget {
  const FailureView({super.key, required this.onRetry, this.title = 'Podaci trenutno nisu dostupni.'});

  final VoidCallback onRetry;
  final String title;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Spacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          ),
          const SizedBox(height: Spacing.lg),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Pokušaj ponovo'),
          ),
        ],
      ),
    ),
  );
}
