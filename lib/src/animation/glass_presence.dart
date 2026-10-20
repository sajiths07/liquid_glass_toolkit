import 'package:flutter/widgets.dart';

/// Scales how "present" the liquid-glass surfaces below it are, from `0`
/// (invisible) to `1` (fully visible).
///
/// Wrapping a glass surface in [Opacity] or [FadeTransition] is problematic:
/// on several renderers a backdrop filter inside a transparent layer samples
/// an empty backdrop, so the blur disappears for the whole fade. Surfaces
/// instead read this value and scale their own tint, border, highlight and
/// shadow alpha, blur radius and content opacity. All entry/exit transitions
/// in this package use it.
///
/// Only liquid-glass surfaces react to it; wrap other content in a
/// [FadeTransition] if it should fade too.
class LiquidGlassPresence extends InheritedWidget {
  /// Creates a presence scope.
  const LiquidGlassPresence({
    super.key,
    required this.value,
    required super.child,
  });

  /// Presence factor. Values are clamped to `[0, 1]` when read.
  final double value;

  /// The presence factor for [context], or `1` when there is no scope.
  static double of(BuildContext context) {
    final double? value = context
        .dependOnInheritedWidgetOfExactType<LiquidGlassPresence>()
        ?.value;
    if (value == null || !value.isFinite) return 1;
    return value.clamp(0.0, 1.0);
  }

  @override
  bool updateShouldNotify(LiquidGlassPresence oldWidget) =>
      value != oldWidget.value;
}
