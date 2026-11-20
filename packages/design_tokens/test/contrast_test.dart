import 'dart:math' as math;

import 'package:design_tokens/design_tokens.dart';
import 'package:test/test.dart';

double _channel(int value) {
  final c = value / 255;
  return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(int argb) =>
    0.2126 * _channel((argb >> 16) & 0xFF) + 0.7152 * _channel((argb >> 8) & 0xFF) + 0.0722 * _channel(argb & 0xFF);

double contrast(int a, int b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('every status colour pair meets WCAG AA in both schemes', () {
    for (final (scheme, s) in [('light', StatusColorTokens.light), ('dark', StatusColorTokens.dark)]) {
      final textPairs = <String, (int, int)>{
        'pending': (s.onPending, s.pending),
        'approved': (s.onApproved, s.approved),
        'pickedUp': (s.onPickedUp, s.pickedUp),
        'overdue': (s.onOverdue, s.overdue),
        'returned': (s.onReturned, s.returned),
        'rejected': (s.onRejected, s.rejected),
        'cancelled': (s.onCancelled, s.cancelled),
      };
      for (final MapEntry(key: name, value: (foreground, background)) in textPairs.entries) {
        expect(contrast(foreground, background), greaterThanOrEqualTo(4.5), reason: '$scheme: $name');
      }
    }
  });
}
