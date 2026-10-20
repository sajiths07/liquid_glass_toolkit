import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../core/glass_quality.dart';
import '../core/glass_style.dart';

Color _scaleAlpha(Color color, double factor) =>
    color.withValues(alpha: (color.a * factor).clamp(0.0, 1.0));

/// Unit vector pointing from the centre of a surface towards the light.
Offset glassLightVector(Alignment alignment) {
  final double len = math.sqrt(
    alignment.x * alignment.x + alignment.y * alignment.y,
  );
  if (len < 1e-6) return const Offset(0, -1);
  return Offset(alignment.x / len, alignment.y / len);
}

/// Paints the drop shadow of a glass surface, excluding the area under the
/// glass itself so the shadow never darkens translucent glass.
class GlassShadowPainter extends CustomPainter {
  /// Creates a shadow painter.
  GlassShadowPainter({required this.style, required this.presence});

  /// Resolved style.
  final LiquidGlassStyle style;

  /// Presence factor (0..1).
  final double presence;

  /// Whether this painter would draw anything.
  static bool isVisible(LiquidGlassStyle style, double presence) =>
      style.shadowColor.a * presence > 0.002 &&
      (style.shadowBlur > 0 || style.shadowOffset != Offset.zero);

  @override
  void paint(Canvas canvas, Size size) {
    if (!isVisible(style, presence) || size.isEmpty) return;
    final RRect shape = style.borderRadius.toRRect(Offset.zero & size);
    final double spread = style.shadowBlur * 2 + style.shadowOffset.distance;
    final Path outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect((Offset.zero & size).inflate(spread + 4))
      ..addRRect(shape);
    canvas
      ..save()
      ..clipPath(outside);
    final Paint paint = Paint()
      ..color = _scaleAlpha(style.shadowColor, presence)
      ..maskFilter = style.shadowBlur > 0
          ? MaskFilter.blur(
              BlurStyle.normal,
              Shadow.convertRadiusToSigma(style.shadowBlur),
            )
          : null;
    canvas
      ..drawRRect(shape.shift(style.shadowOffset), paint)
      ..restore();
  }

  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(GlassShadowPainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.presence != presence;
}

/// Paints environment reflections on top of a glass shape: a glossy sheen
/// over the upper half, a thin bright inner rim along the top edge and a
/// faint light bounce along the bottom edge.
///
/// [intensity] scales every layer (0 disables painting).
class GlassReflectionPainter extends CustomPainter {
  /// Creates a reflection painter.
  GlassReflectionPainter({
    required this.borderRadius,
    required this.intensity,
    this.color = const Color(0xFFFFFFFF),
  });

  /// Shape of the glass.
  final BorderRadius borderRadius;

  /// Overall strength, typically 0..1.
  final double intensity;

  /// Reflected light color.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || intensity <= 0) return;
    final Rect bounds = Offset.zero & size;
    final RRect shape = borderRadius.toRRect(bounds);
    canvas
      ..save()
      ..clipRRect(shape);

    // Gloss: strongest at the top edge, gone by the middle.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.topCenter,
          Offset(bounds.center.dx, bounds.top + size.height * 0.52),
          <Color>[
            _scaleAlpha(color, 0.30 * intensity),
            _scaleAlpha(color, 0.10 * intensity),
            _scaleAlpha(color, 0),
          ],
          const <double>[0, 0.45, 1],
        ),
    );

    // Light bouncing back up from the surface below.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.bottomCenter,
          Offset(bounds.center.dx, bounds.bottom - size.height * 0.35),
          <Color>[_scaleAlpha(color, 0.12 * intensity), _scaleAlpha(color, 0)],
        ),
    );

    // Inner rim catching the light, fading towards the sides and bottom.
    final double w = math.max(1, math.min(1.5, size.shortestSide / 30));
    canvas.drawRRect(
      shape.deflate(w * 1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..shader = ui.Gradient.linear(
          bounds.topCenter,
          bounds.bottomCenter,
          <Color>[
            _scaleAlpha(color, 0.75 * intensity),
            _scaleAlpha(color, 0.05 * intensity),
            _scaleAlpha(color, 0.25 * intensity),
          ],
          const <double>[0, 0.5, 1],
        ),
    );
    canvas.restore();
  }

  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(GlassReflectionPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.intensity != intensity ||
      oldDelegate.color != color;
}

/// Paints the optics of a clear water drop over a (usually magnified)
/// backdrop: a soft refraction rim along the edge, a bright caustic where
/// light focuses near the bottom, a specular highlight towards the light and
/// a thin bright edge.
///
/// [intensity] scales every layer (0 disables painting).
class GlassDropPainter extends CustomPainter {
  /// Creates a water-drop painter.
  GlassDropPainter({
    required this.borderRadius,
    required this.intensity,
    this.lightAlignment = const Alignment(-0.55, -1),
    this.color = const Color(0xFFFFFFFF),
  });

  /// Shape of the drop.
  final BorderRadius borderRadius;

  /// Overall strength, typically 0..1.
  final double intensity;

  /// Direction of the light source.
  final Alignment lightAlignment;

  /// Light color.
  final Color color;

  void _ellipse(Canvas canvas, Offset centre, Size radii, List<Color> colors) {
    if (radii.isEmpty) return;
    canvas
      ..save()
      ..translate(centre.dx, centre.dy)
      ..scale(1, radii.height / radii.width)
      ..drawCircle(
        Offset.zero,
        radii.width,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            radii.width,
            colors,
            colors.length == 2
                ? null
                : List<double>.generate(
                    colors.length,
                    (int i) => i / (colors.length - 1),
                  ),
          ),
      )
      ..restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || intensity <= 0) return;
    final Rect bounds = Offset.zero & size;
    final RRect shape = borderRadius.toRRect(bounds);
    final double s = size.shortestSide;
    final Offset light = glassLightVector(lightAlignment);
    canvas
      ..save()
      ..clipRRect(shape);

    // Volume: a drop is slightly brighter at the top and clear below.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.topCenter,
          bounds.bottomCenter,
          <Color>[
            _scaleAlpha(color, 0.10 * intensity),
            _scaleAlpha(color, 0),
            _scaleAlpha(color, 0.04 * intensity),
          ],
          const <double>[0, 0.55, 1],
        ),
    );

    // Refraction rim: light near the edge is bent away, so the edge reads
    // slightly darker and blurred, like the meniscus of a drop.
    canvas.drawRRect(
      shape.deflate(s * 0.04),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.14
        ..color = Color.fromRGBO(0, 0, 0, 0.10 * intensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.06),
    );

    // Caustic: the drop focuses light on the side away from the source.
    _ellipse(
      canvas,
      Offset(
        bounds.center.dx - light.dx * size.width * 0.18,
        bounds.center.dy - light.dy * size.height * 0.30,
      ),
      Size(size.width * 0.42, size.height * 0.32),
      <Color>[_scaleAlpha(color, 0.30 * intensity), _scaleAlpha(color, 0)],
    );

    // Specular highlight towards the light.
    final Offset spot = Offset(
      bounds.center.dx + light.dx * size.width * 0.34,
      bounds.center.dy + light.dy * size.height * 0.36,
    );
    _ellipse(
      canvas,
      spot,
      Size(math.min(size.width * 0.12, s * 0.4), s * 0.09),
      <Color>[
        _scaleAlpha(color, 0.85 * intensity),
        _scaleAlpha(color, 0.25 * intensity),
        _scaleAlpha(color, 0),
      ],
    );

    // Thin bright edge, strongest facing the light.
    final double w = math.max(1, s / 36);
    canvas.drawRRect(
      shape.deflate(w / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..shader = ui.Gradient.linear(
          bounds.center +
              Offset(light.dx * size.width / 2, light.dy * size.height / 2),
          bounds.center -
              Offset(light.dx * size.width / 2, light.dy * size.height / 2),
          <Color>[
            _scaleAlpha(color, 0.75 * intensity),
            _scaleAlpha(color, 0.10 * intensity),
            _scaleAlpha(color, 0.40 * intensity),
          ],
          const <double>[0, 0.5, 1],
        ),
    );
    canvas.restore();
  }

  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(GlassDropPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.intensity != intensity ||
      oldDelegate.lightAlignment != lightAlignment ||
      oldDelegate.color != color;
}

/// Paints the tint, lighting and border of a glass surface.
///
/// Lighting uses [lightingShader] when provided (standard/premium quality)
/// and otherwise falls back to canvas gradients. Minimal quality always uses
/// a single flat sheen.
class GlassBodyPainter extends CustomPainter {
  /// Creates a body painter.
  GlassBodyPainter({
    required this.style,
    required this.quality,
    required this.presence,
    this.lightingShader,
  });

  /// Resolved style.
  final LiquidGlassStyle style;

  /// Effective quality.
  final LiquidGlassQuality quality;

  /// Presence factor (0..1).
  final double presence;

  /// Per-surface instance of the lighting shader, if loaded.
  final ui.FragmentShader? lightingShader;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final Rect bounds = Offset.zero & size;
    final RRect shape = style.borderRadius.toRRect(bounds);

    final double tintAlpha = style.opacity * presence;
    if (tintAlpha > 0) {
      canvas.drawRRect(
        shape,
        Paint()..color = _scaleAlpha(style.tintColor, tintAlpha),
      );
    }

    final double highlight = style.highlightOpacity * presence;
    if (style.enableHighlights && highlight > 0) {
      if (quality == LiquidGlassQuality.minimal) {
        _paintSheen(canvas, bounds, shape, highlight);
      } else if (lightingShader != null) {
        _paintShaderLighting(canvas, size, highlight);
      } else {
        _paintFallbackLighting(canvas, bounds, shape, highlight);
      }
    }

    if (style.borderWidth > 0 && style.borderColor.a > 0) {
      final double w = style.borderWidth;
      final RRect stroke = shape.deflate(w / 2);
      final Paint border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w;
      if (quality == LiquidGlassQuality.minimal || !style.enableHighlights) {
        border.color = _scaleAlpha(style.borderColor, presence);
      } else {
        final Offset light = glassLightVector(style.lightAlignment);
        border.shader = ui.Gradient.linear(
          bounds.center +
              Offset(light.dx * size.width / 2, light.dy * size.height / 2),
          bounds.center -
              Offset(light.dx * size.width / 2, light.dy * size.height / 2),
          <Color>[
            _scaleAlpha(style.borderColor, presence),
            _scaleAlpha(style.borderColor, presence * 0.35),
            _scaleAlpha(style.borderColor, presence * 0.7),
          ],
          const <double>[0, 0.6, 1],
        );
      }
      canvas.drawRRect(stroke, border);
    }
  }

  void _paintSheen(Canvas canvas, Rect bounds, RRect shape, double highlight) {
    final Paint sheen = Paint()
      ..shader = ui.Gradient.linear(
        bounds.topCenter,
        Offset(bounds.center.dx, bounds.top + bounds.height * 0.55),
        <Color>[
          _scaleAlpha(style.highlightColor, 0.22 * highlight),
          _scaleAlpha(style.highlightColor, 0),
        ],
      );
    canvas.drawRRect(shape, sheen);
  }

  void _paintShaderLighting(Canvas canvas, Size size, double highlight) {
    final ui.FragmentShader shader = lightingShader!;
    final BorderRadius r = style.borderRadius;
    final Offset light = glassLightVector(style.lightAlignment);
    final Color c = style.highlightColor;
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, math.min(r.topLeft.x, r.topLeft.y))
      ..setFloat(3, math.min(r.topRight.x, r.topRight.y))
      ..setFloat(4, math.min(r.bottomRight.x, r.bottomRight.y))
      ..setFloat(5, math.min(r.bottomLeft.x, r.bottomLeft.y))
      ..setFloat(6, light.dx)
      ..setFloat(7, light.dy)
      ..setFloat(8, style.thickness)
      ..setFloat(9, style.rimLightIntensity)
      ..setFloat(10, style.specularIntensity)
      ..setFloat(11, highlight * c.a)
      ..setFloat(12, c.r)
      ..setFloat(13, c.g)
      ..setFloat(14, c.b)
      ..setFloat(15, 1);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  void _paintFallbackLighting(
    Canvas canvas,
    Rect bounds,
    RRect shape,
    double highlight,
  ) {
    final Offset light = glassLightVector(style.lightAlignment);
    final Offset half = Offset(bounds.width / 2, bounds.height / 2);
    final Offset lit =
        bounds.center + Offset(light.dx * half.dx, light.dy * half.dy);
    final Offset unlit =
        bounds.center - Offset(light.dx * half.dx, light.dy * half.dy);

    if (style.rimLightIntensity > 0 && style.thickness > 0) {
      final double band = math.min(
        style.thickness * 0.3,
        shape.shortestSide / 4,
      );
      if (band > 0) {
        final double rim = style.rimLightIntensity * highlight;
        canvas.drawRRect(
          shape.deflate(band / 2),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = band
            ..shader = ui.Gradient.linear(
              lit,
              unlit,
              <Color>[
                _scaleAlpha(style.highlightColor, 0.55 * rim),
                _scaleAlpha(style.highlightColor, 0),
                _scaleAlpha(style.highlightColor, 0.18 * rim),
              ],
              const <double>[0, 0.55, 1],
            ),
        );
      }
    }

    if (style.specularIntensity > 0) {
      final Offset centre =
          bounds.center +
          Offset(light.dx * half.dx * 0.62, light.dy * half.dy * 0.62);
      final double radius = math.max(bounds.width, bounds.height) * 0.55;
      canvas
        ..save()
        ..clipRRect(shape)
        ..drawCircle(
          centre,
          radius,
          Paint()
            ..shader = ui.Gradient.radial(centre, radius, <Color>[
              _scaleAlpha(
                style.highlightColor,
                0.22 * style.specularIntensity * highlight,
              ),
              _scaleAlpha(style.highlightColor, 0),
            ]),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(GlassBodyPainter oldDelegate) =>
      oldDelegate.style != style ||
      oldDelegate.quality != quality ||
      oldDelegate.presence != presence ||
      oldDelegate.lightingShader != lightingShader;
}
