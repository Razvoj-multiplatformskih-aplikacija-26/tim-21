import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  test('light and dark themes use matching brightness', () {
    expect(BoardGameTheme.light().colorScheme.brightness, Brightness.light);
    expect(BoardGameTheme.dark().colorScheme.brightness, Brightness.dark);
  });
}
