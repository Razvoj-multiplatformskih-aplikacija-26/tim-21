import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

class BoardGameApp extends StatelessWidget {
  const BoardGameApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BoardGame Booking',
    theme: BoardGameTheme.light(),
    darkTheme: BoardGameTheme.dark(),
    home: const Scaffold(body: Center(child: Text('BoardGame Booking'))),
  );
}
