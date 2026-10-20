import 'package:flutter/material.dart';
import 'package:liquid_glass_ui/liquid_glass_ui.dart';

/// Motion presets offered by the configurator.
enum MotionPreset { fluid, snappy, bouncy, gentle, curveOnly }

/// Live, app-wide glass configuration edited on the settings page.
class DemoConfig extends ChangeNotifier {
  double blur = 12;
  double opacity = 0.16;
  Color tint = Colors.white;
  double borderWidth = 1;
  double borderOpacity = 0.45;
  double cornerRadius = 22;
  bool highlights = true;
  bool refraction = true;
  double refractionStrength = 0.35;
  LiquidGlassQuality quality = LiquidGlassQuality.standard;
  MotionPreset motion = MotionPreset.fluid;
  double durationMs = 450;
  ThemeMode themeMode = ThemeMode.light;
  bool reduceMotion = false;
  bool reduceTransparency = false;
  LiquidGlassDropShape dropShape = LiquidGlassDropShape.capsule;
  double dropWidth = 140;
  double dropHeight = 56;
  double dropMagnification = 1.15;
  Color dropShadow = const Color(0x29000000);
  Color accent = const Color(0xFF0A84FF);
  bool perTabColors = false;

  /// Selected color of each navigation tab when [perTabColors] is on.
  static const List<Color> tabColors = <Color>[
    Color(0xFF0A84FF),
    Color(0xFF30D158),
    Color(0xFFFF9F0A),
    Color(0xFFFF375F),
  ];

  /// Creates the config, optionally starting from a named preset (used by
  /// `--dart-define=DEMO_PRESET=...` to capture screenshots).
  DemoConfig({String preset = const String.fromEnvironment('DEMO_PRESET')}) {
    switch (preset) {
      case 'circle':
        dropShape = LiquidGlassDropShape.circle;
        dropMagnification = 1.3;
        dropShadow = const Color(0x660A84FF);
      case 'dark':
        themeMode = ThemeMode.dark;
      case 'tinted':
        tint = const Color(0xFF0A84FF);
        opacity = 0.22;
        dropShape = LiquidGlassDropShape.roundedRectangle;
        dropShadow = const Color(0x55FF375F);
      case 'colors':
        accent = const Color(0xFFFF375F);
        perTabColors = true;
    }
  }

  LiquidGlassDropStyle get dropStyle => LiquidGlassDropStyle(
    shape: dropShape,
    size: Size(dropWidth, dropHeight),
    magnification: dropMagnification,
    shadowColor: dropShadow,
    borderRadius: BorderRadius.circular(14),
  );

  /// Applies [change] and notifies listeners.
  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  /// Restores the defaults.
  void reset() => update(() {
    blur = 12;
    opacity = 0.16;
    tint = Colors.white;
    borderWidth = 1;
    borderOpacity = 0.45;
    cornerRadius = 22;
    highlights = true;
    refraction = true;
    refractionStrength = 0.35;
    quality = LiquidGlassQuality.standard;
    motion = MotionPreset.fluid;
    durationMs = 450;
    themeMode = ThemeMode.light;
    reduceMotion = false;
    reduceTransparency = false;
    dropShape = LiquidGlassDropShape.capsule;
    dropWidth = 140;
    dropHeight = 56;
    dropMagnification = 1.15;
    dropShadow = const Color(0x29000000);
    accent = const Color(0xFF0A84FF);
    perTabColors = false;
  });

  LiquidGlassAnimationConfig get animation {
    final Duration duration = Duration(milliseconds: durationMs.round());
    final LiquidGlassAnimationConfig preset = switch (motion) {
      MotionPreset.fluid => LiquidGlassAnimationConfig.fluid,
      MotionPreset.snappy => LiquidGlassAnimationConfig.snappy,
      MotionPreset.bouncy => LiquidGlassAnimationConfig.bouncy,
      MotionPreset.gentle => LiquidGlassAnimationConfig.gentle,
      MotionPreset.curveOnly => const LiquidGlassAnimationConfig(
        curve: Curves.easeInOutCubic,
      ),
    };
    return preset.copyWith(duration: duration);
  }

  LiquidGlassThemeData themeFor(Brightness brightness) {
    final bool dark = brightness == Brightness.dark;
    final LiquidGlassStyle base = dark
        ? const LiquidGlassStyle.dark()
        : const LiquidGlassStyle();
    final Color effectiveTint = dark && tint == Colors.white
        ? base.tintColor
        : tint;
    final LiquidGlassStyle style = base.copyWith(
      blur: blur,
      opacity: opacity,
      tintColor: effectiveTint,
      borderWidth: borderWidth,
      borderColor: Colors.white.withValues(
        alpha: borderOpacity * (dark ? 0.5 : 1),
      ),
      borderRadius: BorderRadius.circular(cornerRadius),
      enableHighlights: highlights,
      enableRefraction: refraction,
      refractionStrength: refractionStrength,
    );
    final LiquidGlassThemeData defaults = dark
        ? LiquidGlassThemeData.dark(accentColor: accent)
        : LiquidGlassThemeData.light(accentColor: accent);
    return defaults.copyWith(
      style: style,
      quality: quality,
      animation: animation,
      overlayAnimation: animation,
      reduceMotion: reduceMotion,
      reduceTransparency: reduceTransparency,
    );
  }
}

/// Provides the [DemoConfig] to the widget tree.
class DemoConfigScope extends InheritedNotifier<DemoConfig> {
  const DemoConfigScope({
    super.key,
    required DemoConfig config,
    required super.child,
  }) : super(notifier: config);

  static DemoConfig of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DemoConfigScope>()!.notifier!;
}
