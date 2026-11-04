import 'package:domain/domain.dart';
import 'package:go_router/go_router.dart';

import 'screens/loan_detail_screen.dart';
import 'screens/loan_request_screen.dart';
import 'screens/my_loans_screen.dart';

final router = GoRouter(
  routes: [
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
