import 'package:flutter/material.dart';

import '../animation/animation_config.dart';
import '../theme/liquid_glass_theme.dart';

/// Page transition: the incoming page slides in from the trailing edge with
/// rounded corners that flatten as it lands, while the outgoing page drifts
/// back and dims. With reduced motion it becomes a cross-fade.
///
/// Opacity is never applied to the incoming page during the slide, so glass
/// surfaces on it keep their blur throughout the transition.
class LiquidGlassPageTransition extends StatefulWidget {
  /// Creates the transition.
  const LiquidGlassPageTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    this.curve = Curves.easeOutCubic,
    this.reverseCurve,
    this.cornerRadius = 32,
  });

  /// Primary route animation (this page entering / leaving).
  final Animation<double> animation;

  /// Secondary animation (another page covering this one).
  final Animation<double> secondaryAnimation;

  /// The page.
  final Widget child;

  /// Curve for entering.
  final Curve curve;

  /// Curve for leaving. Defaults to the flipped [curve].
  final Curve? reverseCurve;

  /// Corner radius of the page at the start of the slide.
  final double cornerRadius;

  @override
  State<LiquidGlassPageTransition> createState() =>
      _LiquidGlassPageTransitionState();
}

class _LiquidGlassPageTransitionState extends State<LiquidGlassPageTransition> {
  late CurvedAnimation _primary;
  late CurvedAnimation _secondary;

  @override
  void initState() {
    super.initState();
    _create();
  }

  void _create() {
    final Curve reverse = widget.reverseCurve ?? widget.curve.flipped;
    _primary = CurvedAnimation(
      parent: widget.animation,
      curve: widget.curve,
      reverseCurve: reverse,
    );
    _secondary = CurvedAnimation(
      parent: widget.secondaryAnimation,
      curve: widget.curve,
      reverseCurve: reverse,
    );
  }

  @override
  void didUpdateWidget(LiquidGlassPageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation ||
        oldWidget.secondaryAnimation != widget.secondaryAnimation ||
        oldWidget.curve != widget.curve ||
        oldWidget.reverseCurve != widget.reverseCurve) {
      _primary.dispose();
      _secondary.dispose();
      _create();
    }
  }

  @override
  void dispose() {
    _primary.dispose();
    _secondary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (LiquidGlassTheme.reduceMotionOf(context)) {
      return FadeTransition(opacity: widget.animation, child: widget.child);
    }
    final bool rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final double dir = rtl ? -1 : 1;
    final Animation<double> primary = _primary;
    final Animation<double> secondary = _secondary;
    final double cornerRadius = widget.cornerRadius;
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[primary, secondary]),
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final double t = primary.value;
        final double s = secondary.value;
        final double width = MediaQuery.maybeSizeOf(context)?.width ?? 400;
        final double x = dir * ((1 - t) * width - s * width * 0.28);
        final double scale = 0.94 + 0.06 * t;
        final double radius = cornerRadius * (1 - t).clamp(0.0, 1.0);
        Widget page = child!;
        if (radius > 0.5) {
          page = DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18 * (1 - t)),
                  blurRadius: 30,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: page,
            ),
          );
        }
        page = Transform(
          alignment: Alignment.center,
          transform: Matrix4.translationValues(x, 0, 0)
            ..multiply(Matrix4.diagonal3Values(scale, scale, 1)),
          child: page,
        );
        if (s > 0) {
          page = Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              page,
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.14 * s),
                  ),
                ),
              ),
            ],
          );
        }
        return page;
      },
    );
  }
}

/// A [PageTransitionsBuilder] that applies [LiquidGlassPageTransition] to
/// `MaterialPageRoute`s, for use in `ThemeData.pageTransitionsTheme`.
///
/// The curve comes from the theme's `overlayAnimation`. The duration is the
/// route's own (300 ms for `MaterialPageRoute`); use [LiquidGlassPageRoute]
/// for a configurable duration.
class LiquidGlassPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates the builder.
  const LiquidGlassPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final LiquidGlassAnimationConfig config = LiquidGlassTheme.of(
      context,
    ).overlayAnimation;
    return LiquidGlassPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      curve: config.curve,
      reverseCurve: config.reverseCurve,
      child: child,
    );
  }
}

/// A page route using [LiquidGlassPageTransition] with a configurable
/// duration and curve.
///
/// When [animationConfig] is null, the `overlayAnimation` of the theme
/// visible from the navigator is used. Route transitions are time-based, so
/// [LiquidGlassAnimationConfig.spring] is ignored here.
class LiquidGlassPageRoute<T> extends PageRoute<T> {
  /// Creates a route.
  LiquidGlassPageRoute({
    required this.builder,
    this.animationConfig,
    super.settings,
    this.maintainState = true,
    super.fullscreenDialog,
  });

  /// Builds the page.
  final WidgetBuilder builder;

  /// Timing override.
  final LiquidGlassAnimationConfig? animationConfig;

  LiquidGlassAnimationConfig get _config {
    final LiquidGlassAnimationConfig? explicit = animationConfig;
    if (explicit != null) return explicit;
    final BuildContext? context = navigator?.context;
    if (context == null) return const LiquidGlassThemeData().overlayAnimation;
    return LiquidGlassTheme.of(context).overlayAnimation;
  }

  @override
  final bool maintainState;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => _config.duration;

  @override
  Duration get reverseTransitionDuration => _config.effectiveReverseDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: builder(context),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final LiquidGlassAnimationConfig config = _config;
    return LiquidGlassPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      curve: config.curve,
      reverseCurve: config.reverseCurve,
      child: child,
    );
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is PageRoute && !nextRoute.fullscreenDialog;
}
