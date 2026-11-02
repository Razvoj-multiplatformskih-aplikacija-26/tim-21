import 'package:design_tokens/design_tokens.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

class LoanFilterBar extends StatelessWidget {
  const LoanFilterBar({
    super.key,
    required this.filter,
    required this.games,
    required this.members,
    required this.onChanged,
  });

  final LoanFilter filter;
  final List<({BoardGameId id, String title})> games;
  final List<MemberId> members;
  final ValueChanged<LoanFilter> onChanged;

  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.sm, Spacing.lg, Spacing.sm),
      child: Wrap(
        spacing: Spacing.sm,
        runSpacing: Spacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final stage in LoanStage.values)
            FilterChip(
              label: Text(stage.label),
              selected: filter.stages.contains(stage),
              visualDensity: VisualDensity.compact,
              onSelected: (selected) => onChanged(filter.withStage(stage, selected: selected)),
            ),
          _Picker<BoardGameId>(
            label: 'Igra',
            value: filter.gameId,
            options: [for (final game in games) (value: game.id, label: game.title)],
            onChanged: (id) => onChanged(id == null ? filter.copyWith(clearGame: true) : filter.copyWith(gameId: id)),
          ),
          _Picker<MemberId>(
            label: 'Član',
            value: filter.memberId,
            options: [for (final member in members) (value: member, label: member.value)],
            onChanged: (id) =>
                onChanged(id == null ? filter.copyWith(clearMember: true) : filter.copyWith(memberId: id)),
          ),
          TextButton.icon(
            onPressed: filter.isEmpty ? null : () => onChanged(LoanFilter.none),
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Poništi filtere'),
          ),
        ],
      ),
    ),
  );
}

/// A labelled drop-down whose first option, „Sve“, stands for no restriction (`null`).
class _Picker<T> extends StatelessWidget {
  const _Picker({required this.label, required this.value, required this.options, required this.onChanged});

  final String label;
  final T? value;
  final List<({T value, String label})> options;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 200,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: value,
          isDense: true,
          isExpanded: true,
          hint: const Text('Sve'),
          items: [
            DropdownMenuItem<T?>(child: Text('Sve')),
            for (final option in options)
              DropdownMenuItem<T?>(
                value: option.value,
                child: Text(option.label, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    ),
  );
}
