import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  final statuses = <LoanStatus>[
    const Pending(),
    Approved(pickupDeadline: wednesday),
    PickedUp(dueAt: wednesday),
    Overdue(dueAt: wednesday),
    Returned(returnedAt: wednesday),
    const Rejected(),
    const Cancelled(),
  ];

  test('allows exactly eight transitions out of forty-nine', () {
    final allowed = <(Type, Type)>[
      for (final from in statuses)
        for (final to in statuses)
          if (canTransition(from, to)) (from.runtimeType, to.runtimeType),
    ];

    expect(allowed, [
      (Pending, Approved),
      (Pending, Rejected),
      (Pending, Cancelled),
      (Approved, PickedUp),
      (Approved, Cancelled),
      (PickedUp, Overdue),
      (PickedUp, Returned),
      (Overdue, Returned),
    ]);
  });

  test('only the four open statuses are active', () {
    expect(statuses.where((status) => status.isActive).map((status) => status.runtimeType), [
      Pending,
      Approved,
      PickedUp,
      Overdue,
    ]);
  });
}
