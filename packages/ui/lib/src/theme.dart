import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';

abstract final class BoardGameTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(BrandColors.blue), brightness: brightness),
  );
}
