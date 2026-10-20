import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

/// Describes the timing and physics of a liquid-glass animation.
///
/// A config can be time-based ([duration] + [curve]) or physics-based (when
/// [spring] is non-null). Physics-based configs still keep a [duration] and
/// [curve]: they are used by APIs that are inherently time-based, such as
/// page routes, which Flutter drives with a fixed transition duration.
///
/// Use [drive] to animate any [AnimationController] with this config, which
/// is how every widget in this package animates.
@immutable
class LiquidGlassAnimationConfig with Diagnosticable {
  /// Creates an animation config.
  const LiquidGlassAnimationConfig({
    this.duration = const Duration(milliseconds: 420),
    this.reverseDuration,
    this.curve = Curves.easeOutCubic,
    this.reverseCurve,
    this.spring,
    this.reducedMotionDuration = const Duration(milliseconds: 120),
  });

  /// Default config: a softly under-damped spring with a slight overshoot.
  static const LiquidGlassAnimationConfig fluid = LiquidGlassAnimationConfig(
    duration: Duration(milliseconds: 450),
    curve: Curves.easeOutCubic,
    spring: SpringDescription(mass: 1, stiffness: 260, damping: 27),
  );

  /// Quick, nearly critically damped motion for direct manipulation.
  static const LiquidGlassAnimationConfig snappy = LiquidGlassAnimationConfig(
    duration: Duration(milliseconds: 240),
    curve: Curves.easeOutQuart,
    spring: SpringDescription(mass: 1, stiffness: 520, damping: 42),
  );

  /// Playful motion with visible overshoot.
  static const LiquidGlassAnimationConfig bouncy = LiquidGlassAnimationConfig(
    duration: Duration(milliseconds: 600),
    curve: Curves.easeOutBack,
    spring: SpringDescription(mass: 1, stiffness: 220, damping: 15),
  );

  /// Slow, curve-based motion without springs.
  static const LiquidGlassAnimationConfig gentle = LiquidGlassAnimationConfig(
    duration: Duration(milliseconds: 650),
    curve: Curves.easeInOutCubic,
  );

  /// Forward animation duration (time-based configs and route transitions).
  final Duration duration;

  /// Reverse duration. Defaults to [duration].
  final Duration? reverseDuration;

  /// Forward curve for time-based animation.
  final Curve curve;

  /// Reverse curve. Defaults to the flipped [curve].
  final Curve? reverseCurve;

  /// Spring physics. When non-null, [drive] runs a [SpringSimulation]
  /// instead of a curve, and incoming gesture velocity is preserved.
  final SpringDescription? spring;

  /// Duration used instead of [duration] when reduced motion is requested.
  /// Reduced-motion animations are linear, never overshoot, and widgets drop
  /// scale/translation in favour of cross-fades.
  final Duration reducedMotionDuration;

  /// Whether this config animates with spring physics.
  bool get usesSpring => spring != null;

  /// The effective reverse duration.
  Duration get effectiveReverseDuration => reverseDuration ?? duration;

  /// The effective reverse curve.
  Curve get effectiveReverseCurve => reverseCurve ?? curve.flipped;

  /// A copy suitable for users who requested reduced motion.
  LiquidGlassAnimationConfig reduced() {
    return LiquidGlassAnimationConfig(
      duration: reducedMotionDuration,
      reverseDuration: reducedMotionDuration,
      curve: Curves.linear,
      reverseCurve: Curves.linear,
      reducedMotionDuration: reducedMotionDuration,
    );
  }

  /// Returns [reduced] when [reduceMotion] is true, otherwise `this`.
  LiquidGlassAnimationConfig resolve({required bool reduceMotion}) =>
      reduceMotion ? reduced() : this;

  /// Animates [controller] towards [target] using this config.
  ///
  /// With a [spring], a [SpringSimulation] starting from the controller's
  /// current value and the given [velocity] (units per second) is used, so
  /// animations can be interrupted and redirected mid-flight without jumps.
  /// Otherwise [duration]/[curve] (or their reverse variants when moving to
  /// a smaller value) are used.
  ///
  /// [tolerance] should be scaled to the controller's units; the default
  /// suits controllers in the `0..1` range.
  TickerFuture drive(
    AnimationController controller,
    double target, {
    double velocity = 0,
    Tolerance tolerance = const Tolerance(distance: 0.0005, velocity: 0.005),
  }) {
    final SpringDescription? spring = this.spring;
    if (spring != null) {
      return controller.animateWith(
        SpringSimulation(
          spring,
          controller.value,
          target,
          velocity,
          tolerance: tolerance,
          snapToEnd: true,
        ),
      );
    }
    final bool reverse = target < controller.value;
    final Duration d = reverse ? effectiveReverseDuration : duration;
    if (d == Duration.zero) {
      controller.value = target;
      return TickerFuture.complete();
    }
    return controller.animateTo(
      target,
      duration: d,
      curve: reverse ? effectiveReverseCurve : curve,
    );
  }

  /// Creates a copy with the given fields replaced. Pass
  /// [removeSpring] to switch a spring config to curve-based timing.
  LiquidGlassAnimationConfig copyWith({
    Duration? duration,
    Duration? reverseDuration,
    Curve? curve,
    Curve? reverseCurve,
    SpringDescription? spring,
    bool removeSpring = false,
    Duration? reducedMotionDuration,
  }) {
    return LiquidGlassAnimationConfig(
      duration: duration ?? this.duration,
      reverseDuration: reverseDuration ?? this.reverseDuration,
      curve: curve ?? this.curve,
      reverseCurve: reverseCurve ?? this.reverseCurve,
      spring: removeSpring ? null : (spring ?? this.spring),
      reducedMotionDuration:
          reducedMotionDuration ?? this.reducedMotionDuration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiquidGlassAnimationConfig &&
        other.duration == duration &&
        other.reverseDuration == reverseDuration &&
        other.curve == curve &&
        other.reverseCurve == reverseCurve &&
        other.spring?.mass == spring?.mass &&
        other.spring?.stiffness == spring?.stiffness &&
        other.spring?.damping == spring?.damping &&
        other.reducedMotionDuration == reducedMotionDuration;
  }

  @override
  int get hashCode => Object.hash(
    duration,
    reverseDuration,
    curve,
    reverseCurve,
    spring?.mass,
    spring?.stiffness,
    spring?.damping,
    reducedMotionDuration,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Duration>('duration', duration))
      ..add(
        DiagnosticsProperty<Duration>(
          'reverseDuration',
          reverseDuration,
          defaultValue: null,
        ),
      )
      ..add(DiagnosticsProperty<Curve>('curve', curve))
      ..add(
        DiagnosticsProperty<SpringDescription>(
          'spring',
          spring,
          defaultValue: null,
        ),
      );
  }
}
