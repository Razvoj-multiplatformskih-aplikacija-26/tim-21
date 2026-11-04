import 'package:blocs/blocs.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import 'scroll_reveal.dart';

String loanDeadline(LoanStatus status) => switch (status) {
  Approved(:final pickupDeadline) => formatDate(pickupDeadline),
  PickedUp(:final dueAt) || Overdue(:final dueAt) => formatDate(dueAt),
  Returned(:final returnedAt) => formatDate(returnedAt),
  Pending() || Rejected() || Cancelled() => '—',
};

class LoanTable extends StatefulWidget {
  const LoanTable({
    super.key,
    required this.items,
    required this.selectedId,
    required this.focusNode,
    required this.onSelect,
    required this.onMove,
  });

  static const rowHeight = 52.0;
  static const focusFrameKey = ValueKey('loan-table-focus-frame');

  final List<LoanBoardItem> items;
  final LoanId? selectedId;
  final FocusNode focusNode;
  final ValueChanged<LoanId> onSelect;
  final ValueChanged<int> onMove;

  @override
  State<LoanTable> createState() => _LoanTableState();
}

class _LoanTableState extends State<LoanTable> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(LoanTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedId != null && widget.selectedId != oldWidget.selectedId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _revealSelected() {
    if (!mounted) return;
    final index = widget.items.indexWhere((item) => item.loan.id == widget.selectedId);
    revealIndex(_scroll, index: index, extent: LoanTable.rowHeight);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp => -1,
      LogicalKeyboardKey.arrowDown => 1,
      _ => 0,
    };
    if (delta == 0) return KeyEventResult.ignored;
    widget.onMove(delta);
    return KeyEventResult.handled;
  }

  void _tapRow(LoanId id) {
    widget.onSelect(id);
    widget.focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final items = widget.items;
    return Focus(
      focusNode: widget.focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Semantics(
        container: true,
        label: 'Tabla pozajmica, ${items.length} pozajmica',
        child: ListenableBuilder(
          listenable: widget.focusNode,
          builder: (context, _) => DecoratedBox(
            key: LoanTable.focusFrameKey,
            position: DecorationPosition.foreground,
            decoration: widget.focusNode.hasFocus
                ? BoxDecoration(border: Border.all(color: theme.colorScheme.primary, width: 2))
                : const BoxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: theme.colorScheme.surfaceContainerLow,
                  child: SizedBox(
                    height: 44,
                    child: _Columns(
                      game: _HeaderCell('Igra', style: headerStyle),
                      member: _HeaderCell('Član', style: headerStyle),
                      status: _HeaderCell('Stanje', style: headerStyle),
                      deadline: _HeaderCell('Rok', style: headerStyle),
                      requested: _HeaderCell('Zatraženo', style: headerStyle),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    itemExtent: LoanTable.rowHeight,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final selected = item.loan.id == widget.selectedId;
                      return _LoanRow(
                        key: ValueKey(item.loan.id),
                        item: item,
                        selected: selected,
                        focused: selected && widget.focusNode.hasFocus,
                        onTap: () => _tapRow(item.loan.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoanRow extends StatelessWidget {
  const _LoanRow({super.key, required this.item, required this.selected, required this.focused, required this.onTap});

  final LoanBoardItem item;
  final bool selected;

  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final overdue = item.status is Overdue;
    final background = selected
        ? scheme.secondaryContainer
        : overdue
        ? scheme.errorContainer.withValues(alpha: 0.35)
        : Colors.transparent;
    final body = theme.textTheme.bodyMedium;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: background,
        child: InkWell(
          onTap: onTap,
          canRequestFocus: false,
          child: Container(
            foregroundDecoration: focused ? BoxDecoration(border: Border.all(color: scheme.primary, width: 2)) : null,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: overdue ? scheme.error : Colors.transparent, width: 4),
                bottom: BorderSide(color: scheme.outlineVariant),
              ),
            ),
            child: _Columns(
              game: _TextCell(item.gameTitle, style: theme.textTheme.titleSmall),
              member: _TextCell(item.loan.memberId.value, style: body),
              status: Align(
                alignment: Alignment.centerLeft,
                child: LoanStatusBadge(status: item.status),
              ),
              deadline: _TextCell(
                loanDeadline(item.status),
                style: overdue ? body?.copyWith(color: scheme.error, fontWeight: FontWeight.w600) : body,
              ),
              requested: _TextCell(formatDate(item.loan.requestedAt), style: body),
            ),
          ),
        ),
      ),
    );
  }
}

class _Columns extends StatelessWidget {
  const _Columns({
    required this.game,
    required this.member,
    required this.status,
    required this.deadline,
    required this.requested,
  });

  final Widget game;
  final Widget member;
  final Widget status;
  final Widget deadline;
  final Widget requested;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
    child: Row(
      children: [
        Expanded(flex: 3, child: game),
        Expanded(flex: 2, child: member),
        SizedBox(width: 130, child: status),
        SizedBox(width: 130, child: deadline),
        SizedBox(width: 120, child: requested),
      ],
    ),
  );
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.style});

  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Semantics(header: true, child: _TextCell(label, style: style));
}

class _TextCell extends StatelessWidget {
  const _TextCell(this.text, {required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: Spacing.sm),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );
}
