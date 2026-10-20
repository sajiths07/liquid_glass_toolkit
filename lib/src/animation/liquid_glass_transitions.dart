import 'package:flutter/widgets.dart';

import '../core/glass_quality.dart';
import '../core/glass_style.dart';
import '../theme/liquid_glass_theme.dart';
import '../widgets/liquid_glass_surface.dart';
import 'animation_config.dart';
import 'glass_presence.dart';

/// Explicit entry/exit transition for liquid-glass content.
///
/// Drives [LiquidGlassPresence] (fading glass and its content without
/// breaking backdrop blur), and scales/slides the child. With reduced
/// motion, only the presence fade remains.
///
/// [animation] values may overshoot `1` (spring-driven controllers); scale
/// and offset follow the overshoot, presence is clamped.
class LiquidGlassTransition extends StatelessWidget {
  /// Creates a transition.
  const LiquidGlassTransition({
    super.key,
    required this.animation,
    required this.child,
    this.scaleBegin = 0.9,
    this.offsetBegin = Offset.zero,
    this.alignment = Alignment.center,
  });

  /// Progress from hidden (`0`) to shown (`1`).
  final Animation<double> animation;

  /// Content, typically containing liquid-glass surfaces.
  final Widget child;

  /// Scale at progress `0`.
  final double scaleBegin;

  /// Translation at progress `0`, in logical pixels.
  final Offset offsetBegin;

  /// Origin of the scale.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = LiquidGlassTheme.reduceMotionOf(context);
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (BuildContext context, Widget? child) {
        final double t = animation.value;
        final double presence = t.clamp(0.0, 1.0);
        Widget result = LiquidGlassPresence(value: presence, child: child!);
        if (!reduceMotion) {
          final double scale = scaleBegin + (1 - scaleBegin) * t;
          final Offset offset = offsetBegin * (1 - t);
          result = Transform(
            alignment: alignment,
            transform: Matrix4.translationValues(offset.dx, offset.dy, 0)
              ..multiply(Matrix4.diagonal3Values(scale, scale, 1)),
            child: result,
          );
        }
        return IgnorePointer(ignoring: presence < 0.5, child: result);
      },
    );
  }
}

/// Implicitly animates liquid-glass content in and out when [visible]
/// changes, using [animation] (or the theme's `animation`).
///
/// Interrupting the animation (toggling [visible] mid-flight) continues from
/// the current value and velocity. When hidden and settled, the child is
/// removed from the tree unless [maintainState] is true.
class LiquidGlassAppear extends StatefulWidget {
  /// Creates an implicit appear/disappear animation.
  const LiquidGlassAppear({
    super.key,
    required this.visible,
    required this.child,
    this.animation,
    this.scaleBegin = 0.88,
    this.offsetBegin = const Offset(0, 12),
    this.alignment = Alignment.center,
    this.maintainState = false,
    this.onEnd,
  });

  /// Whether the child is shown.
  final bool visible;

  /// The content.
  final Widget child;

  /// Overrides the theme animation.
  final LiquidGlassAnimationConfig? animation;

  /// Scale when hidden.
  final double scaleBegin;

  /// Offset when hidden.
  final Offset offsetBegin;

  /// Origin of the scale.
  final Alignment alignment;

  /// Keeps the hidden child mounted (but invisible and non-interactive).
  final bool maintainState;

  /// Called whenever an appear or disappear animation settles.
  final VoidCallback? onEnd;

  @override
  State<LiquidGlassAppear> createState() => _LiquidGlassAppearState();
}

class _LiquidGlassAppearState extends State<LiquidGlassAppear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
    value: widget.visible ? 1 : 0,
  );

  @override
  void didUpdateWidget(LiquidGlassAppear oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) _run();
  }

  void _run() {
    final LiquidGlassAnimationConfig config =
        (widget.animation ?? LiquidGlassTheme.of(context).animation).resolve(
          reduceMotion: LiquidGlassTheme.reduceMotionOf(context),
        );
    final double velocity = _controller.velocity;
    config.drive(_controller, widget.visible ? 1 : 0, velocity: velocity).then((
      _,
    ) {
      if (!mounted) return;
      setState(() {});
      widget.onEnd?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hidden = !widget.visible && !_controller.isAnimating;
    if (hidden && !widget.maintainState) return const SizedBox.shrink();
    return ExcludeSemantics(
      excluding: !widget.visible,
      child: LiquidGlassTransition(
        animation: _controller,
        scaleBegin: widget.scaleBegin,
        offsetBegin: widget.offsetBegin,
        alignment: widget.alignment,
        child: widget.child,
      ),
    );
  }
}

/// A [LiquidGlassSurface] that animates between styles whenever [style]
/// changes: blur, transparency, tint, radius, lighting and shadow are all
/// interpolated.
///
/// Uses [animation] or the theme's `animation`. Spring overshoot is clamped
/// for the style interpolation so values stay within their valid ranges.
class AnimatedLiquidGlassSurface extends StatefulWidget {
  /// Creates an animated surface.
  const AnimatedLiquidGlassSurface({
    super.key,
    required this.style,
    this.child,
    this.quality,
    this.padding,
    this.foregroundColor,
    this.animation,
  });

  /// Target style.
  final LiquidGlassStyle style;

  /// Content painted above the glass.
  final Widget? child;

  /// Rendering quality.
  final LiquidGlassQuality? quality;

  /// Padding around [child].
  final EdgeInsetsGeometry? padding;

  /// Text/icon color inside the surface.
  final Color? foregroundColor;

  /// Overrides the theme animation.
  final LiquidGlassAnimationConfig? animation;

  @override
  State<AnimatedLiquidGlassSurface> createState() =>
      _AnimatedLiquidGlassSurfaceState();
}

class _AnimatedLiquidGlassSurfaceState extends State<AnimatedLiquidGlassSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1,
  );
  late LiquidGlassStyle _from = widget.style;
  late LiquidGlassStyle _to = widget.style;

  LiquidGlassStyle get _current =>
      LiquidGlassStyle.lerp(_from, _to, _controller.value.clamp(0.0, 1.0));

  @override
  void didUpdateWidget(AnimatedLiquidGlassSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.style != _to) {
      _from = _current;
      _to = widget.style;
      _controller.value = 0;
      final LiquidGlassAnimationConfig config =
          (widget.animation ?? LiquidGlassTheme.of(context).animation).resolve(
            reduceMotion: LiquidGlassTheme.reduceMotionOf(context),
          );
      config.drive(_controller, 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) => LiquidGlassSurface(
        style: _current,
        quality: widget.quality,
        padding: widget.padding,
        foregroundColor: widget.foregroundColor,
        child: child,
      ),
      child: widget.child,
    );
  }
}
