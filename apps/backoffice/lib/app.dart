import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import 'dependencies.dart';
import 'screens/loan_board_screen.dart';

class BackofficeApp extends StatelessWidget {
  const BackofficeApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) => RepositoryProvider.value(
    value: dependencies,
    child: BlocProvider(
      create: (_) =>
          LoanBoardBloc(repository: dependencies.loans, clock: dependencies.clock)..add(const LoanBoardRequested()),
      child: MaterialApp(
        title: 'BoardGame Booking · Backoffice',
        theme: BoardGameTheme.light(),
        darkTheme: BoardGameTheme.dark(),
        home: const LoanBoardScreen(),
      ),
    ),
  );
}
