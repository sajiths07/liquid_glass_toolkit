// Ticker futures are driven by pumping, not awaited.
// ignore_for_file: unawaited_futures

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_toolkit/liquid_glass_toolkit.dart';
import 'package:liquid_glass_toolkit/src/rendering/backdrop_filters.dart';

void main() {
  group('LiquidGlassStyle', () {
    test('has documented defaults', () {
      const LiquidGlassStyle s = LiquidGlassStyle();
      expect(s.blur, 12);
      expect(s.opacity, 0.16);
      expect(s.enableRefraction, isTrue);
      expect(s.enableHighlights, isTrue);
      expect(s.borderRadius, const BorderRadius.all(Radius.circular(22)));
    });

    test('presets describe distinct glass types', () {
      const LiquidGlassStyle clear = LiquidGlassStyle.clear();
      const LiquidGlassStyle frosted = LiquidGlassStyle.frosted();
      final LiquidGlassStyle tinted = LiquidGlassStyle.tinted(Colors.teal);
      expect(clear.blur, lessThan(const LiquidGlassStyle().blur));
      expect(clear.opacity, lessThan(0.1));
      expect(frosted.blur, greaterThan(const LiquidGlassStyle().blur));
      expect(tinted.tintColor, Colors.teal);
      expect(
        const LiquidGlassStyle.dark().tintColor.computeLuminance(),
        lessThan(0.1),
      );
    });

    test('blur and opacity are independent', () {
      final LiquidGlassStyle s = const LiquidGlassStyle().copyWith(
        blur: 0,
        opacity: 0.9,
      );
      expect(s.blur, 0);
      expect(s.opacity, 0.9);
      final LiquidGlassStyle t = const LiquidGlassStyle().copyWith(
        blur: 40,
        opacity: 0,
      );
      expect(t.blur, 40);
      expect(t.opacity, 0);
    });

    test('copyWith, equality and hashCode', () {
      const LiquidGlassStyle a = LiquidGlassStyle();
      final LiquidGlassStyle b = a.copyWith();
      expect(b, a);
      expect(b.hashCode, a.hashCode);
      expect(a.copyWith(rimLightIntensity: 0.1), isNot(a));
    });

    test('lerp interpolates numbers, colors and radii', () {
      const LiquidGlassStyle a = LiquidGlassStyle(
        blur: 0,
        opacity: 0,
        borderRadius: BorderRadius.zero,
        enableRefraction: false,
      );
      const LiquidGlassStyle b = LiquidGlassStyle(
        blur: 20,
        opacity: 1,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      );
      final LiquidGlassStyle mid = LiquidGlassStyle.lerp(a, b, 0.5);
      expect(mid.blur, 10);
      expect(mid.opacity, 0.5);
      expect(mid.borderRadius.topLeft.x, 10);
      expect(LiquidGlassStyle.lerp(a, b, 0.4).enableRefraction, isFalse);
      expect(LiquidGlassStyle.lerp(a, b, 0.6).enableRefraction, isTrue);
      expect(LiquidGlassStyle.lerp(a, b, 1.5).opacity, 1, reason: 'clamped');
    });

    test('invalid values assert in debug mode', () {
      expect(() => LiquidGlassStyle(blur: -1), throwsAssertionError);
      expect(() => LiquidGlassStyle(opacity: 1.5), throwsAssertionError);
      expect(() => LiquidGlassStyle(saturation: 9), throwsAssertionError);
      expect(
        () => LiquidGlassStyle(refractionStrength: -0.1),
        throwsAssertionError,
      );
    });

    test('sanitized clamps non-finite values', () {
      final LiquidGlassStyle s = const LiquidGlassStyle().copyWith(
        shadowOffset: const Offset(double.nan, 0),
      );
      expect(s.sanitized().shadowOffset, Offset.zero);
    });

    test('reduced transparency produces an opaque, unblurred style', () {
      final LiquidGlassStyle s = const LiquidGlassStyle()
          .withReducedTransparency(const Color(0xFFF2F2F7));
      expect(s.blur, 0);
      expect(s.opacity, 1);
      expect(s.tintColor.a, 1);
      expect(s.enableRefraction, isFalse);
      expect(s.hasColorAdjustment, isFalse);
    });

    test('high contrast strengthens the border', () {
      final LiquidGlassStyle s = const LiquidGlassStyle().withHighContrast(
        Colors.black,
      );
      expect(s.borderWidth, greaterThanOrEqualTo(1.5));
      expect(s.opacity, greaterThanOrEqualTo(0.6));
    });
  });

  group('backdrop filter', () {
    test('clear unadjusted glass needs no backdrop layer', () {
      const LiquidGlassStyle s = LiquidGlassStyle(
        blur: 0,
        saturation: 1,
        brightness: 0,
        contrast: 1,
      );
      expect(buildGlassBackdropFilter(s, LiquidGlassQuality.standard), isNull);
    });

    test('minimal quality skips the color matrix', () {
      const LiquidGlassStyle s = LiquidGlassStyle(blur: 0, saturation: 2);
      expect(buildGlassBackdropFilter(s, LiquidGlassQuality.minimal), isNull);
      expect(
        buildGlassBackdropFilter(s, LiquidGlassQuality.standard),
        isNotNull,
      );
    });

    test('zero presence removes blur', () {
      const LiquidGlassStyle s = LiquidGlassStyle(
        saturation: 1,
        brightness: 0,
        contrast: 1,
      );
      expect(
        buildGlassBackdropFilter(s, LiquidGlassQuality.minimal, presence: 0),
        isNull,
      );
    });

    test('identity color matrix when unadjusted', () {
      final List<double> m = glassColorMatrix(
        saturation: 1,
        contrast: 1,
        brightness: 0,
      );
      expect(m, <double>[
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]);
    });

    test('zero saturation produces equal rows (grayscale)', () {
      final List<double> m = glassColorMatrix(
        saturation: 0,
        contrast: 1,
        brightness: 0,
      );
      expect(m.sublist(0, 3), m.sublist(5, 8));
      expect(m.sublist(0, 3), m.sublist(10, 13));
    });
  });

  group('LiquidGlassAnimationConfig', () {
    testWidgets('curve config honours forward and reverse durations', (
      tester,
    ) async {
      final AnimationController c = AnimationController(
        vsync: const TestVSync(),
      );
      addTearDown(c.dispose);
      const LiquidGlassAnimationConfig config = LiquidGlassAnimationConfig(
        duration: Duration(milliseconds: 200),
        reverseDuration: Duration(milliseconds: 600),
        curve: Curves.linear,
        reverseCurve: Curves.linear,
      );
      config.drive(c, 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.value, closeTo(0.5, 0.02));
      await tester.pump(const Duration(milliseconds: 110));
      expect(c.value, 1);

      config.drive(c, 0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(c.value, closeTo(0.5, 0.02));
      await tester.pump(const Duration(milliseconds: 310));
      expect(c.value, 0);
    });

    testWidgets('spring config overshoots and settles exactly on target', (
      tester,
    ) async {
      final AnimationController c = AnimationController.unbounded(
        vsync: const TestVSync(),
      );
      addTearDown(c.dispose);
      double peak = 0;
      c.addListener(() => peak = c.value > peak ? c.value : peak);
      LiquidGlassAnimationConfig.bouncy.drive(c, 1);
      await tester.pumpAndSettle();
      expect(peak, greaterThan(1.0));
      expect(c.value, 1);
    });

    testWidgets('spring keeps the incoming velocity', (tester) async {
      final AnimationController a = AnimationController.unbounded(
        vsync: const TestVSync(),
      );
      final AnimationController b = AnimationController.unbounded(
        vsync: const TestVSync(),
      );
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      LiquidGlassAnimationConfig.fluid.drive(a, 1);
      LiquidGlassAnimationConfig.fluid.drive(b, 1, velocity: 10);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(b.value, greaterThan(a.value));
      await tester.pumpAndSettle();
    });

    testWidgets('custom spring description is used', (tester) async {
      final AnimationController stiff = AnimationController.unbounded(
        vsync: const TestVSync(),
      );
      final AnimationController soft = AnimationController.unbounded(
        vsync: const TestVSync(),
      );
      addTearDown(stiff.dispose);
      addTearDown(soft.dispose);
      const LiquidGlassAnimationConfig(
        spring: SpringDescription(mass: 1, stiffness: 900, damping: 60),
      ).drive(stiff, 1);
      const LiquidGlassAnimationConfig(
        spring: SpringDescription(mass: 1, stiffness: 60, damping: 16),
      ).drive(soft, 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(stiff.value, greaterThan(soft.value));
      await tester.pumpAndSettle();
    });

    testWidgets('zero duration jumps immediately', (tester) async {
      final AnimationController c = AnimationController(
        vsync: const TestVSync(),
      );
      addTearDown(c.dispose);
      const LiquidGlassAnimationConfig(duration: Duration.zero).drive(c, 1);
      expect(c.value, 1);
    });

    test('reduced motion drops springs and shortens timing', () {
      final LiquidGlassAnimationConfig r = LiquidGlassAnimationConfig.bouncy
          .resolve(reduceMotion: true);
      expect(r.usesSpring, isFalse);
      expect(
        r.duration,
        LiquidGlassAnimationConfig.bouncy.reducedMotionDuration,
      );
      expect(r.curve, Curves.linear);
      expect(
        LiquidGlassAnimationConfig.bouncy.resolve(reduceMotion: false),
        same(LiquidGlassAnimationConfig.bouncy),
      );
    });

    test('copyWith can remove the spring', () {
      final LiquidGlassAnimationConfig c = LiquidGlassAnimationConfig.fluid
          .copyWith(removeSpring: true, duration: const Duration(seconds: 1));
      expect(c.usesSpring, isFalse);
      expect(c.duration, const Duration(seconds: 1));
      expect(c, isNot(LiquidGlassAnimationConfig.fluid));
    });
  });
}
