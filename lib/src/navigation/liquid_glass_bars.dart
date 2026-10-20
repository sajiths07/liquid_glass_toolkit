import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../animation/animation_config.dart';
import '../core/glass_drop_style.dart';
import '../core/glass_quality.dart';
import '../core/glass_style.dart';
import '../rendering/glass_painters.dart';
import '../theme/liquid_glass_theme.dart';
import '../widgets/glass_selector.dart';
import '../widgets/liquid_glass_button.dart';
import '../widgets/liquid_glass_surface.dart';

/// Localized "Back" label, falling back to English when no Material or
/// Cupertino localizations are present.
String glassBackLabel(BuildContext context) {
  final MaterialLocalizations? material =
      Localizations.of<MaterialLocalizations>(context, MaterialLocalizations);
  return material?.backButtonTooltip ?? 'Back';
}

/// Style for controls embedded in another glass surface: no backdrop work
/// (blur and color adjustments would sample the parent glass twice).
LiquidGlassStyle embeddedGlassStyle(LiquidGlassStyle base) => base.copyWith(
  blur: 0,
  saturation: 1,
  brightness: 0,
  contrast: 1,
  shadowBlur: 0,
  shadowOffset: Offset.zero,
  opacity: (base.opacity * 0.8).clamp(0.0, 1.0),
);

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.color, this.rtl);

  final Color color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width, h = size.height;
    final Path path = Path()
      ..moveTo(w * 0.62, h * 0.2)
      ..lineTo(w * 0.32, h * 0.5)
      ..lineTo(w * 0.62, h * 0.8);
    if (rtl) {
      canvas
        ..translate(w, 0)
        ..scale(-1, 1);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) =>
      old.color != color || old.rtl != rtl;
}

/// A glass back button that pops the current route.
class LiquidGlassBackButton extends StatelessWidget {
  /// Creates a back button. [onPressed] defaults to `Navigator.maybePop`.
  const LiquidGlassBackButton({
    super.key,
    this.onPressed,
    this.style,
    this.color,
  });

  /// Overrides the default pop behaviour.
  final VoidCallback? onPressed;

  /// Glass style of the button.
  final LiquidGlassStyle? style;

  /// Chevron color. Defaults to the theme `foregroundColor`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color fg = color ?? LiquidGlassTheme.of(context).foregroundColor;
    final bool rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    return LiquidGlassIconButton(
      semanticLabel: glassBackLabel(context),
      style: style,
      color: fg,
      size: 40,
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      icon: CustomPaint(
        size: const Size.square(22),
        painter: _ChevronPainter(fg, rtl),
      ),
    );
  }
}

/// A full-width glass app bar that content scrolls underneath.
///
/// Includes the top safe-area inset. When [leading] is null and the current
/// route can be popped, a [LiquidGlassBackButton] is shown.
class LiquidGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates an app bar.
  const LiquidGlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions = const <Widget>[],
    this.bottom,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.toolbarHeight = 56,
    this.style,
    this.quality,
    this.foregroundColor,
  });

  /// Color of the title, back button and glass buttons in [leading] and
  /// [actions] that don't set their own color. Defaults to the theme
  /// `foregroundColor`.
  final Color? foregroundColor;

  /// Title, usually a [Text]. Exposed as a header to screen readers.
  final Widget? title;

  /// Widget before the title.
  final Widget? leading;

  /// Widgets after the title.
  final List<Widget> actions;

  /// Optional widget below the toolbar (for example a search field or
  /// segmented control).
  final PreferredSizeWidget? bottom;

  /// Whether to show a back button when possible.
  final bool automaticallyImplyLeading;

  /// Whether to center the title.
  final bool centerTitle;

  /// Height of the toolbar row, excluding [bottom] and the status bar.
  final double toolbarHeight;

  /// Glass style. Defaults to the theme style with square corners and no
  /// border or shadow.
  final LiquidGlassStyle? style;

  /// Rendering quality.
  final LiquidGlassQuality? quality;

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final LiquidGlassThemeData theme = LiquidGlassTheme.of(context);
    final LiquidGlassStyle base =
        style ??
        theme.style.copyWith(
          borderRadius: BorderRadius.zero,
          borderWidth: 0,
          shadowBlur: 0,
          shadowOffset: Offset.zero,
          thickness: 6,
          specularIntensity: 0,
        );
    final double top = MediaQuery.maybePaddingOf(context)?.top ?? 0;
    final bool canPop = ModalRoute.of(context)?.canPop ?? false;
    final Widget? lead =
        leading ??
        (automaticallyImplyLeading && canPop
            ? LiquidGlassBackButton(style: embeddedGlassStyle(theme.style))
            : null);
    final Widget? bottom = this.bottom;
    final Color fg = foregroundColor ?? theme.foregroundColor;
    Widget bar = Semantics(
      container: true,
      explicitChildNodes: true,
      child: LiquidGlassSurface(
        style: base,
        quality: quality,
        child: Padding(
          padding: EdgeInsets.only(top: top),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: toolbarHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: NavigationToolbar(
                    leading: lead,
                    middle: title == null
                        ? null
                        : Semantics(
                            header: true,
                            child: DefaultTextStyle.merge(
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              child: title!,
                            ),
                          ),
                    trailing: actions.isEmpty
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: actions,
                          ),
                    centerMiddle: centerTitle,
                    middleSpacing: 12,
                  ),
                ),
              ),
              ?bottom,
            ],
          ),
        ),
      ),
    );
    if (foregroundColor != null) {
      bar = LiquidGlassTheme(
        data: theme.copyWith(foregroundColor: foregroundColor),
        child: bar,
      );
    }
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: fg.withValues(alpha: fg.a * 0.12),
            width: 0.5,
          ),
        ),
      ),
      child: bar,
    );
  }
}

/// A destination of a [LiquidGlassNavigationBar].
@immutable
class LiquidGlassNavigationDestination {
  /// Creates a destination.
  const LiquidGlassNavigationDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.selectedColor,
    this.unselectedColor,
  });

  /// Icon shown when not selected.
  final Widget icon;

  /// Icon shown when selected. Defaults to [icon].
  final Widget? selectedIcon;

  /// Label text, also used for semantics.
  final String label;

  /// Icon and label color of this destination when selected. Falls back to
  /// [LiquidGlassNavigationBar.selectedColor], then the theme `accentColor`.
  final Color? selectedColor;

  /// Icon and label color of this destination when not selected. Falls back
  /// to [LiquidGlassNavigationBar.unselectedColor], then the theme
  /// `effectiveSecondaryForegroundColor`.
  final Color? unselectedColor;
}

/// A floating, capsule-shaped glass navigation bar with a liquid selection
/// indicator that glides (and can be dragged) between destinations.
///
/// By default the capsule is clearer than other surfaces and carries
/// environment reflections (a top gloss, a bright inner rim and a bottom
/// light bounce); the indicator is a clear glass lens. Reflections are
/// disabled with [showReflections] and are dropped automatically when the
/// platform asks for reduced transparency.
///
/// The capsule is centered and never wider than [maxWidth], so destinations
/// keep a comfortable, evenly spaced position on tablets and desktops.
///
/// Its [preferredSize] excludes the bottom safe-area inset, which the bar
/// adds itself; [LiquidGlassScaffold] accounts for both.
class LiquidGlassNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// Creates a navigation bar.
  const LiquidGlassNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.showLabels = true,
    this.height = 64,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 12),
    this.style,
    this.indicatorStyle,
    this.quality,
    this.animation,
    this.maxWidth = 480,
    this.showReflections = true,
    this.dropStyle = const LiquidGlassDropStyle(),
    this.selectedColor,
    this.unselectedColor,
    this.borderRadius,
  }) : assert(destinations.length >= 2),
       assert(maxWidth > 0);

  /// Corner radius of the capsule. Defaults to a pill (`height / 2`). Use
  /// [LiquidGlassDropStyle.shape] to change the shape of the indicator.
  final BorderRadius? borderRadius;

  /// The destinations, at least two.
  final List<LiquidGlassNavigationDestination> destinations;

  /// Index of the selected destination.
  final int selectedIndex;

  /// Called when the user selects a destination.
  final ValueChanged<int>? onDestinationSelected;

  /// Whether to show text labels under the icons.
  final bool showLabels;

  /// Height of the capsule.
  final double height;

  /// Space around the capsule (the bottom safe-area inset is added).
  final EdgeInsets margin;

  /// Style of the capsule. Defaults to the theme style, pill-shaped.
  final LiquidGlassStyle? style;

  /// Style of the selection indicator.
  final LiquidGlassStyle? indicatorStyle;

  /// Rendering quality of the capsule.
  final LiquidGlassQuality? quality;

  /// Overrides the theme `animation` for indicator movement.
  final LiquidGlassAnimationConfig? animation;

  /// Maximum width of the capsule; it is centered when space is wider.
  final double maxWidth;

  /// Whether to paint environment reflections on the capsule and indicator.
  final bool showReflections;

  /// Look of the clear water drop that marks the selected destination:
  /// size, shape, tint, edge, shadow, magnification and stretch.
  /// [indicatorStyle], when given, replaces the drop's glass material but
  /// the drop still controls size, shape, shadow and optics.
  final LiquidGlassDropStyle dropStyle;

  /// Color of the selected destination's icon and label, unless the
  /// destination sets its own. Defaults to the theme `accentColor`.
  final Color? selectedColor;

  /// Color of unselected icons and labels, unless a destination sets its
  /// own. Defaults to the theme `effectiveSecondaryForegroundColor`.
  final Color? unselectedColor;

  /// Gap between the capsule edge and the indicator.
  static const double _inset = 4;

  @override
  Size get preferredSize => Size.fromHeight(height + margin.vertical);

  @override
  Widget build(BuildContext context) {
    final LiquidGlassThemeData theme = LiquidGlassTheme.of(context);
    final bool dark = LiquidGlassTheme.brightnessOf(context) == Brightness.dark;
    final bool reduceTransparency = LiquidGlassTheme.reduceTransparencyOf(
      context,
    );
    final LiquidGlassQuality effectiveQuality = quality ?? theme.quality;
    final BorderRadius pill = borderRadius ?? BorderRadius.circular(height / 2);
    final LiquidGlassDropStyle drop = dropStyle;

    final LiquidGlassStyle capsule =
        style?.copyWith(borderRadius: pill) ??
        theme.style.copyWith(
          borderRadius: pill,
          blur: theme.style.blur * 0.75,
          opacity: theme.style.opacity * 0.5,
          saturation: math.min(3, theme.style.saturation * 1.25),
          highlightOpacity: math.max(theme.style.highlightOpacity, 0.75),
          rimLightIntensity: math.max(theme.style.rimLightIntensity, 0.85),
          specularIntensity: math.max(theme.style.specularIntensity, 0.55),
          refractionStrength: math.max(theme.style.refractionStrength, 0.5),
          thickness: math.max(theme.style.thickness, 18),
        );
    final LiquidGlassStyle indicator =
        (indicatorStyle ??
                embeddedGlassStyle(capsule).copyWith(
                  tintColor: drop.tintColor,
                  opacity: drop.tintOpacity ?? (dark ? 0.06 : 0.16),
                  borderColor:
                      drop.borderColor ?? Color(dark ? 0x40FFFFFF : 0x73FFFFFF),
                  borderWidth: drop.borderWidth,
                  highlightColor: drop.highlightColor,
                  highlightOpacity: 0.6,
                  rimLightIntensity: 0.8,
                  specularIntensity: 0.25,
                  thickness: 12,
                ))
            .copyWith(
              shadowColor: drop.shadowColor,
              shadowBlur: drop.shadowBlur,
              shadowOffset: drop.shadowOffset,
            );

    final double reflection = !showReflections || reduceTransparency
        ? 0
        : (dark ? 0.55 : 1.0) *
              (effectiveQuality == LiquidGlassQuality.minimal ? 0.6 : 1.0);
    final Color barUnselected =
        unselectedColor ??
        (reduceTransparency && theme.secondaryForegroundColor == null
            ? theme.foregroundColor.withValues(alpha: 0.9)
            : theme.effectiveSecondaryForegroundColor);
    final Color barSelected = selectedColor ?? theme.accentColor;
    final double bottomInset = MediaQuery.maybePaddingOf(context)?.bottom ?? 0;

    return Padding(
      padding: margin.copyWith(bottom: margin.bottom + bottomInset),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox(
            height: height,
            child: LiquidGlassSurface(
              style: capsule,
              quality: quality,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (reflection > 0)
                    CustomPaint(
                      painter: GlassReflectionPainter(
                        borderRadius: pill,
                        intensity: reflection * 0.7,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(_inset),
                    child: GlassSelectorRow(
                      itemCount: destinations.length,
                      selectedIndex: selectedIndex.clamp(
                        0,
                        destinations.length - 1,
                      ),
                      onSelected: onDestinationSelected,
                      animation: animation,
                      indicatorStyle: indicator,
                      indicatorInset: const EdgeInsets.symmetric(horizontal: 2),
                      drop: drop,
                      indicatorForegroundBuilder:
                          reflection > 0 && drop.opticsIntensity > 0
                          ? (BorderRadius radius) => CustomPaint(
                              painter: GlassDropPainter(
                                borderRadius: radius,
                                intensity: reflection * drop.opticsIntensity,
                                lightAlignment: capsule.lightAlignment,
                                color: drop.highlightColor,
                              ),
                            )
                          : null,
                      semanticLabelBuilder: (int i) => destinations[i].label,
                      itemBuilder: (BuildContext context, int i, double s) {
                        final LiquidGlassNavigationDestination d =
                            destinations[i];
                        return _DestinationContent(
                          destination: d,
                          selectedness: s,
                          showLabel: showLabels,
                          color: Color.lerp(
                            d.unselectedColor ?? barUnselected,
                            d.selectedColor ?? barSelected,
                            s,
                          )!,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon and label of one navigation destination, laid out in fixed slots
/// so every destination lines up regardless of icon or label metrics.
class _DestinationContent extends StatelessWidget {
  const _DestinationContent({
    required this.destination,
    required this.selectedness,
    required this.showLabel,
    required this.color,
  });

  final LiquidGlassNavigationDestination destination;
  final double selectedness;
  final bool showLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bool selected = selectedness > 0.5;
    final List<Shadow>? glow = selectedness > 0
        ? <Shadow>[
            Shadow(
              color: Color.fromRGBO(255, 255, 255, 0.55 * selectedness),
              blurRadius: 8,
            ),
          ]
        : null;
    final Widget icon = SizedBox.square(
      dimension: 26,
      child: Center(
        child: IconTheme.merge(
          data: IconThemeData(color: color, size: 24, shadows: glow),
          child: selected
              ? (destination.selectedIcon ?? destination.icon)
              : destination.icon,
        ),
      ),
    );
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            icon,
            if (showLabel) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                destination.label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.3),
                style: TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  letterSpacing: 0.1,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                  shadows: glow,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
