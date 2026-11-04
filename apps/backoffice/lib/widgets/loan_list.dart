import 'package:blocs/blocs.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import 'loan_table.dart';
import 'scroll_reveal.dart';

class LoanList extends StatefulWidget {
  const LoanList({
    super.key,
    required this.items,
    required this.selectedId,
    required this.focusNode,
    required this.onSelect,
    required this.onMove,
    required this.onOpen,
  });

  static const itemHeight = 96.0;
  static const focusFrameKey = ValueKey('loan-list-focus-frame');

  final List<LoanBoardItem> items;
  final LoanId? selectedId;
  final FocusNode focusNode;
  final ValueChanged<LoanId> onSelect;
  final ValueChanged<int> onMove;

  final VoidCallback onOpen;

  @override
  State<LoanList> createState() => _LoanListState();
}

class _LoanListState extends State<LoanList> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected(animate: false));
  }

  @override
  void didUpdateWidget(LoanList oldWidget) {
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

  void _revealSelected({bool animate = true}) {
    if (!mounted) return;
    final index = widget.items.indexWhere((item) => item.loan.id == widget.selectedId);
    revealIndex(_scroll, index: index, extent: LoanList.itemHeight, animate: animate);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        widget.onMove(-1);
      case LogicalKeyboardKey.arrowDown:
        widget.onMove(1);
      case LogicalKeyboardKey.enter when widget.selectedId != null:
        widget.onOpen();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _tapCard(LoanId id) {
    widget.onSelect(id);
    widget.focusNode.requestFocus();
    widget.onOpen();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return Focus(
      focusNode: widget.focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Semantics(
        container: true,
        label: 'Lista pozajmica, ${items.length} pozajmica',
        child: ListenableBuilder(
          listenable: widget.focusNode,
          builder: (context, _) => DecoratedBox(
            key: LoanList.focusFrameKey,
            position: DecorationPosition.foreground,
            decoration: widget.focusNode.hasFocus
                ? BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2))
                : const BoxDecoration(),
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              itemExtent: LoanList.itemHeight,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = item.loan.id == widget.selectedId;
                return _LoanCard(
                  key: ValueKey(item.loan.id),
                  item: item,
                  selected: selected,
                  focused: selected && widget.focusNode.hasFocus,
                  onTap: () => _tapCard(item.loan.id),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({super.key, required this.item, required this.selected, required this.focused, required this.onTap});

  final LoanBoardItem item;
  final bool selected;

  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final overdue = item.status is Overdue;
    final body = theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final radius = BorderRadius.circular(Radii.md);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected
              ? scheme.secondaryContainer
              : overdue
              ? scheme.errorContainer.withValues(alpha: 0.35)
              : scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: focused ? 3 : (selected ? 2 : 1),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            canRequestFocus: false,
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: overdue ? scheme.error : Colors.transparent, width: 4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.gameTitle,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(item.loan.memberId.value, style: body, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      LoanStatusBadge(status: item.status),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        'Rok: ${loanDeadline(item.status)}',
                        style: overdue ? body?.copyWith(color: scheme.error, fontWeight: FontWeight.w600) : body,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
