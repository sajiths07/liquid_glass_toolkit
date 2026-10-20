import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../core/glass_style.dart';

/// Applies the refraction shader (plus an optional blur/color [baseFilter])
/// to the backdrop behind its child.
///
/// The backdrop texture handed to a backdrop shader covers the whole render
/// target, so the shader needs to know where this surface is on screen. The
/// global rectangle is recomputed every time this object paints, and
/// [repaint] (typically the enclosing scroll position) forces a repaint when
/// the surface moves without repainting itself.
class RefractiveBackdrop extends SingleChildRenderObjectWidget {
  /// Creates a refractive backdrop.
  const RefractiveBackdrop({
    super.key,
    required this.shader,
    required this.style,
    required this.devicePixelRatio,
    required this.presence,
    this.baseFilter,
    this.repaint,
    super.child,
  });

  /// Per-surface instance of the refraction program.
  final ui.FragmentShader shader;

  /// Resolved style (radii, thickness, strength, dispersion).
  final LiquidGlassStyle style;

  /// Device pixel ratio of the view.
  final double devicePixelRatio;

  /// Presence factor (0..1) scaling the refraction strength.
  final double presence;

  /// Blur / color filter applied after refraction.
  final ui.ImageFilter? baseFilter;

  /// Triggers a repaint when notified.
  final Listenable? repaint;

  @override
  RenderRefractiveBackdrop createRenderObject(BuildContext context) {
    return RenderRefractiveBackdrop(
      shader: shader,
      style: style,
      devicePixelRatio: devicePixelRatio,
      presence: presence,
      baseFilter: baseFilter,
      repaint: repaint,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderRefractiveBackdrop renderObject,
  ) {
    renderObject
      ..shader = shader
      ..style = style
      ..devicePixelRatio = devicePixelRatio
      ..presence = presence
      ..baseFilter = baseFilter
      ..repaint = repaint;
  }
}

/// Render object for [RefractiveBackdrop].
class RenderRefractiveBackdrop extends RenderProxyBox {
  /// Creates the render object.
  RenderRefractiveBackdrop({
    required ui.FragmentShader shader,
    required LiquidGlassStyle style,
    required double devicePixelRatio,
    required double presence,
    ui.ImageFilter? baseFilter,
    Listenable? repaint,
  }) : _shader = shader,
       _style = style,
       _devicePixelRatio = devicePixelRatio,
       _presence = presence,
       _baseFilter = baseFilter,
       _repaint = repaint;

  /// Set when creating a shader filter failed; disables refraction for the
  /// rest of the process instead of failing every frame.
  static bool _disabled = false;

  /// Whether refraction was disabled after a runtime failure.
  static bool get debugRefractionDisabled => _disabled;

  ui.FragmentShader _shader;
  set shader(ui.FragmentShader value) {
    if (identical(value, _shader)) return;
    _shader = value;
    markNeedsPaint();
  }

  LiquidGlassStyle _style;
  set style(LiquidGlassStyle value) {
    if (value == _style) return;
    _style = value;
    markNeedsPaint();
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  double _presence;
  set presence(double value) {
    if (value == _presence) return;
    _presence = value;
    markNeedsPaint();
  }

  ui.ImageFilter? _baseFilter;
  set baseFilter(ui.ImageFilter? value) {
    if (value == _baseFilter) return;
    _baseFilter = value;
    markNeedsPaint();
  }

  Listenable? _repaint;
  set repaint(Listenable? value) {
    if (identical(value, _repaint)) return;
    if (attached) _repaint?.removeListener(markNeedsPaint);
    _repaint = value;
    if (attached) _repaint?.addListener(markNeedsPaint);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _repaint?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _repaint?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  BackdropFilterLayer? get layer => super.layer as BackdropFilterLayer?;

  ui.ImageFilter? _buildFilter() {
    if (_disabled) return _baseFilter;
    final Rect global = MatrixUtils.transformRect(
      getTransformTo(null),
      Offset.zero & size,
    );
    final double scale = size.width > 0 ? global.width / size.width : 1;
    final double px = _devicePixelRatio;
    double radius(Radius r) => math.min(r.x, r.y) * scale * px;
    final BorderRadius r = _style.borderRadius;
    _shader
      ..setFloat(2, global.left * px)
      ..setFloat(3, global.top * px)
      ..setFloat(4, global.width * px)
      ..setFloat(5, global.height * px)
      ..setFloat(6, radius(r.topLeft))
      ..setFloat(7, radius(r.topRight))
      ..setFloat(8, radius(r.bottomRight))
      ..setFloat(9, radius(r.bottomLeft))
      ..setFloat(10, _style.thickness * scale * px)
      ..setFloat(11, _style.refractionStrength * _presence)
      ..setFloat(12, _style.dispersion * _presence);
    try {
      final ui.ImageFilter refraction = ui.ImageFilter.shader(_shader);
      final ui.ImageFilter? base = _baseFilter;
      return base == null
          ? refraction
          : ui.ImageFilter.compose(outer: base, inner: refraction);
    } on Object catch (error, stack) {
      _disabled = true;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'liquid_glass_ui',
          context: ErrorDescription(
            'while creating the refraction filter; premium refraction is '
            'disabled and surfaces fall back to standard quality',
          ),
        ),
      );
      return _baseFilter;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      layer = null;
      return;
    }
    final ui.ImageFilter? filter = _buildFilter();
    if (filter == null) {
      layer = null;
      super.paint(context, offset);
      return;
    }
    layer ??= BackdropFilterLayer();
    layer!
      ..filter = filter
      ..blendMode = BlendMode.srcOver;
    context.pushLayer(layer!, super.paint, offset);
  }
}
