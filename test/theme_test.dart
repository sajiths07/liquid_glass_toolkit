import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_toolkit/liquid_glass_toolkit.dart';

import 'helpers.dart';

LiquidGlassThemeData? _captured;

class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) {
    _captured = LiquidGlassTheme.of(context);
    return const SizedBox();
  }
}

void main() {
  setUp(() => _captured = null);

  testWidgets('falls back to light defaults in a light app', (tester) async {
    await tester.pumpWidget(harness(const _Probe()));
    expect(_captured!.style, const LiquidGlassStyle());
  });

  testWidgets('falls back to dark defaults when the app is dark', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const _Probe(), themeMode: ThemeMode.dark));
    expect(_captured!.style, const LiquidGlassStyle.dark());
    expect(_captured!.foregroundColor.computeLuminance(), greaterThan(0.8));
  });

  testWidgets('LiquidGlassTheme overrides and picks darkData', (tester) async {
    final LiquidGlassThemeData light = LiquidGlassThemeData.light(
      quality: LiquidGlassQuality.premium,
    );
    final LiquidGlassThemeData dark = LiquidGlassThemeData.dark(
      quality: LiquidGlassQuality.minimal,
    );
    Widget app(ThemeMode mode) => MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: mode,
      home: LiquidGlassTheme(
        data: light,
        darkData: dark,
        child: const _Probe(),
      ),
    );
    await tester.pumpWidget(app(ThemeMode.light));
    expect(_captured!.quality, LiquidGlassQuality.premium);
    await tester.pumpWidget(app(ThemeMode.dark));
    await tester.pumpAndSettle();
    expect(_captured!.quality, LiquidGlassQuality.minimal);
  });

  testWidgets('reads ThemeData extensions', (tester) async {
    final LiquidGlassThemeData data = LiquidGlassThemeData.light(
      accentColor: Colors.pink,
    );
    await tester.pumpWidget(
      harness(
        const _Probe(),
        theme: ThemeData(extensions: <ThemeExtension<dynamic>>[data]),
      ),
    );
    expect(_captured!.accentColor, Colors.pink);
  });

  testWidgets('works in a CupertinoApp', (tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        theme: CupertinoThemeData(brightness: Brightness.dark),
        home: _Probe(),
      ),
    );
    expect(_captured!.style, const LiquidGlassStyle.dark());
  });

  testWidgets('nested themes: nearest wins', (tester) async {
    await tester.pumpWidget(
      harness(
        LiquidGlassTheme(
          data: LiquidGlassThemeData.light(quality: LiquidGlassQuality.minimal),
          child: const _Probe(),
        ),
        glass: LiquidGlassThemeData.light(quality: LiquidGlassQuality.premium),
      ),
    );
    expect(_captured!.quality, LiquidGlassQuality.minimal);
  });

  testWidgets('accessibility flags follow MediaQuery unless overridden', (
    tester,
  ) async {
    late bool motion, transparency;
    final Widget probe = Builder(
      builder: (BuildContext context) {
        motion = LiquidGlassTheme.reduceMotionOf(context);
        transparency = LiquidGlassTheme.reduceTransparencyOf(context);
        return const SizedBox();
      },
    );
    await tester.pumpWidget(harness(probe));
    expect(motion, isFalse);
    expect(transparency, isFalse);

    await tester.pumpWidget(
      harness(probe, disableAnimations: true, highContrast: true),
    );
    expect(motion, isTrue);
    expect(transparency, isTrue);

    await tester.pumpWidget(
      harness(
        probe,
        disableAnimations: true,
        highContrast: true,
        glass: LiquidGlassThemeData.light(
          reduceMotion: false,
          reduceTransparency: false,
        ),
      ),
    );
    expect(motion, isFalse);
    expect(transparency, isFalse);
  });

  test('ThemeExtension lerp interpolates style', () {
    final LiquidGlassThemeData a = LiquidGlassThemeData.light(
      style: const LiquidGlassStyle(blur: 0),
    );
    final LiquidGlassThemeData b = LiquidGlassThemeData.light(
      style: const LiquidGlassStyle(blur: 10),
    );
    expect(a.lerp(b, 0.5).style.blur, 5);
    expect(a.copyWith(), a);
  });
}
