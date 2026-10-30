import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import 'dependencies.dart';
import 'screens/my_loans_screen.dart';

class BoardGameApp extends StatelessWidget {
  const BoardGameApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) => RepositoryProvider.value(
    value: dependencies,
    child: BlocProvider(
      create: (_) =>
          MyLoansBloc(repository: dependencies.loans, clock: dependencies.clock, member: dependencies.member)
            ..add(const MyLoansRequested()),
      child: MaterialApp(
        title: 'BoardGame Booking',
        theme: BoardGameTheme.light(),
        darkTheme: BoardGameTheme.dark(),
        home: const MyLoansScreen(),
      ),
    ),
  );
}
