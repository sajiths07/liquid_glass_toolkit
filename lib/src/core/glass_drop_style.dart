import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Outline of a [LiquidGlassDropStyle] indicator.
enum LiquidGlassDropShape {
  /// Fully rounded ends (a pill). Default.
  capsule,

  /// A circle sized to the smaller of the resolved width and height. It
  /// still stretches into a capsule while moving, like a liquid drop.
  circle,

  /// A rectangle with [LiquidGlassDropStyle.borderRadius] corners.
  roundedRectangle,
}

/// Appearance of the clear "water drop" that marks the selected item of a
/// `LiquidGlassNavigationBar` (and other liquid selectors).
///
/// The drop is nearly transparent: it slightly magnifies the content
/// behind it, and paints the optics of a real drop of water (a soft
/// refraction rim, a bright caustic, a specular highlight and a thin bright
/// edge) plus an optional drop shadow.
///
/// ```dart
/// LiquidGlassNavigationBar(
///   dropStyle: const LiquidGlassDropStyle(
///     shape: LiquidGlassDropShape.circle,
///     size: Size(52, 52),
///     shadowColor: Color(0x4D0A84FF),
///     magnification: 1.25,
///   ),
///   // ...
/// )
/// ```
@immutable
class LiquidGlassDropStyle with Diagnosticable {
  /// Creates a drop style. Every value has a sensible default.
  const LiquidGlassDropStyle({
    this.size,
    this.shape = LiquidGlassDropShape.capsule,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.magnification = 1.15,
    this.tintColor = const Color(0xFFFFFFFF),
    this.tintOpacity,
    this.borderColor,
    this.borderWidth = 0.8,
    this.highlightColor = const Color(0xFFFFFFFF),
    this.opticsIntensity = 1,
    this.shadowColor = const Color(0x29000000),
    this.shadowBlur = 14,
    this.shadowOffset = const Offset(0, 4),
    this.stretch = true,
  }) : assert(magnification > 0, 'magnification must be > 0'),
       assert(
         tintOpacity == null || (tintOpacity >= 0 && tintOpacity <= 1),
         'tintOpacity must be in [0, 1]',
       ),
       assert(borderWidth >= 0, 'borderWidth must be >= 0'),
       assert(
         opticsIntensity >= 0 && opticsIntensity <= 1,
         'opticsIntensity must be in [0, 1]',
       ),
       assert(shadowBlur >= 0, 'shadowBlur must be >= 0');

  /// Preferred size of the drop. A null dimension fills the item slot
  /// (minus a small gap). Sizes are clamped to the slot.
  final Size? size;

  /// Outline of the drop.
  final LiquidGlassDropShape shape;

  /// Corner radius used by [LiquidGlassDropShape.roundedRectangle].
  final BorderRadius borderRadius;

  /// How much the content behind the drop is magnified. `1` disables the
  /// lens. The lens is not used on the web, where backdrop magnification
  /// interferes with blur on other glass surfaces, nor under reduced
  /// transparency; the drop optics are still painted there.
  final double magnification;

  /// Color of the very light tint inside the drop.
  final Color tintColor;

  /// Opacity of [tintColor]. Defaults to a brightness-dependent value
  /// (about 0.16 in light mode and 0.06 in dark mode).
  final double? tintOpacity;

  /// Edge color. Defaults to translucent white.
  final Color? borderColor;

  /// Edge width.
  final double borderWidth;

  /// Color of the caustic, highlight and bright edge.
  final Color highlightColor;

  /// Strength of the painted optics (rim, caustic, highlight, edge), 0..1.
  final double opticsIntensity;

  /// Color of the soft shadow under the drop. Use a transparent color to
  /// remove it.
  final Color shadowColor;

  /// Blur radius of the shadow.
  final double shadowBlur;

  /// Offset of the shadow.
  final Offset shadowOffset;

  /// Whether the drop stretches and flattens with its speed while moving,
  /// like liquid. Always off under reduced motion.
  final bool stretch;

  /// Whether the drop should magnify its backdrop on this platform.
  bool get usesMagnification => magnification != 1 && !kIsWeb;

  /// Resolves the drop size inside a slot of [slot] size.
  Size resolveSize(Size slot) {
    double w = math.min(size?.width ?? slot.width, slot.width);
    double h = math.min(size?.height ?? slot.height, slot.height);
    if (shape == LiquidGlassDropShape.circle) {
      w = h = math.min(w, h);
    }
    return Size(math.max(0, w), math.max(0, h));
  }

  /// Corner radius for a drop of [resolved] size.
  BorderRadius resolveRadius(Size resolved) => switch (shape) {
    LiquidGlassDropShape.roundedRectangle => borderRadius,
    _ => BorderRadius.circular(resolved.shortestSide / 2),
  };

  /// Returns a copy with the given fields replaced.
  LiquidGlassDropStyle copyWith({
    Size? size,
    LiquidGlassDropShape? shape,
    BorderRadius? borderRadius,
    double? magnification,
    Color? tintColor,
    double? tintOpacity,
    Color? borderColor,
    double? borderWidth,
    Color? highlightColor,
    double? opticsIntensity,
    Color? shadowColor,
    double? shadowBlur,
    Offset? shadowOffset,
    bool? stretch,
  }) {
    return LiquidGlassDropStyle(
      size: size ?? this.size,
      shape: shape ?? this.shape,
      borderRadius: borderRadius ?? this.borderRadius,
      magnification: magnification ?? this.magnification,
      tintColor: tintColor ?? this.tintColor,
      tintOpacity: tintOpacity ?? this.tintOpacity,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      highlightColor: highlightColor ?? this.highlightColor,
      opticsIntensity: opticsIntensity ?? this.opticsIntensity,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      stretch: stretch ?? this.stretch,
    );
  }

  /// Linearly interpolates between two drop styles.
  static LiquidGlassDropStyle lerp(
    LiquidGlassDropStyle a,
    LiquidGlassDropStyle b,
    double t,
  ) {
    if (identical(a, b)) return a;
    final bool first = t < 0.5;
    return LiquidGlassDropStyle(
      size: Size.lerp(a.size, b.size, t),
      shape: first ? a.shape : b.shape,
      borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t)!,
      magnification: math.max(
        0.01,
        lerpDouble(a.magnification, b.magnification, t)!,
      ),
      tintColor: Color.lerp(a.tintColor, b.tintColor, t)!,
      tintOpacity: a.tintOpacity == null || b.tintOpacity == null
          ? (first ? a.tintOpacity : b.tintOpacity)
          : lerpDouble(a.tintOpacity, b.tintOpacity, t)!.clamp(0.0, 1.0),
      borderColor: Color.lerp(a.borderColor, b.borderColor, t),
      borderWidth: math.max(0, lerpDouble(a.borderWidth, b.borderWidth, t)!),
      highlightColor: Color.lerp(a.highlightColor, b.highlightColor, t)!,
      opticsIntensity: lerpDouble(
        a.opticsIntensity,
        b.opticsIntensity,
        t,
      )!.clamp(0.0, 1.0),
      shadowColor: Color.lerp(a.shadowColor, b.shadowColor, t)!,
      shadowBlur: math.max(0, lerpDouble(a.shadowBlur, b.shadowBlur, t)!),
      shadowOffset: Offset.lerp(a.shadowOffset, b.shadowOffset, t)!,
      stretch: first ? a.stretch : b.stretch,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiquidGlassDropStyle &&
          other.size == size &&
          other.shape == shape &&
          other.borderRadius == borderRadius &&
          other.magnification == magnification &&
          other.tintColor == tintColor &&
          other.tintOpacity == tintOpacity &&
          other.borderColor == borderColor &&
          other.borderWidth == borderWidth &&
          other.highlightColor == highlightColor &&
          other.opticsIntensity == opticsIntensity &&
          other.shadowColor == shadowColor &&
          other.shadowBlur == shadowBlur &&
          other.shadowOffset == shadowOffset &&
          other.stretch == stretch;

  @override
  int get hashCode => Object.hash(
    size,
    shape,
    borderRadius,
    magnification,
    tintColor,
    tintOpacity,
    borderColor,
    borderWidth,
    highlightColor,
    opticsIntensity,
    shadowColor,
    shadowBlur,
    shadowOffset,
    stretch,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Size>('size', size, defaultValue: null))
      ..add(EnumProperty<LiquidGlassDropShape>('shape', shape))
      ..add(DoubleProperty('magnification', magnification))
      ..add(ColorProperty('tintColor', tintColor))
      ..add(DoubleProperty('tintOpacity', tintOpacity, defaultValue: null))
      ..add(ColorProperty('shadowColor', shadowColor))
      ..add(DoubleProperty('shadowBlur', shadowBlur))
      ..add(FlagProperty('stretch', value: stretch, ifFalse: 'rigid'));
  }
}
