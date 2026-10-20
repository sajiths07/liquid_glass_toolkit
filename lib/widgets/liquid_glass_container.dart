import 'package:flutter/material.dart';

import '../src/core/glass_quality.dart';
import '../src/core/glass_style.dart';
import '../src/theme/liquid_glass_theme.dart';
import '../src/widgets/liquid_glass_surface.dart';

/// A widget that applies a frosted glass effect to its child.
///
/// This is the original widget of `liquid_glass_ui` and keeps its 0.x API:
/// [blur], [opacity], [padding] and [borderRadius] behave as before (a white
/// tint at [opacity] over a backdrop blurred with sigma [blur], with 16 px
/// corners by default).
///
/// Since 0.5.0 it renders through [LiquidGlassSurface], so it also gains the
/// theme's border, lighting and shadow. Pass [style] to control those, or
/// use [LiquidGlassSurface] directly for full control.
class LiquidGlassContainer extends StatelessWidget {
  /// The widget below this widget in the tree.
  final Widget child;

  /// The amount of blur to apply to the background (Gaussian sigma).
  ///
  /// A higher value means a more blurred background.
  final double blur;

  /// The opacity of the white overlay color.
  ///
  /// A value of 0.0 means completely transparent, and 1.0 means completely opaque.
  final double opacity;

  /// The padding to apply to the child.
  final EdgeInsetsGeometry? padding;

  /// The radius of the corners of the glass container.
  ///
  /// If null, a default of `BorderRadius.circular(16)` is used.
  final BorderRadiusGeometry? borderRadius;

  /// Base style for lighting, border and shadow. [blur], [opacity] and
  /// [borderRadius] always override the corresponding values. Defaults to
  /// the theme style with a white tint.
  final LiquidGlassStyle? style;

  /// Rendering quality. Defaults to the theme quality.
  final LiquidGlassQuality? quality;

  /// Creates a [LiquidGlassContainer].
  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.2,
    this.padding,
    this.borderRadius,
    this.style,
    this.quality,
  });

  @override
  Widget build(BuildContext context) {
    final LiquidGlassStyle base =
        style ??
        LiquidGlassTheme.of(
          context,
        ).style.copyWith(tintColor: const Color(0xFFFFFFFF));
    return LiquidGlassSurface(
      style: base.copyWith(blur: blur, opacity: opacity),
      quality: quality,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      padding: padding,
      child: child,
    );
  }
}
