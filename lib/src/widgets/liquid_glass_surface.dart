import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../animation/glass_presence.dart';
import '../core/glass_quality.dart';
import '../core/glass_style.dart';
import '../rendering/backdrop_filters.dart';
import '../rendering/glass_painters.dart';
import '../rendering/refractive_backdrop.dart';
import '../shaders/liquid_glass_shaders.dart';
import '../theme/liquid_glass_theme.dart';

/// The fundamental liquid-glass building block: a rounded pane that blurs,
/// tints, lights and (on supporting renderers) refracts whatever is painted
/// behind it, then paints [child] on top.
///
/// Appearance comes from [style] or, when null, from the ambient
/// [LiquidGlassTheme]. Rendering cost is governed by [quality]. Accessibility
/// preferences are applied automatically:
///
/// * Reduced transparency (or platform high contrast, unless overridden in
///   the theme) replaces the glass with an opaque fill and disables blur.
/// * High contrast strengthens the border.
///
/// Text and icons inside default to [LiquidGlassThemeData.foregroundColor].
///
/// The surface sizes itself to its child (plus [padding]). Wrap it in a
/// [SizedBox] or [ConstrainedBox] for a fixed size.
class LiquidGlassSurface extends StatefulWidget {
  /// Creates a glass surface.
  const LiquidGlassSurface({
    super.key,
    this.child,
    this.style,
    this.quality,
    this.borderRadius,
    this.padding,
    this.foregroundColor,
  });

  /// Content painted above the glass.
  final Widget? child;

  /// Glass appearance. Replaces the theme style entirely; derive from
  /// `LiquidGlassTheme.of(context).style.copyWith(...)` to tweak a few
  /// values.
  final LiquidGlassStyle? style;

  /// Rendering quality. Defaults to the theme quality.
  final LiquidGlassQuality? quality;

  /// Overrides [LiquidGlassStyle.borderRadius]. Directional radii are
  /// resolved with the ambient [Directionality].
  final BorderRadiusGeometry? borderRadius;

  /// Padding between the glass edge and [child].
  final EdgeInsetsGeometry? padding;

  /// Overrides the default text and icon color inside the surface.
  final Color? foregroundColor;

  @override
  State<LiquidGlassSurface> createState() => _LiquidGlassSurfaceState();
}

class _LiquidGlassSurfaceState extends State<LiquidGlassSurface> {
  ui.FragmentShader? _lightingShader;
  ui.FragmentShader? _refractionShader;
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    LiquidGlassShaders.status.addListener(_onShaderStatusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition = Scrollable.maybeOf(context)?.position;
  }

  void _onShaderStatusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LiquidGlassShaders.status.removeListener(_onShaderStatusChanged);
    _lightingShader?.dispose();
    _refractionShader?.dispose();
    super.dispose();
  }

  ui.FragmentShader? _obtainLightingShader() {
    final ui.FragmentProgram? program = LiquidGlassShaders.lightingProgram;
    if (program == null) return null;
    return _lightingShader ??= program.fragmentShader();
  }

  ui.FragmentShader? _obtainRefractionShader() {
    if (!LiquidGlassShaders.supportsRefraction ||
        RenderRefractiveBackdrop.debugRefractionDisabled) {
      return null;
    }
    return _refractionShader ??= LiquidGlassShaders.refractionProgram!
        .fragmentShader();
  }

  @override
  Widget build(BuildContext context) {
    final LiquidGlassThemeData theme = LiquidGlassTheme.of(context);
    final double presence = LiquidGlassPresence.of(context);
    final Color foreground = widget.foregroundColor ?? theme.foregroundColor;

    LiquidGlassStyle style = widget.style ?? theme.style;
    final BorderRadiusGeometry? radius = widget.borderRadius;
    if (radius != null) {
      style = style.copyWith(
        borderRadius: radius.resolve(Directionality.maybeOf(context)),
      );
    }
    style = style.sanitized();
    LiquidGlassQuality quality = widget.quality ?? theme.quality;
    if (LiquidGlassTheme.reduceTransparencyOf(context)) {
      style = style.withReducedTransparency(theme.opaqueSurfaceColor);
      quality = LiquidGlassQuality.minimal;
    }
    if (LiquidGlassTheme.highContrastOf(context)) {
      style = style.withHighContrast(foreground);
    }

    if (quality != LiquidGlassQuality.minimal &&
        LiquidGlassShaders.status.value == LiquidGlassShaderStatus.notLoaded) {
      unawaited(LiquidGlassShaders.ensureLoaded());
    }

    Widget content = widget.child ?? const SizedBox.shrink();
    if (widget.padding != null) {
      content = Padding(padding: widget.padding!, child: content);
    }
    content = IconTheme.merge(
      data: IconThemeData(color: foreground),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: foreground),
        child: content,
      ),
    );
    if (presence < 1) {
      content = Opacity(opacity: presence, child: content);
    }
    content = LiquidGlassPresence(value: 1, child: content);

    Widget glass = CustomPaint(
      painter: GlassBodyPainter(
        style: style,
        quality: quality,
        presence: presence,
        lightingShader: quality == LiquidGlassQuality.minimal
            ? null
            : _obtainLightingShader(),
      ),
      child: content,
    );

    final ui.ImageFilter? baseFilter = buildGlassBackdropFilter(
      style,
      quality,
      presence: presence,
    );
    final ui.FragmentShader? refraction =
        quality == LiquidGlassQuality.premium &&
            style.enableRefraction &&
            style.refractionStrength > 0
        ? _obtainRefractionShader()
        : null;
    if (refraction != null) {
      glass = RefractiveBackdrop(
        shader: refraction,
        style: style,
        devicePixelRatio: MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
        presence: presence,
        baseFilter: baseFilter,
        repaint: _scrollPosition,
        child: glass,
      );
    } else if (baseFilter != null) {
      glass = BackdropFilter(filter: baseFilter, child: glass);
    }

    glass = ClipRRect(borderRadius: style.borderRadius, child: glass);

    if (GlassShadowPainter.isVisible(style, presence)) {
      glass = CustomPaint(
        painter: GlassShadowPainter(style: style, presence: presence),
        child: glass,
      );
    }
    return glass;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      EnumProperty<LiquidGlassShaderStatus>(
        'shaders',
        LiquidGlassShaders.status.value,
      ),
    );
  }
}
