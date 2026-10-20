import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../animation/animation_config.dart';
import '../core/glass_quality.dart';
import '../core/glass_style.dart';

/// App-wide configuration for liquid-glass widgets.
///
/// Provide it in one of two ways (both are optional):
///
/// * Wrap a subtree in [LiquidGlassTheme].
/// * Add it to `ThemeData.extensions` of a Material app. Separate light and
///   dark instances then follow the app's `ThemeMode` automatically.
///
/// Without either, [LiquidGlassThemeData.fallback] is used for the ambient
/// brightness.
@immutable
class LiquidGlassThemeData extends ThemeExtension<LiquidGlassThemeData>
    with Diagnosticable {
  /// Creates theme data. Unspecified values use light-mode defaults.
  const LiquidGlassThemeData({
    this.style = const LiquidGlassStyle(),
    this.quality = LiquidGlassQuality.standard,
    this.animation = LiquidGlassAnimationConfig.fluid,
    this.interactionAnimation = LiquidGlassAnimationConfig.snappy,
    this.overlayAnimation = const LiquidGlassAnimationConfig(
      duration: Duration(milliseconds: 380),
      reverseDuration: Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      spring: SpringDescription(mass: 1, stiffness: 300, damping: 30),
    ),
    this.foregroundColor = const Color(0xFF111114),
    this.accentColor = const Color(0xFF0A84FF),
    this.secondaryForegroundColor,
    this.onAccentColor = const Color(0xFFFFFFFF),
    this.destructiveColor = const Color(0xFFFF3B30),
    this.opaqueSurfaceColor = const Color(0xFFF2F2F7),
    this.reduceMotion,
    this.reduceTransparency,
  });

  /// Light-mode defaults with optional overrides.
  factory LiquidGlassThemeData.light({
    LiquidGlassStyle? style,
    LiquidGlassQuality quality = LiquidGlassQuality.standard,
    LiquidGlassAnimationConfig? animation,
    LiquidGlassAnimationConfig? interactionAnimation,
    LiquidGlassAnimationConfig? overlayAnimation,
    Color? foregroundColor,
    Color? accentColor,
    Color? secondaryForegroundColor,
    Color? onAccentColor,
    Color? destructiveColor,
    bool? reduceMotion,
    bool? reduceTransparency,
  }) {
    const LiquidGlassThemeData base = LiquidGlassThemeData();
    return base.copyWith(
      style: style,
      quality: quality,
      animation: animation,
      interactionAnimation: interactionAnimation,
      overlayAnimation: overlayAnimation,
      foregroundColor: foregroundColor,
      accentColor: accentColor,
      secondaryForegroundColor: secondaryForegroundColor,
      onAccentColor: onAccentColor,
      destructiveColor: destructiveColor,
      reduceMotion: reduceMotion,
      reduceTransparency: reduceTransparency,
    );
  }

  /// Dark-mode defaults with optional overrides.
  factory LiquidGlassThemeData.dark({
    LiquidGlassStyle? style,
    LiquidGlassQuality quality = LiquidGlassQuality.standard,
    LiquidGlassAnimationConfig? animation,
    LiquidGlassAnimationConfig? interactionAnimation,
    LiquidGlassAnimationConfig? overlayAnimation,
    Color? foregroundColor,
    Color? accentColor,
    Color? secondaryForegroundColor,
    Color? onAccentColor,
    Color? destructiveColor,
    bool? reduceMotion,
    bool? reduceTransparency,
  }) {
    const LiquidGlassThemeData base = LiquidGlassThemeData(
      style: LiquidGlassStyle.dark(),
      foregroundColor: Color(0xFFF5F5F7),
      accentColor: Color(0xFF0A84FF),
      destructiveColor: Color(0xFFFF453A),
      opaqueSurfaceColor: Color(0xFF1C1C1E),
    );
    return base.copyWith(
      style: style,
      quality: quality,
      animation: animation,
      interactionAnimation: interactionAnimation,
      overlayAnimation: overlayAnimation,
      foregroundColor: foregroundColor,
      accentColor: accentColor,
      secondaryForegroundColor: secondaryForegroundColor,
      onAccentColor: onAccentColor,
      destructiveColor: destructiveColor,
      reduceMotion: reduceMotion,
      reduceTransparency: reduceTransparency,
    );
  }

  /// The default theme for [brightness].
  factory LiquidGlassThemeData.fallback(Brightness brightness) =>
      brightness == Brightness.dark
      ? LiquidGlassThemeData.dark()
      : LiquidGlassThemeData.light();

  /// Default glass appearance for every surface.
  final LiquidGlassStyle style;

  /// Default rendering quality. See [LiquidGlassQuality].
  final LiquidGlassQuality quality;

  /// Motion of indicators, switches, segmented controls and implicit style
  /// changes.
  final LiquidGlassAnimationConfig animation;

  /// Motion of press feedback on buttons and cards.
  final LiquidGlassAnimationConfig interactionAnimation;

  /// Motion of dialogs, sheets, menus, morphs and page transitions.
  final LiquidGlassAnimationConfig overlayAnimation;

  /// Color for text and icons drawn on glass.
  final Color foregroundColor;

  /// Color for selected and "on" states.
  final Color accentColor;

  /// Color for unselected navigation items and segments, placeholders and
  /// other secondary content. Defaults to [foregroundColor] at 72% opacity
  /// (see [effectiveSecondaryForegroundColor]).
  final Color? secondaryForegroundColor;

  /// Color for text and icons drawn on [accentColor] (for example inside a
  /// prominent button).
  final Color onAccentColor;

  /// Color for destructive actions such as "Delete" menu items.
  final Color destructiveColor;

  /// [secondaryForegroundColor], or [foregroundColor] at 72% opacity.
  Color get effectiveSecondaryForegroundColor =>
      secondaryForegroundColor ??
      foregroundColor.withValues(alpha: foregroundColor.a * 0.72);

  /// Solid color used behind glass when transparency is reduced.
  final Color opaqueSurfaceColor;

  /// Forces reduced motion on (`true`) or off (`false`). `null` follows the
  /// platform setting (`MediaQueryData.disableAnimations`).
  final bool? reduceMotion;

  /// Forces the opaque fallback on (`true`) or off (`false`). `null` follows
  /// the platform high-contrast setting (`MediaQueryData.highContrast`).
  /// Flutter does not expose the iOS "Reduce Transparency" switch, so apps
  /// that want to honor it should forward their own preference here.
  final bool? reduceTransparency;

  @override
  LiquidGlassThemeData copyWith({
    LiquidGlassStyle? style,
    LiquidGlassQuality? quality,
    LiquidGlassAnimationConfig? animation,
    LiquidGlassAnimationConfig? interactionAnimation,
    LiquidGlassAnimationConfig? overlayAnimation,
    Color? foregroundColor,
    Color? accentColor,
    Color? secondaryForegroundColor,
    Color? onAccentColor,
    Color? destructiveColor,
    Color? opaqueSurfaceColor,
    bool? reduceMotion,
    bool? reduceTransparency,
  }) {
    return LiquidGlassThemeData(
      style: style ?? this.style,
      quality: quality ?? this.quality,
      animation: animation ?? this.animation,
      interactionAnimation: interactionAnimation ?? this.interactionAnimation,
      overlayAnimation: overlayAnimation ?? this.overlayAnimation,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      accentColor: accentColor ?? this.accentColor,
      secondaryForegroundColor:
          secondaryForegroundColor ?? this.secondaryForegroundColor,
      onAccentColor: onAccentColor ?? this.onAccentColor,
      destructiveColor: destructiveColor ?? this.destructiveColor,
      opaqueSurfaceColor: opaqueSurfaceColor ?? this.opaqueSurfaceColor,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      reduceTransparency: reduceTransparency ?? this.reduceTransparency,
    );
  }

  @override
  LiquidGlassThemeData lerp(
    covariant ThemeExtension<LiquidGlassThemeData>? other,
    double t,
  ) {
    if (other is! LiquidGlassThemeData) return this;
    final bool first = t < 0.5;
    return LiquidGlassThemeData(
      style: LiquidGlassStyle.lerp(style, other.style, t),
      quality: first ? quality : other.quality,
      animation: first ? animation : other.animation,
      interactionAnimation: first
          ? interactionAnimation
          : other.interactionAnimation,
      overlayAnimation: first ? overlayAnimation : other.overlayAnimation,
      foregroundColor: Color.lerp(foregroundColor, other.foregroundColor, t)!,
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
      secondaryForegroundColor: Color.lerp(
        secondaryForegroundColor,
        other.secondaryForegroundColor,
        t,
      ),
      onAccentColor: Color.lerp(onAccentColor, other.onAccentColor, t)!,
      destructiveColor: Color.lerp(
        destructiveColor,
        other.destructiveColor,
        t,
      )!,
      opaqueSurfaceColor: Color.lerp(
        opaqueSurfaceColor,
        other.opaqueSurfaceColor,
        t,
      )!,
      reduceMotion: first ? reduceMotion : other.reduceMotion,
      reduceTransparency: first ? reduceTransparency : other.reduceTransparency,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiquidGlassThemeData &&
        other.style == style &&
        other.quality == quality &&
        other.animation == animation &&
        other.interactionAnimation == interactionAnimation &&
        other.overlayAnimation == overlayAnimation &&
        other.foregroundColor == foregroundColor &&
        other.accentColor == accentColor &&
        other.secondaryForegroundColor == secondaryForegroundColor &&
        other.onAccentColor == onAccentColor &&
        other.destructiveColor == destructiveColor &&
        other.opaqueSurfaceColor == opaqueSurfaceColor &&
        other.reduceMotion == reduceMotion &&
        other.reduceTransparency == reduceTransparency;
  }

  @override
  int get hashCode => Object.hash(
    style,
    quality,
    animation,
    interactionAnimation,
    overlayAnimation,
    foregroundColor,
    accentColor,
    secondaryForegroundColor,
    onAccentColor,
    destructiveColor,
    opaqueSurfaceColor,
    reduceMotion,
    reduceTransparency,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<LiquidGlassStyle>('style', style))
      ..add(EnumProperty<LiquidGlassQuality>('quality', quality))
      ..add(
        DiagnosticsProperty<LiquidGlassAnimationConfig>('animation', animation),
      )
      ..add(ColorProperty('foregroundColor', foregroundColor))
      ..add(ColorProperty('accentColor', accentColor))
      ..add(
        ColorProperty(
          'secondaryForegroundColor',
          secondaryForegroundColor,
          defaultValue: null,
        ),
      )
      ..add(ColorProperty('onAccentColor', onAccentColor))
      ..add(ColorProperty('destructiveColor', destructiveColor))
      ..add(
        DiagnosticsProperty<bool>(
          'reduceMotion',
          reduceMotion,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<bool>(
          'reduceTransparency',
          reduceTransparency,
          defaultValue: null,
        ),
      );
  }
}

/// Provides [LiquidGlassThemeData] to descendant liquid-glass widgets.
///
/// When [darkData] is given, it is used whenever the ambient brightness
/// (Material or Cupertino theme, then platform brightness) is dark.
///
/// Dialogs, sheets and menus shown with this package's `show*` functions
/// capture the theme from the calling context, so placing this widget below
/// `MaterialApp`/`CupertinoApp` (for example in `home` or `builder`) works.
class LiquidGlassTheme extends InheritedTheme {
  /// Creates a liquid-glass theme.
  const LiquidGlassTheme({
    super.key,
    required this.data,
    this.darkData,
    required super.child,
  });

  /// Theme used for light brightness (and dark when [darkData] is null).
  final LiquidGlassThemeData data;

  /// Optional theme used for dark brightness.
  final LiquidGlassThemeData? darkData;

  /// The ambient brightness used to pick light/dark defaults.
  static Brightness brightnessOf(BuildContext context) {
    return CupertinoTheme.maybeBrightnessOf(context) ??
        MediaQuery.maybePlatformBrightnessOf(context) ??
        Brightness.light;
  }

  /// Returns the effective theme data for [context].
  ///
  /// Lookup order: nearest [LiquidGlassTheme], then a
  /// [LiquidGlassThemeData] extension on the Material [Theme], then
  /// [LiquidGlassThemeData.fallback].
  static LiquidGlassThemeData of(BuildContext context) {
    final LiquidGlassTheme? inherited = context
        .dependOnInheritedWidgetOfExactType<LiquidGlassTheme>();
    final Brightness brightness = brightnessOf(context);
    if (inherited != null) {
      final LiquidGlassThemeData? dark = inherited.darkData;
      return brightness == Brightness.dark && dark != null
          ? dark
          : inherited.data;
    }
    final LiquidGlassThemeData? extension = Theme.of(
      context,
    ).extension<LiquidGlassThemeData>();
    return extension ?? LiquidGlassThemeData.fallback(brightness);
  }

  /// Whether motion should be reduced for [context], combining the theme
  /// override with `MediaQueryData.disableAnimations`.
  static bool reduceMotionOf(BuildContext context) {
    return of(context).reduceMotion ??
        MediaQuery.maybeDisableAnimationsOf(context) ??
        false;
  }

  /// Whether the opaque fallback should be used for [context], combining the
  /// theme override with `MediaQueryData.highContrast`.
  static bool reduceTransparencyOf(BuildContext context) {
    return of(context).reduceTransparency ??
        MediaQuery.maybeHighContrastOf(context) ??
        false;
  }

  /// Whether the platform requested high contrast.
  static bool highContrastOf(BuildContext context) =>
      MediaQuery.maybeHighContrastOf(context) ?? false;

  @override
  Widget wrap(BuildContext context, Widget child) {
    return LiquidGlassTheme(data: data, darkData: darkData, child: child);
  }

  @override
  bool updateShouldNotify(LiquidGlassTheme oldWidget) =>
      data != oldWidget.data || darkData != oldWidget.darkData;
}
