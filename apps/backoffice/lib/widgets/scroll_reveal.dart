import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

void revealIndex(ScrollController scroll, {required int index, required double extent, bool animate = true}) {
  if (index < 0 || !scroll.hasClients) return;
  final position = scroll.position;
  final top = index * extent;
  final bottom = top + extent;
  final double target;
  if (top < position.pixels) {
    target = top;
  } else if (bottom > position.pixels + position.viewportDimension) {
    target = bottom - position.viewportDimension;
  } else {
    return;
  }
  final clamped = target.clamp(position.minScrollExtent, position.maxScrollExtent);
  if (animate) {
    scroll.animateTo(clamped, duration: MotionTokens.short, curve: Curves.easeOut);
  } else {
    scroll.jumpTo(clamped);
  }
}
