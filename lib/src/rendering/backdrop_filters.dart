import 'dart:ui' as ui;

import '../core/glass_quality.dart';
import '../core/glass_style.dart';

/// Builds the 5x4 color matrix for saturation, contrast and brightness.
///
/// Saturation uses Rec. 709 luminance weights. Offsets are expressed in the
/// `0..255` range expected by [ui.ColorFilter.matrix].
List<double> glassColorMatrix({
  required double saturation,
  required double contrast,
  required double brightness,
}) {
  const double lr = 0.2126, lg = 0.7152, lb = 0.0722;
  final double s = saturation;
  final double c = contrast;
  final double inv = 1 - s;
  final double offset = 127.5 * (1 - c) + brightness * 255;
  return <double>[
    c * (lr * inv + s), c * (lg * inv), c * (lb * inv), 0, offset, //
    c * (lr * inv), c * (lg * inv + s), c * (lb * inv), 0, offset, //
    c * (lr * inv), c * (lg * inv), c * (lb * inv + s), 0, offset, //
    0, 0, 0, 1, 0, //
  ];
}

/// Builds the non-shader part of a surface's backdrop filter, or `null` when
/// the surface needs no backdrop work at all (clear, unadjusted glass), in
/// which case no backdrop layer is created.
///
/// [presence] fades blur and color adjustments towards identity.
ui.ImageFilter? buildGlassBackdropFilter(
  LiquidGlassStyle style,
  LiquidGlassQuality quality, {
  double presence = 1,
}) {
  if (presence <= 0) return null;
  final double sigma = style.blur * presence;
  final ui.ImageFilter? blur = sigma > 0.01
      ? ui.ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: ui.TileMode.mirror,
        )
      : null;
  if (quality == LiquidGlassQuality.minimal || !style.hasColorAdjustment) {
    return blur;
  }
  final ui.ColorFilter color = ui.ColorFilter.matrix(
    glassColorMatrix(
      saturation: 1 + (style.saturation - 1) * presence,
      contrast: 1 + (style.contrast - 1) * presence,
      brightness: style.brightness * presence,
    ),
  );
  if (blur == null) return color;
  return ui.ImageFilter.compose(outer: color, inner: blur);
}
