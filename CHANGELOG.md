# Changelog

## 1.0.0

First release as `liquid_glass_widget`, previously published as
`liquid_glass_ui` (0.0.1 to 0.4.0). A complete liquid glass framework; the
0.x `LiquidGlassContainer` API is kept. To migrate, replace
`liquid_glass_ui` with `liquid_glass_widget` in `pubspec.yaml` and imports.

### Added

*   `LiquidGlassStyle` with full control over blur, tint, saturation,
    contrast, brightness, borders, rim light, specular highlights,
    reflections, refraction and shadows, plus `clear`, `frosted`, `tinted`
    and `dark` presets.
*   `LiquidGlassQuality` (`minimal`, `standard`, `premium`) with distinct
    rendering paths.
*   GPU lighting shader and an Impeller edge-refraction shader with automatic
    fallbacks (`LiquidGlassShaders`).
*   `LiquidGlassTheme` / `LiquidGlassThemeData` (also usable as a
    `ThemeExtension`) with light and dark defaults.
*   `LiquidGlassAnimationConfig` with duration, curve, spring and reduced
    motion handling, and `fluid`, `snappy`, `bouncy` and `gentle` presets.
*   Widgets: `LiquidGlassSurface`, `AnimatedLiquidGlassSurface`,
    `LiquidGlassCard`, `LiquidGlassButton`, `LiquidGlassIconButton`,
    `LiquidGlassSwitch`, `LiquidGlassSlider`, `LiquidGlassSegmentedControl`
    and `LiquidGlassTextField`.
*   Navigation: `LiquidGlassScaffold`, `LiquidGlassAppBar`,
    `LiquidGlassBackButton`, `LiquidGlassNavigationBar`,
    `LiquidGlassPageRoute` and `LiquidGlassPageTransitionsBuilder`.
*   The navigation bar is a floating capsule with environment reflections
    (top gloss, inner rim, bottom light bounce), a clear water-drop
    indicator that magnifies the content behind it, glides and can be
    dragged, a `maxWidth` cap with centering, and fixed icon and label slots
    so destinations stay aligned.
*   `LiquidGlassDropStyle` and `LiquidGlassDropShape` to customize the
    water drop: size, shape (capsule, circle, rounded rectangle),
    magnification, tint, border, highlight color, optics intensity, shadow
    color/blur/offset and liquid stretch.
*   Color cascade (item, then widget, then theme). New theme colors:
    `secondaryForegroundColor`, `onAccentColor` and `destructiveColor`
    (the `light()`/`dark()` factories also accept `foregroundColor`).
    Per-item colors on `LiquidGlassNavigationDestination`,
    `LiquidGlassMenuItem` and segmented-control segments; widget colors on
    the navigation bar, segmented control, buttons, card, switch, slider,
    text field, app bar, back button, dialog, sheet and menu.
*   `borderRadius` on `LiquidGlassNavigationBar`,
    `LiquidGlassSegmentedControl` and `LiquidGlassIconButton`, which were
    previously always pill or circle shaped.
*   Overlays: `showLiquidGlassDialog`, `LiquidGlassDialog`,
    `showLiquidGlassSheet`, `showLiquidGlassMenu`, `LiquidGlassMenuButton`
    and `showLiquidGlassMorph` (liquid morph from the trigger).
*   `LiquidGlassAppear` and `LiquidGlassTransition` for fades that keep
    backdrop blur intact.
*   Accessibility: semantics, keyboard support, 44 px touch targets, text
    scaling, reduced motion, reduced transparency and high contrast.
*   New example app with a live configuration screen.
*   Unit, widget, golden and shader compilation tests.

### Changed

*   `LiquidGlassContainer` now renders through the new glass engine
    (gradient border, highlights and a soft shadow). It accepts optional
    `style` and `quality` parameters; existing parameters are unchanged.
*   Text and icons inside glass default to the theme foreground color.
*   Minimum SDK is now Dart 3.8 / Flutter 3.32.

## 0.4.0 (as liquid_glass_ui)

*   Added a preview screenshot to the `README.md` for better visibility on pub.dev and GitHub.
*   Pushed all local changes to the remote repository to resolve `pub.dev` analysis issues.

## 0.3.0

*   Updated the `homepage` URL to the correct GitHub repository.

## 0.2.0

*   Added a new example showcasing macOS-style widgets (Weather, Calendar, Clock).
*   Added support for custom background images in the example.
*   Enabled macOS desktop support for the example application.
*   Added a screenshots directory with a preview image for the package.

## 0.1.0

*   Improved pub.dev score by: 
    *   Adding comprehensive Dartdoc comments to `LiquidGlassContainer` and its members.
    *   Resolving `withOpacity` deprecation warnings in `lib/widgets/liquid_glass_container.dart` and `example/lib/beautiful_liquid_example.dart`.
    *   Fixing formatting issues (`dart format .`).
    *   Updating `example/test/widget_test.dart` to reflect the new example structure and fix the 'MyApp' error.
*   Created a beautiful new music player UI example in `example/lib/beautiful_liquid_example.dart`.
*   Updated `example/lib/main.dart` to showcase the new beautiful example.
*   Changed the background of the example app to a solid black color for better visibility.

## 0.0.1

*   Initial release of the Liquid Glass UI package. 