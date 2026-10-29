import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

class BackofficeApp extends StatelessWidget {
  const BackofficeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BoardGame Booking · Backoffice',
    theme: BoardGameTheme.light(),
    darkTheme: BoardGameTheme.dark(),
    home: const Scaffold(body: Center(child: Text('BoardGame Booking · Backoffice'))),
  );
}
