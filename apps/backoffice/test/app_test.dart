import 'package:backoffice/app.dart';
import 'package:backoffice/dependencies.dart';
import 'package:backoffice/screens/loan_board_screen.dart';
import 'package:backoffice/widgets/loan_filter_bar.dart';
import 'package:backoffice/widgets/loan_list.dart';
import 'package:backoffice/widgets/loan_table.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void useWindow(WidgetTester tester, {required double width, required double height}) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpBoard(WidgetTester tester, {required double width, double height = 900}) async {
    useWindow(tester, width: width, height: height);
    await tester.pumpWidget(BackofficeApp(dependencies: AppDependencies.fake(latency: Duration.zero)));
    await tester.pumpAndSettle();
  }

  Future<void> pumpWideBoard(WidgetTester tester) => pumpBoard(tester, width: 1400);

  Future<void> resize(WidgetTester tester, {required double width, double height = 900}) async {
    useWindow(tester, width: width, height: height);
    await tester.pumpAndSettle();
  }

  LoanBoardLoaded boardState(WidgetTester tester) =>
      tester.element(find.byType(LoanBoardScreen)).read<LoanBoardBloc>().state as LoanBoardLoaded;

  bool isSelected(WidgetTester tester, LoanId id) => tester
      .widgetList<Semantics>(find.descendant(of: find.byKey(ValueKey(id)), matching: find.byType(Semantics)))
      .any((semantics) => semantics.properties.selected ?? false);

  ButtonStyleButton buttonWith(WidgetTester tester, String label) => tester.widget<ButtonStyleButton>(
    find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton)),
  );

  testWidgets('backoffice shows the loan table and an empty detail panel', (tester) async {
    await pumpWideBoard(tester);

    expect(find.text('Tabla pozajmica'), findsOneWidget);
    for (final header in ['Igra', 'Član', 'Stanje', 'Rok', 'Zatraženo']) {
      expect(find.descendant(of: find.byType(LoanTable), matching: find.text(header)), findsOneWidget);
    }
    expect(find.text('Izaberite pozajmicu u tabeli.'), findsOneWidget);
  });

  testWidgets('selecting a pending loan enables approval, which shows a notice', (tester) async {
    await pumpWideBoard(tester);

    await tester.tap(find.byKey(const ValueKey(LoanId('desk-1'))));
    await tester.pumpAndSettle();
    expect(find.text('Izaberite pozajmicu u tabeli.'), findsNothing);
    expect(buttonWith(tester, 'Odobri').onPressed, isNotNull);
    expect(buttonWith(tester, 'Odbij').onPressed, isNotNull);

    await tester.tap(find.text('Odobri'));
    await tester.pumpAndSettle();
    expect(find.text('Pozajmica je odobrena.'), findsOneWidget);
    expect(buttonWith(tester, 'Odobri').onPressed, isNull);
    expect(buttonWith(tester, 'Odbij').onPressed, isNull);
    expect(find.text('catan-3'), findsOneWidget);
  });

  testWidgets('the second approval for the only copy of a game is refused', (tester) async {
    await pumpWideBoard(tester);

    await tester.tap(find.byKey(const ValueKey(LoanId('desk-5'))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Odobri'));
    await tester.pumpAndSettle();
    expect(find.text('Pozajmica je odobrena.'), findsOneWidget);
    expect(find.text('splendor-1'), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(LoanBoardScreen))).removeCurrentSnackBar();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey(LoanId('desk-6'))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Odobri'));
    await tester.pumpAndSettle();
    expect(find.text('Nema slobodne kopije ove igre.'), findsOneWidget);
    final second = boardState(tester).items.firstWhere((item) => item.loan.id == const LoanId('desk-6'));
    expect(second.status, const Pending());
    expect(second.loan.copyId, isNull);
  });

  testWidgets('arrow down selects the first loan when nothing is selected', (tester) async {
    await pumpWideBoard(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('Izaberite pozajmicu u tabeli.'), findsNothing);
  });

  testWidgets('O approves the selected pending loan', (tester) async {
    await pumpWideBoard(tester);

    await tester.tap(find.byKey(const ValueKey(LoanId('desk-1'))));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyO);
    await tester.pumpAndSettle();
    expect(find.text('Pozajmica je odobrena.'), findsOneWidget);
  });

  testWidgets('R rejects the selected pending loan', (tester) async {
    await pumpWideBoard(tester);

    await tester.tap(find.byKey(const ValueKey(LoanId('desk-1'))));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.pumpAndSettle();
    expect(find.text('Pozajmica je odbijena.'), findsOneWidget);
  });

  testWidgets('action buttons name their shortcut in a tooltip', (tester) async {
    await pumpWideBoard(tester);

    await tester.tap(find.byKey(const ValueKey(LoanId('desk-1'))));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Odobri (O)'), findsOneWidget);
    expect(find.byTooltip('Odbij (R)'), findsOneWidget);
  });

  Future<void> simulate(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> refresh(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Osveži'));
    await tester.pumpAndSettle();
  }

  testWidgets('simulated failure shows retry and recovers', (tester) async {
    await pumpWideBoard(tester);

    await simulate(tester, 'Simuliraj grešku');
    expect(find.text('Sledeći zahtev neće uspeti.'), findsOneWidget);
    expect(find.byType(LoanTable), findsOneWidget);

    await refresh(tester);
    expect(find.text('Pokušaj ponovo'), findsOneWidget);

    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pumpAndSettle();
    expect(find.text('Zatraženo'), findsOneWidget);
  });

  Border? focusFrameBorder(WidgetTester tester, Key key) =>
      (tester.widget<DecoratedBox>(find.byKey(key)).decoration as BoxDecoration).border as Border?;

  Color primaryOf(WidgetTester tester) => Theme.of(tester.element(find.byType(LoanBoardScreen))).colorScheme.primary;

  testWidgets('the focused table shows a frame even when nothing is selected', (tester) async {
    await pumpWideBoard(tester);

    expect(boardState(tester).selectedId, isNull);
    expect(focusFrameBorder(tester, LoanTable.focusFrameKey), Border.all(color: primaryOf(tester), width: 2));
  });

  testWidgets('the focused narrow list shows a frame even when nothing is selected', (tester) async {
    await pumpBoard(tester, width: 600);

    expect(boardState(tester).selectedId, isNull);
    expect(focusFrameBorder(tester, LoanList.focusFrameKey), Border.all(color: primaryOf(tester), width: 2));
  });

  testWidgets('focus and its frame come back to the table after retry', (tester) async {
    await pumpWideBoard(tester);

    await simulate(tester, 'Simuliraj grešku');
    await refresh(tester);
    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pumpAndSettle();

    expect(boardState(tester).selectedId, isNull);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'loan board');
    expect(focusFrameBorder(tester, LoanTable.focusFrameKey), Border.all(color: primaryOf(tester), width: 2));
  });

  testWidgets('a simulated failure hits the next action', (tester) async {
    await pumpWideBoard(tester);
    await tester.tap(find.byKey(const ValueKey(LoanId('desk-1'))));
    await tester.pumpAndSettle();

    await simulate(tester, 'Simuliraj grešku');
    ScaffoldMessenger.of(tester.element(find.byType(LoanBoardScreen))).removeCurrentSnackBar();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Odobri'));
    await tester.pumpAndSettle();
    expect(find.text('Izmena nije sačuvana. Pokušajte ponovo.'), findsOneWidget);
    expect(boardState(tester).selected?.status, const Pending());
  });

  testWidgets('simulated empty response shows the empty view and recovers', (tester) async {
    await pumpWideBoard(tester);

    await simulate(tester, 'Simuliraj prazan odgovor');
    expect(find.text('Nema pozajmica.'), findsOneWidget);
    expect(find.byType(LoanTable), findsNothing);

    tester.element(find.byType(LoanBoardScreen)).read<LoanBoardBloc>().add(const LoanBoardRequested());
    await tester.pumpAndSettle();
    expect(find.text('Zatraženo'), findsOneWidget);
  });

  Future<void> tabTo(WidgetTester tester, String label) async {
    bool focusedOnLabel() {
      final focused = FocusManager.instance.primaryFocus?.context;
      if (focused == null) return false;
      return find
          .descendant(of: find.byElementPredicate((element) => element == focused), matching: find.text(label))
          .evaluate()
          .isNotEmpty;
    }

    for (var i = 0; i < 40 && !focusedOnLabel(); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(focusedOnLabel(), isTrue, reason: '$label is not reachable with Tab');
  }

  testWidgets('both simulation buttons are reached with Tab and pressed with Enter', (tester) async {
    await pumpWideBoard(tester);

    await tabTo(tester, 'Simuliraj prazan odgovor');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Nema pozajmica.'), findsOneWidget);

    await tabTo(tester, 'Simuliraj grešku');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Sledeći zahtev neće uspeti.'), findsOneWidget);
  });

  testWidgets('simulation and refresh buttons are disabled while the board is loading', (tester) async {
    await pumpWideBoard(tester);
    VoidCallback? refreshPressed() =>
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.refresh)).onPressed;

    await tester.tap(find.byTooltip('Osveži'));
    await tester.pump();
    expect(buttonWith(tester, 'Simuliraj grešku').onPressed, isNull);
    expect(buttonWith(tester, 'Simuliraj prazan odgovor').onPressed, isNull);
    expect(refreshPressed(), isNull);

    await tester.pumpAndSettle();
    expect(buttonWith(tester, 'Simuliraj grešku').onPressed, isNotNull);
    expect(buttonWith(tester, 'Simuliraj prazan odgovor').onPressed, isNotNull);
    expect(refreshPressed(), isNotNull);
  });

  group('narrow window', () {
    testWidgets('below 840 pixels the board is a list and a tap opens the detail in a bottom sheet', (tester) async {
      await pumpBoard(tester, width: 600);

      expect(find.byType(LoanList), findsOneWidget);
      expect(find.byType(LoanTable), findsNothing);
      expect(find.text('Zatraženo'), findsNothing);
      expect(find.text('Odobri'), findsNothing);

      await tester.tap(find.byKey(const ValueKey(LoanId('desk-1'))));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(buttonWith(tester, 'Odobri').onPressed, isNotNull);
      expect(buttonWith(tester, 'Odbij').onPressed, isNotNull);

      await tester.tap(find.text('Odobri'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Pozajmica je odobrena.'), findsOneWidget);
      expect(boardState(tester).selectedId, const LoanId('desk-1'));
    });

    testWidgets('the selection survives resizing in both directions', (tester) async {
      await pumpWideBoard(tester);
      await tester.tap(find.byKey(const ValueKey(LoanId('desk-1'))));
      await tester.pumpAndSettle();

      await resize(tester, width: 600);
      expect(find.byType(LoanList), findsOneWidget);
      expect(isSelected(tester, const LoanId('desk-1')), isTrue);

      await resize(tester, width: 1400);
      expect(find.byType(LoanTable), findsOneWidget);
      expect(find.text('Izaberite pozajmicu u tabeli.'), findsNothing);
      expect(find.byTooltip('Odobri (O)'), findsOneWidget);
    });

    testWidgets('arrows move the selection and Enter opens the detail', (tester) async {
      await pumpBoard(tester, width: 600);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final second = boardState(tester).items[1].loan.id;
      expect(boardState(tester).selectedId, second);
      expect(find.byType(BottomSheet), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('O acts on the selection kept from the wide table', (tester) async {
      await pumpWideBoard(tester);
      await tester.tap(find.byKey(const ValueKey(LoanId('desk-1'))));
      await tester.pumpAndSettle();
      await resize(tester, width: 600);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyO);
      await tester.pumpAndSettle();
      expect(find.text('Pozajmica je odobrena.'), findsOneWidget);
    });

    testWidgets('R in the bottom sheet rejects and closes the sheet', (tester) async {
      await pumpBoard(tester, width: 600);
      await tester.tap(find.byKey(const ValueKey(LoanId('desk-1'))));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Pozajmica je odbijena.'), findsOneWidget);
    });

    testWidgets('the list scrolls to the selected loan when it first appears', (tester) async {
      await pumpWideBoard(tester);
      for (var i = 0; i < 30; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      }
      await tester.pumpAndSettle();
      final last = boardState(tester).items.last.loan.id;
      expect(boardState(tester).selectedId, last);

      await resize(tester, width: 480, height: 560);
      final list = tester.getRect(find.byType(LoanList));
      final card = tester.getRect(find.byKey(ValueKey(last)));
      expect(card.top, greaterThanOrEqualTo(list.top));
      expect(card.bottom, lessThanOrEqualTo(list.bottom));
      expect(isSelected(tester, last), isTrue);
    });

    testWidgets('below 840 pixels the simulation buttons are icons with tooltips', (tester) async {
      await pumpBoard(tester, width: 600);

      expect(tester.takeException(), isNull);
      expect(find.text('Simuliraj grešku'), findsNothing);
      expect(find.text('Simuliraj prazan odgovor'), findsNothing);
      expect(find.byTooltip('Simuliraj grešku'), findsOneWidget);
      expect(find.byTooltip('Simuliraj prazan odgovor'), findsOneWidget);

      await tester.tap(find.byTooltip('Simuliraj grešku'));
      await tester.pumpAndSettle();
      expect(find.text('Sledeći zahtev neće uspeti.'), findsOneWidget);

      await refresh(tester);
      expect(find.text('Pokušaj ponovo'), findsOneWidget);
    });

    testWidgets('an open bottom sheet closes when the window becomes wide', (tester) async {
      await pumpBoard(tester, width: 600);
      await tester.tap(find.byKey(const ValueKey(LoanId('desk-1'))));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      await resize(tester, width: 1400);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byTooltip('Odobri (O)'), findsOneWidget);
    });
  });

  group('filters', () {
    Finder chip(String label) => find.widgetWithText(FilterChip, label);

    Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    // MemberId is an extension type, so at run time the picker is a DropdownButton<String?>; find it by label.
    Future<void> pickMember(WidgetTester tester, String member) async {
      final memberPicker = find.descendant(
        of: find.byWidgetPredicate((widget) => widget is InputDecorator && widget.decoration.labelText == 'Član'),
        matching: find.byWidgetPredicate((widget) => widget is DropdownButton),
      );
      await tapAndSettle(tester, memberPicker);
      await tapAndSettle(tester, find.text(member).last);
    }

    testWidgets('a stage chip narrows the table to that stage', (tester) async {
      await pumpWideBoard(tester);

      await tapAndSettle(tester, chip('Odbijena'));
      expect(boardState(tester).items, hasLength(2));
      expect(boardState(tester).items.every((item) => item.status is Rejected), isTrue);
      expect(find.byKey(const ValueKey(LoanId('desk-1'))), findsNothing);
    });

    testWidgets('the overdue chip keeps only loans that are late', (tester) async {
      await pumpWideBoard(tester);

      await tapAndSettle(tester, chip('Kasni'));
      expect(boardState(tester).items, hasLength(3));
      expect(boardState(tester).items.every((item) => item.status is Overdue), isTrue);
    });

    testWidgets('the member drop-down keeps only that member', (tester) async {
      await pumpWideBoard(tester);

      await pickMember(tester, 'member-6');
      expect(boardState(tester).items, hasLength(4));
      expect(boardState(tester).items.every((item) => item.loan.memberId == const MemberId('member-6')), isTrue);
    });

    testWidgets('no match shows a message inside the board, and reset brings every loan back', (tester) async {
      await pumpWideBoard(tester);

      // Every rejected loan in the seed belongs to member-3 or member-5.
      await tapAndSettle(tester, chip('Odbijena'));
      await pickMember(tester, 'member-6');
      expect(find.text('Nema pozajmica za izabrane filtere.'), findsOneWidget);
      expect(find.text('Nema pozajmica.'), findsNothing);
      expect(find.byType(LoanTable), findsNothing);
      expect(find.byType(LoanFilterBar), findsOneWidget);

      await tapAndSettle(tester, find.text('Poništi filtere'));
      expect(find.byType(LoanTable), findsOneWidget);
      expect(boardState(tester).items, hasLength(boardState(tester).allItems.length));
    });

    testWidgets('a selected loan that drops out of the filter is no longer shown in the detail', (tester) async {
      await pumpWideBoard(tester);
      await tapAndSettle(tester, find.byKey(const ValueKey(LoanId('desk-1'))));
      expect(find.text('Izaberite pozajmicu u tabeli.'), findsNothing);

      await tapAndSettle(tester, chip('Vraćena'));
      expect(boardState(tester).selectedId, isNull);
      expect(find.text('Izaberite pozajmicu u tabeli.'), findsOneWidget);
    });

    testWidgets('every kind of filter control is reachable with Tab', (tester) async {
      await pumpWideBoard(tester);
      await tapAndSettle(tester, chip('Na čekanju'));

      String? focusedControl() {
        final context = FocusManager.instance.primaryFocus?.context;
        if (context == null || context.findAncestorWidgetOfExactType<LoanFilterBar>() == null) return null;
        String? kind;
        context.visitAncestorElements((element) {
          kind = switch (element.widget) {
            FilterChip() => 'chip',
            DropdownButton() => 'drop-down',
            TextButton() => 'reset',
            _ => null,
          };
          return kind == null;
        });
        return kind;
      }

      final reached = <String>{};
      for (var i = 0; i < 40; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        if (focusedControl() case final kind?) reached.add(kind);
      }
      expect(reached, {'chip', 'drop-down', 'reset'});
    });

    testWidgets('in a narrow window the bar wraps onto several lines above the list', (tester) async {
      await pumpBoard(tester, width: 600);

      expect(find.byType(LoanList), findsOneWidget);
      expect(tester.takeException(), isNull);
      final firstChip = tester.getRect(chip('Na čekanju'));
      final reset = tester.getRect(find.text('Poništi filtere'));
      expect(reset.top, greaterThan(firstChip.bottom));
      expect(
        tester.getRect(find.byType(LoanFilterBar)).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(LoanList)).top),
      );
    });

    testWidgets('the filter survives a reload', (tester) async {
      await pumpWideBoard(tester);
      await tapAndSettle(tester, chip('Odbijena'));

      tester.element(find.byType(LoanBoardScreen)).read<LoanBoardBloc>().add(const LoanBoardRequested());
      await tester.pumpAndSettle();
      expect(boardState(tester).filter.stages, {LoanStage.rejected});
      expect(boardState(tester).items, hasLength(2));
      expect(tester.widget<FilterChip>(chip('Odbijena')).selected, isTrue);
    });
  });
}
