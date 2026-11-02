import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../identifiers.dart';
import 'loan.dart';
import 'loan_status.dart';

@immutable
final class LoanFilter {
  const LoanFilter({this.stages = const {}, this.gameId, this.memberId});

  static const none = LoanFilter();

  final Set<LoanStage> stages;
  final BoardGameId? gameId;
  final MemberId? memberId;

  bool get isEmpty => stages.isEmpty && gameId == null && memberId == null;

  bool matches(Loan loan, DateTime now) {
    final status = loan.statusAt(now);
    if (stages.isNotEmpty && !stages.contains(status.stage)) return false;
    if (gameId != null && loan.gameId != gameId) return false;
    if (memberId != null && loan.memberId != memberId) return false;
    return true;
  }

  LoanFilter withStage(LoanStage stage, {required bool selected}) =>
      copyWith(stages: selected ? {...stages, stage} : ({...stages}..remove(stage)));

  LoanFilter copyWith({
    Set<LoanStage>? stages,
    BoardGameId? gameId,
    bool clearGame = false,
    MemberId? memberId,
    bool clearMember = false,
  }) => LoanFilter(
    stages: stages ?? this.stages,
    gameId: clearGame ? null : (gameId ?? this.gameId),
    memberId: clearMember ? null : (memberId ?? this.memberId),
  );

  @override
  bool operator ==(Object other) =>
      other is LoanFilter &&
      const SetEquality<LoanStage>().equals(other.stages, stages) &&
      other.gameId == gameId &&
      other.memberId == memberId;

  @override
  int get hashCode => Object.hash(const SetEquality<LoanStage>().hash(stages), gameId, memberId);

  @override
  String toString() => 'LoanFilter(stages: $stages, game: $gameId, member: $memberId)';
}

List<Loan> filterLoans(List<Loan> loans, LoanFilter filter, DateTime now) => [
  for (final loan in loans)
    if (filter.matches(loan, now)) loan,
];
