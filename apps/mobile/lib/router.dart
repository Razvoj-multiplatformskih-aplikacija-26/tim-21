import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'screens/loan_detail_screen.dart';
import 'screens/loan_request_screen.dart';
import 'screens/my_loans_screen.dart';
import 'screens/sign_in_screen.dart';

GoRouter createRouter() => GoRouter(
  redirect: (context, state) {
    final signedIn = context.read<SessionBloc>().state is SignedIn;
    final atLogin = state.matchedLocation == '/login';
    if (!signedIn) return atLogin ? null : '/login';
    return atLogin ? '/' : null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const SignInScreen()),
    GoRoute(
      path: '/',
      builder: (context, state) => const MyLoansScreen(),
      routes: [
        GoRoute(
          path: 'pozajmice/:id',
          builder: (context, state) => LoanDetailScreen(id: LoanId(state.pathParameters['id']!)),
          routes: [
            GoRoute(
              path: 'nova',
              builder: (context, state) => LoanRequestScreen(id: LoanId(state.pathParameters['id']!)),
            ),
          ],
        ),
      ],
    ),
  ],
);
