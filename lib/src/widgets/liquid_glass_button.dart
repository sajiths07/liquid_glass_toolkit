import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../animation/animation_config.dart';
import '../core/glass_quality.dart';
import '../core/glass_style.dart';
import '../theme/liquid_glass_theme.dart';
import 'glass_pressable.dart';
import 'liquid_glass_surface.dart';

/// Derives the pressed / focused appearance of an interactive surface.
LiquidGlassStyle interactiveGlassStyle(
  LiquidGlassStyle base,
  GlassInteractionState state,
  Color accent,
) {
  final double p = state.press.clamp(0.0, 1.0);
  final double hover = state.hovered ? 0.35 : 0;
  final double lift = math.max(p, hover);
  LiquidGlassStyle style = base;
  if (lift > 0) {
    style = LiquidGlassStyle.lerp(
      base,
      base.copyWith(
        opacity: math.min(1, base.opacity + 0.14),
        highlightOpacity: math.min(1, base.highlightOpacity + 0.3),
        specularIntensity: math.min(1, base.specularIntensity + 0.35),
        rimLightIntensity: math.min(1, base.rimLightIntensity + 0.2),
      ),
      lift,
    );
  }
  if (state.focused) {
    style = style.copyWith(
      borderColor: accent,
      borderWidth: math.max(2, style.borderWidth),
    );
  }
  return style;
}

/// A pill-shaped glass button with spring press feedback.
///
/// Meets a 44x44 minimum touch target, supports keyboard activation
/// (Enter/Space), focus highlight, hover feedback and button semantics.
/// Set [prominent] for an accent-tinted primary action.
class LiquidGlassButton extends StatelessWidget {
  /// Creates a glass button.
  const LiquidGlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.onLongPress,
    this.prominent = false,
    this.style,
    this.quality,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.animation,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.foregroundColor,
    this.color,
  });

  /// Called when the button is activated. `null` disables the button.
  final VoidCallback? onPressed;

  /// Called on long press.
  final VoidCallback? onLongPress;

  /// Text and icon color. Defaults to the theme `onAccentColor` when
  /// [prominent], otherwise the theme `foregroundColor`.
  final Color? foregroundColor;

  /// Fill color of a [prominent] button and the keyboard focus ring.
  /// Defaults to the theme `accentColor`.
  final Color? color;

  /// Button content, usually a [Text] or a [Row] of icon and text.
  final Widget child;

  /// Tints the glass with the theme accent color and uses white content.
  final bool prominent;

  /// Glass style. Defaults to the theme style with pill-shaped corners.
  final LiquidGlassStyle? style;

  /// Rendering quality.
  final LiquidGlassQuality? quality;

  /// Padding around [child].
  final EdgeInsetsGeometry padding;

  /// Overrides the theme `interactionAnimation` used for press feedback.
  final LiquidGlassAnimationConfig? animation;

  /// Semantic label when [child] has no readable text.
  final String? semanticLabel;

  /// Focus node.
  final FocusNode? focusNode;

  /// Whether to autofocus.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final LiquidGlassThemeData theme = LiquidGlassTheme.of(context);
    LiquidGlassStyle base =
        style ?? theme.style.copyWith(borderRadius: BorderRadius.circular(999));
    final Color accent = color ?? theme.accentColor;
    Color foreground = foregroundColor ?? theme.foregroundColor;
    if (prominent) {
      base = base.copyWith(
        tintColor: accent,
        opacity: math.max(base.opacity, 0.82),
      );
      foreground = foregroundColor ?? theme.onAccentColor;
    }
    return GlassPressable(
      onPressed: onPressed,
      onLongPress: onLongPress,
      animation: animation,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
      autofocus: autofocus,
      pressScale: 0.05,
      child: child,
      builder:
          (BuildContext context, GlassInteractionState state, Widget? child) {
            return ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              child: LiquidGlassSurface(
                style: interactiveGlassStyle(base, state, accent),
                quality: quality,
                padding: padding,
                foregroundColor: state.enabled
                    ? foreground
                    : foreground.withValues(alpha: foreground.a * 0.4),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  child: Center(widthFactor: 1, heightFactor: 1, child: child),
                ),
              ),
            );
          },
    );
  }
}

/// A circular glass button for an icon.
///
/// Always provide [semanticLabel] so screen readers can announce the action.
class LiquidGlassIconButton extends StatelessWidget {
  /// Creates a glass icon button.
  const LiquidGlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.size = 44,
    this.iconSize = 22,
    this.style,
    this.quality,
    this.animation,
    this.focusNode,
    this.autofocus = false,
    this.color,
    this.focusColor,
    this.borderRadius,
  });

  /// Corner radius. Defaults to a circle (`size / 2`).
  final BorderRadius? borderRadius;

  /// Icon color. Defaults to the theme `foregroundColor`.
  final Color? color;

  /// Keyboard focus ring color. Defaults to the theme `accentColor`.
  final Color? focusColor;

  /// The icon widget, typically an [Icon].
  final Widget icon;

  /// Called when activated. `null` disables the button.
  final VoidCallback? onPressed;

  /// Label announced by screen readers.
  final String semanticLabel;

  /// Diameter of the button. Touch target is never smaller than 44.
  final double size;

  /// Icon size.
  final double iconSize;

  /// Glass style. Defaults to the theme style with circular corners.
  final LiquidGlassStyle? style;

  /// Rendering quality.
  final LiquidGlassQuality? quality;

  /// Overrides the theme `interactionAnimation`.
  final LiquidGlassAnimationConfig? animation;

  /// Focus node.
  final FocusNode? focusNode;

  /// Whether to autofocus.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final LiquidGlassThemeData theme = LiquidGlassTheme.of(context);
    final LiquidGlassStyle base = (style ?? theme.style).copyWith(
      borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
    );
    final double target = math.max(size, 44);
    return GlassPressable(
      onPressed: onPressed,
      animation: animation,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
      autofocus: autofocus,
      pressScale: 0.1,
      builder: (BuildContext context, GlassInteractionState state, _) {
        final Color c = color ?? theme.foregroundColor;
        final Color fg = state.enabled ? c : c.withValues(alpha: c.a * 0.4);
        return SizedBox(
          width: target,
          height: target,
          child: Center(
            child: SizedBox(
              width: size,
              height: size,
              child: LiquidGlassSurface(
                style: interactiveGlassStyle(
                  base,
                  state,
                  focusColor ?? theme.accentColor,
                ),
                quality: quality,
                foregroundColor: fg,
                child: Center(
                  child: IconTheme.merge(
                    data: IconThemeData(size: iconSize),
                    child: ExcludeSemantics(child: icon),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A padded glass card. Becomes pressable (with subtle spring feedback and
/// button semantics) when [onTap] is provided.
class LiquidGlassCard extends StatelessWidget {
  /// Creates a glass card.
  const LiquidGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.style,
    this.quality,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius,
    this.semanticLabel,
    this.animation,
    this.foregroundColor,
    this.focusColor,
  });

  /// Card content.
  final Widget child;

  /// Default text and icon color of [child]. Defaults to the theme
  /// `foregroundColor`.
  final Color? foregroundColor;

  /// Keyboard focus ring color. Defaults to the theme `accentColor`.
  final Color? focusColor;

  /// Makes the card interactive.
  final VoidCallback? onTap;

  /// Long-press callback (only used when [onTap] is non-null).
  final VoidCallback? onLongPress;

  /// Glass style. Defaults to the theme style.
  final LiquidGlassStyle? style;

  /// Rendering quality.
  final LiquidGlassQuality? quality;

  /// Inner padding.
  final EdgeInsetsGeometry padding;

  /// Outer margin.
  final EdgeInsetsGeometry? margin;

  /// Corner radius override.
  final BorderRadiusGeometry? borderRadius;

  /// Semantic label for interactive cards.
  final String? semanticLabel;

  /// Overrides the theme `interactionAnimation`.
  final LiquidGlassAnimationConfig? animation;

  @override
  Widget build(BuildContext context) {
    Widget card;
    if (onTap == null) {
      card = LiquidGlassSurface(
        style: style,
        quality: quality,
        padding: padding,
        borderRadius: borderRadius,
        foregroundColor: foregroundColor,
        child: child,
      );
    } else {
      final LiquidGlassThemeData theme = LiquidGlassTheme.of(context);
      final LiquidGlassStyle base = style ?? theme.style;
      card = GlassPressable(
        onPressed: onTap,
        onLongPress: onLongPress,
        animation: animation,
        semanticLabel: semanticLabel,
        pressScale: 0.025,
        child: child,
        builder:
            (
              BuildContext context,
              GlassInteractionState state,
              Widget? child,
            ) => LiquidGlassSurface(
              style: interactiveGlassStyle(
                base,
                state,
                focusColor ?? theme.accentColor,
              ),
              quality: quality,
              padding: padding,
              borderRadius: borderRadius,
              foregroundColor: foregroundColor,
              child: child,
            ),
      );
    }
    if (margin != null) card = Padding(padding: margin!, child: card);
    return card;
  }
}
