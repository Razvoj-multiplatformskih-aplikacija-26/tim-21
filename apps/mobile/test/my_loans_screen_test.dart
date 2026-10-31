import 'dart:async';

import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/dependencies.dart';
import 'package:mobile/screens/my_loans_screen.dart';
import 'package:use_cases/use_cases.dart';

const _member = MemberId('ana');
const _catan = BoardGame(id: BoardGameId('catan'), title: 'Catan');

final class _StubRepository implements LoanRepository {
  _StubRepository(this.loans);

  List<Loan> loans;
  int failingRequests = 0;
  Completer<void>? gate;

  @override
  Future<List<Loan>> loansOf(MemberId member) async {
    await gate?.future;
    if (failingRequests > 0) {
      failingRequests--;
      throw const RepositoryException('Simulated outage');
    }
    return loans;
  }

  @override
  Future<List<BoardGame>> games() async => const [_catan];

  @override
  Future<Result<Loan>> cancel(LoanId id) async {
    final result = changeLoanStatus(loans.single, const Cancelled());
    if (result case Success(:final value)) loans = [value];
    return result;
  }
}

Loan _pendingLoan() => Loan(
  id: const LoanId('l-1'),
  memberId: _member,
  gameId: _catan.id,
  duration: LoanDuration.parse(7).valueOrNull!,
  requestedAt: DateTime.utc(2026, 11, 2),
);

Widget _screenOver(LoanRepository repository) => RepositoryProvider.value(
  value: AppDependencies(loans: repository, clock: const SystemClock(), member: _member),
  child: BlocProvider(
    create: (_) =>
        MyLoansBloc(repository: repository, clock: const SystemClock(), member: _member)..add(const MyLoansRequested()),
    child: const MaterialApp(home: MyLoansScreen()),
  ),
);

void main() {
  testWidgets('shows progress while loading', (tester) async {
    final repository = _StubRepository([_pendingLoan()])..gate = Completer();
    await tester.pumpWidget(_screenOver(repository));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.gate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('shows the failure and recovers through the retry button', (tester) async {
    final repository = _StubRepository([_pendingLoan()])..failingRequests = 1;
    await tester.pumpWidget(_screenOver(repository));
    await tester.pumpAndSettle();

    expect(find.text('Podaci trenutno nisu dostupni.'), findsOneWidget);

    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pumpAndSettle();

    expect(find.text('Catan'), findsOneWidget);
  });

  testWidgets('shows the empty view', (tester) async {
    await tester.pumpWidget(_screenOver(_StubRepository([])));
    await tester.pumpAndSettle();

    expect(find.text('Nemate pozajmica.'), findsOneWidget);
  });

  testWidgets('cancels a loan only after the dialog is confirmed', (tester) async {
    await tester.pumpWidget(_screenOver(_StubRepository([_pendingLoan()])));
    await tester.pumpAndSettle();

    expect(find.text('Na čekanju'), findsOneWidget);

    await tester.tap(find.text('Otkaži'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Odustani'));
    await tester.pumpAndSettle();

    expect(find.text('Na čekanju'), findsOneWidget);

    await tester.tap(find.text('Otkaži'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otkaži pozajmicu'));
    await tester.pumpAndSettle();

    expect(find.text('Otkazana'), findsOneWidget);
    expect(find.text('Pozajmica je otkazana.'), findsOneWidget);
    expect(find.text('Otkaži'), findsNothing);
  });

  testWidgets('hides the simulation menu when the port is not the fake', (tester) async {
    await tester.pumpWidget(_screenOver(_StubRepository([])));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Simulacija'), findsNothing);
  });
}
