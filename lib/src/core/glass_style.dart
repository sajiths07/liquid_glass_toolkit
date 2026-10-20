import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Immutable description of how a liquid-glass surface looks.
///
/// Every visual property can be tuned independently: transparency ([opacity])
/// is unrelated to frosting ([blur]), lighting ([rimLightIntensity],
/// [specularIntensity], [highlightOpacity]) is unrelated to tint, and so on.
///
/// Values outside the documented ranges trigger an assertion in debug mode
/// and are clamped by [sanitized] before rendering in release mode.
@immutable
class LiquidGlassStyle with Diagnosticable {
  /// Creates a glass style. The defaults describe a light, lightly frosted
  /// pane suitable for bright backgrounds.
  const LiquidGlassStyle({
    this.blur = 12,
    this.opacity = 0.16,
    this.tintColor = const Color(0xFFFFFFFF),
    this.saturation = 1.4,
    this.brightness = 0,
    this.contrast = 1,
    this.thickness = 14,
    this.refractionStrength = 0.35,
    this.dispersion = 0.15,
    this.borderColor = const Color(0x73FFFFFF),
    this.borderWidth = 1,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.highlightColor = const Color(0xFFFFFFFF),
    this.highlightOpacity = 0.6,
    this.rimLightIntensity = 0.65,
    this.specularIntensity = 0.45,
    this.lightAlignment = const Alignment(-0.55, -1),
    this.shadowColor = const Color(0x24000000),
    this.shadowBlur = 24,
    this.shadowOffset = const Offset(0, 10),
    this.enableRefraction = true,
    this.enableHighlights = true,
  }) : assert(blur >= 0, 'blur must be >= 0'),
       assert(opacity >= 0 && opacity <= 1, 'opacity must be in [0, 1]'),
       assert(
         saturation >= 0 && saturation <= 3,
         'saturation must be in [0, 3]',
       ),
       assert(
         brightness >= -1 && brightness <= 1,
         'brightness must be in [-1, 1]',
       ),
       assert(contrast >= 0 && contrast <= 3, 'contrast must be in [0, 3]'),
       assert(thickness >= 0, 'thickness must be >= 0'),
       assert(
         refractionStrength >= 0 && refractionStrength <= 1,
         'refractionStrength must be in [0, 1]',
       ),
       assert(
         dispersion >= 0 && dispersion <= 1,
         'dispersion must be in [0, 1]',
       ),
       assert(borderWidth >= 0, 'borderWidth must be >= 0'),
       assert(
         highlightOpacity >= 0 && highlightOpacity <= 1,
         'highlightOpacity must be in [0, 1]',
       ),
       assert(
         rimLightIntensity >= 0 && rimLightIntensity <= 1,
         'rimLightIntensity must be in [0, 1]',
       ),
       assert(
         specularIntensity >= 0 && specularIntensity <= 1,
         'specularIntensity must be in [0, 1]',
       ),
       assert(shadowBlur >= 0, 'shadowBlur must be >= 0');

  /// Nearly invisible glass: almost no frosting or tint, strong edges.
  const LiquidGlassStyle.clear({
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(22)),
  }) : this(
         blur: 1.5,
         opacity: 0.03,
         saturation: 1.15,
         borderColor: const Color(0x59FFFFFF),
         highlightOpacity: 0.7,
         rimLightIntensity: 0.8,
         specularIntensity: 0.5,
         refractionStrength: 0.55,
         shadowColor: const Color(0x14000000),
         borderRadius: borderRadius,
       );

  /// Heavily frosted glass that hides most detail behind it.
  const LiquidGlassStyle.frosted({
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(22)),
  }) : this(
         blur: 28,
         opacity: 0.3,
         saturation: 1.6,
         highlightOpacity: 0.5,
         refractionStrength: 0.2,
         borderRadius: borderRadius,
       );

  /// Glass tinted with [color]. [opacity] controls how strongly the color
  /// covers the backdrop.
  const LiquidGlassStyle.tinted(
    Color color, {
    double opacity = 0.32,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(22)),
  }) : this(
         tintColor: color,
         opacity: opacity,
         blur: 14,
         saturation: 1.3,
         borderColor: const Color(0x66FFFFFF),
         borderRadius: borderRadius,
       );

  /// Default style tuned for dark backgrounds and dark themes.
  const LiquidGlassStyle.dark({
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(22)),
  }) : this(
         blur: 14,
         opacity: 0.28,
         tintColor: const Color(0xFF1C1C1F),
         saturation: 1.5,
         brightness: -0.02,
         borderColor: const Color(0x38FFFFFF),
         highlightOpacity: 0.4,
         rimLightIntensity: 0.55,
         specularIntensity: 0.3,
         shadowColor: const Color(0x52000000),
         borderRadius: borderRadius,
       );

  /// Gaussian blur sigma applied to the backdrop, in logical pixels.
  ///
  /// `0` produces clear glass; `8`–`16` is lightly frosted; `24`+ is heavily
  /// frosted. Valid range: `>= 0`.
  final double blur;

  /// Opacity of the [tintColor] layer drawn on top of the blurred backdrop.
  ///
  /// Independent of [blur]. `0` is fully transparent, `1` fully covers the
  /// backdrop. Valid range: `[0, 1]`.
  final double opacity;

  /// Color of the glass body. Combined with [opacity].
  final Color tintColor;

  /// Saturation multiplier applied to the backdrop (`1` = unchanged, `0` =
  /// grayscale). Valid range: `[0, 3]`. Ignored by
  /// `LiquidGlassQuality.minimal`.
  final double saturation;

  /// Additive brightness shift applied to the backdrop. Valid range:
  /// `[-1, 1]`. Ignored by `LiquidGlassQuality.minimal`.
  final double brightness;

  /// Contrast multiplier applied to the backdrop (`1` = unchanged). Valid
  /// range: `[0, 3]`. Ignored by `LiquidGlassQuality.minimal`.
  final double contrast;

  /// Perceived thickness of the glass edge in logical pixels.
  ///
  /// Controls the width of the lit bevel and of the refraction band.
  final double thickness;

  /// How strongly the backdrop is bent near the edges (premium only).
  /// Valid range: `[0, 1]`.
  final double refractionStrength;

  /// Chromatic dispersion at the refracting edge (premium only). Valid range:
  /// `[0, 1]`.
  final double dispersion;

  /// Color of the hairline border.
  final Color borderColor;

  /// Width of the hairline border in logical pixels. `0` disables it.
  final double borderWidth;

  /// Corner radii of the glass shape.
  final BorderRadius borderRadius;

  /// Color of rim light, bevel and specular highlights.
  final Color highlightColor;

  /// Global multiplier for all highlights. Valid range: `[0, 1]`.
  final double highlightOpacity;

  /// Intensity of the directional rim light along the glass edge.
  /// Valid range: `[0, 1]`.
  final double rimLightIntensity;

  /// Intensity of the soft specular reflection near the lit edge.
  /// Valid range: `[0, 1]`.
  final double specularIntensity;

  /// Where the light source sits relative to the surface. `Alignment.topLeft`
  /// lights the top-left edge most strongly.
  final Alignment lightAlignment;

  /// Color of the drop shadow. Use a transparent color to disable it.
  final Color shadowColor;

  /// Blur radius of the drop shadow in logical pixels.
  final double shadowBlur;

  /// Offset of the drop shadow.
  final Offset shadowOffset;

  /// Whether the refraction shader may run (premium quality only).
  final bool enableRefraction;

  /// Whether rim light, bevel and specular highlights are drawn.
  final bool enableHighlights;

  /// Whether the backdrop needs a color-matrix filter at all.
  bool get hasColorAdjustment =>
      saturation != 1 || brightness != 0 || contrast != 1;

  /// Returns a copy with every numeric value clamped to its valid range and
  /// non-finite values replaced by defaults. Used by the renderer so invalid
  /// release-mode configuration never crashes painting.
  LiquidGlassStyle sanitized() {
    double clamp(double v, double lo, double hi, double fallback) =>
        v.isFinite ? v.clamp(lo, hi).toDouble() : fallback;
    return LiquidGlassStyle(
      blur: clamp(blur, 0, 200, 12),
      opacity: clamp(opacity, 0, 1, 0.16),
      tintColor: tintColor,
      saturation: clamp(saturation, 0, 3, 1),
      brightness: clamp(brightness, -1, 1, 0),
      contrast: clamp(contrast, 0, 3, 1),
      thickness: clamp(thickness, 0, 200, 14),
      refractionStrength: clamp(refractionStrength, 0, 1, 0),
      dispersion: clamp(dispersion, 0, 1, 0),
      borderColor: borderColor,
      borderWidth: clamp(borderWidth, 0, 50, 1),
      borderRadius: borderRadius,
      highlightColor: highlightColor,
      highlightOpacity: clamp(highlightOpacity, 0, 1, 0.6),
      rimLightIntensity: clamp(rimLightIntensity, 0, 1, 0.65),
      specularIntensity: clamp(specularIntensity, 0, 1, 0.45),
      lightAlignment: lightAlignment,
      shadowColor: shadowColor,
      shadowBlur: clamp(shadowBlur, 0, 200, 24),
      shadowOffset: shadowOffset.isFinite ? shadowOffset : Offset.zero,
      enableRefraction: enableRefraction,
      enableHighlights: enableHighlights,
    );
  }

  /// Converts this style into an opaque, non-blurred fallback for users who
  /// request reduced transparency. [surfaceColor] is the solid color the
  /// tint is composited onto.
  LiquidGlassStyle withReducedTransparency(Color surfaceColor) {
    final Color solid = Color.alphaBlend(
      tintColor.withValues(alpha: (opacity * 1.5).clamp(0, 1).toDouble()),
      surfaceColor,
    );
    return copyWith(
      blur: 0,
      opacity: 1,
      tintColor: solid.withValues(alpha: 1),
      saturation: 1,
      brightness: 0,
      contrast: 1,
      enableRefraction: false,
      highlightOpacity: highlightOpacity * 0.4,
    );
  }

  /// Strengthens borders for users who requested high contrast.
  /// [foreground] is the color used for text on glass.
  LiquidGlassStyle withHighContrast(Color foreground) {
    return copyWith(
      borderColor: foreground.withValues(alpha: 0.7),
      borderWidth: borderWidth < 1.5 ? 1.5 : borderWidth,
      opacity: opacity < 0.6 ? 0.6 : opacity,
    );
  }

  /// Creates a copy with the given fields replaced.
  LiquidGlassStyle copyWith({
    double? blur,
    double? opacity,
    Color? tintColor,
    double? saturation,
    double? brightness,
    double? contrast,
    double? thickness,
    double? refractionStrength,
    double? dispersion,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    Color? highlightColor,
    double? highlightOpacity,
    double? rimLightIntensity,
    double? specularIntensity,
    Alignment? lightAlignment,
    Color? shadowColor,
    double? shadowBlur,
    Offset? shadowOffset,
    bool? enableRefraction,
    bool? enableHighlights,
  }) {
    return LiquidGlassStyle(
      blur: blur ?? this.blur,
      opacity: opacity ?? this.opacity,
      tintColor: tintColor ?? this.tintColor,
      saturation: saturation ?? this.saturation,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      thickness: thickness ?? this.thickness,
      refractionStrength: refractionStrength ?? this.refractionStrength,
      dispersion: dispersion ?? this.dispersion,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      highlightColor: highlightColor ?? this.highlightColor,
      highlightOpacity: highlightOpacity ?? this.highlightOpacity,
      rimLightIntensity: rimLightIntensity ?? this.rimLightIntensity,
      specularIntensity: specularIntensity ?? this.specularIntensity,
      lightAlignment: lightAlignment ?? this.lightAlignment,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      enableRefraction: enableRefraction ?? this.enableRefraction,
      enableHighlights: enableHighlights ?? this.enableHighlights,
    );
  }

  /// Linearly interpolates between two styles. Used for animated appearance
  /// changes. Boolean flags switch at `t = 0.5`.
  static LiquidGlassStyle lerp(
    LiquidGlassStyle a,
    LiquidGlassStyle b,
    double t,
  ) {
    if (identical(a, b)) return a;
    double d(double x, double y) => lerpDouble(x, y, t)!;
    return LiquidGlassStyle(
      blur: d(a.blur, b.blur).clamp(0, double.infinity).toDouble(),
      opacity: d(a.opacity, b.opacity).clamp(0, 1).toDouble(),
      tintColor: Color.lerp(a.tintColor, b.tintColor, t)!,
      saturation: d(a.saturation, b.saturation).clamp(0, 3).toDouble(),
      brightness: d(a.brightness, b.brightness).clamp(-1, 1).toDouble(),
      contrast: d(a.contrast, b.contrast).clamp(0, 3).toDouble(),
      thickness: d(
        a.thickness,
        b.thickness,
      ).clamp(0, double.infinity).toDouble(),
      refractionStrength: d(
        a.refractionStrength,
        b.refractionStrength,
      ).clamp(0, 1).toDouble(),
      dispersion: d(a.dispersion, b.dispersion).clamp(0, 1).toDouble(),
      borderColor: Color.lerp(a.borderColor, b.borderColor, t)!,
      borderWidth: d(
        a.borderWidth,
        b.borderWidth,
      ).clamp(0, double.infinity).toDouble(),
      borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t)!,
      highlightColor: Color.lerp(a.highlightColor, b.highlightColor, t)!,
      highlightOpacity: d(
        a.highlightOpacity,
        b.highlightOpacity,
      ).clamp(0, 1).toDouble(),
      rimLightIntensity: d(
        a.rimLightIntensity,
        b.rimLightIntensity,
      ).clamp(0, 1).toDouble(),
      specularIntensity: d(
        a.specularIntensity,
        b.specularIntensity,
      ).clamp(0, 1).toDouble(),
      lightAlignment: Alignment.lerp(a.lightAlignment, b.lightAlignment, t)!,
      shadowColor: Color.lerp(a.shadowColor, b.shadowColor, t)!,
      shadowBlur: d(
        a.shadowBlur,
        b.shadowBlur,
      ).clamp(0, double.infinity).toDouble(),
      shadowOffset: Offset.lerp(a.shadowOffset, b.shadowOffset, t)!,
      enableRefraction: t < 0.5 ? a.enableRefraction : b.enableRefraction,
      enableHighlights: t < 0.5 ? a.enableHighlights : b.enableHighlights,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiquidGlassStyle &&
        other.blur == blur &&
        other.opacity == opacity &&
        other.tintColor == tintColor &&
        other.saturation == saturation &&
        other.brightness == brightness &&
        other.contrast == contrast &&
        other.thickness == thickness &&
        other.refractionStrength == refractionStrength &&
        other.dispersion == dispersion &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        other.borderRadius == borderRadius &&
        other.highlightColor == highlightColor &&
        other.highlightOpacity == highlightOpacity &&
        other.rimLightIntensity == rimLightIntensity &&
        other.specularIntensity == specularIntensity &&
        other.lightAlignment == lightAlignment &&
        other.shadowColor == shadowColor &&
        other.shadowBlur == shadowBlur &&
        other.shadowOffset == shadowOffset &&
        other.enableRefraction == enableRefraction &&
        other.enableHighlights == enableHighlights;
  }

  @override
  int get hashCode => Object.hashAll(<Object>[
    blur,
    opacity,
    tintColor,
    saturation,
    brightness,
    contrast,
    thickness,
    refractionStrength,
    dispersion,
    borderColor,
    borderWidth,
    borderRadius,
    highlightColor,
    highlightOpacity,
    rimLightIntensity,
    specularIntensity,
    lightAlignment,
    shadowColor,
    shadowBlur,
    shadowOffset,
    enableRefraction,
    enableHighlights,
  ]);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('blur', blur))
      ..add(DoubleProperty('opacity', opacity))
      ..add(ColorProperty('tintColor', tintColor))
      ..add(DoubleProperty('saturation', saturation))
      ..add(DoubleProperty('brightness', brightness))
      ..add(DoubleProperty('contrast', contrast))
      ..add(DoubleProperty('thickness', thickness))
      ..add(DoubleProperty('refractionStrength', refractionStrength))
      ..add(DoubleProperty('dispersion', dispersion))
      ..add(ColorProperty('borderColor', borderColor))
      ..add(DoubleProperty('borderWidth', borderWidth))
      ..add(DiagnosticsProperty<BorderRadius>('borderRadius', borderRadius))
      ..add(ColorProperty('highlightColor', highlightColor))
      ..add(DoubleProperty('highlightOpacity', highlightOpacity))
      ..add(DoubleProperty('rimLightIntensity', rimLightIntensity))
      ..add(DoubleProperty('specularIntensity', specularIntensity))
      ..add(DiagnosticsProperty<Alignment>('lightAlignment', lightAlignment))
      ..add(ColorProperty('shadowColor', shadowColor))
      ..add(DoubleProperty('shadowBlur', shadowBlur))
      ..add(DiagnosticsProperty<Offset>('shadowOffset', shadowOffset))
      ..add(
        FlagProperty(
          'enableRefraction',
          value: enableRefraction,
          ifFalse: 'refraction disabled',
        ),
      )
      ..add(
        FlagProperty(
          'enableHighlights',
          value: enableHighlights,
          ifFalse: 'highlights disabled',
        ),
      );
  }
}
