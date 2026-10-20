import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widget/liquid_glass_widget.dart';
import 'package:liquid_glass_widget/src/rendering/glass_painters.dart';

import 'helpers.dart';

GlassBodyPainter _bodyPainter(WidgetTester tester) {
  return tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((CustomPaint p) => p.painter)
      .whereType<GlassBodyPainter>()
      .single;
}

void main() {
  // Each test starts with unloaded shaders; loads started inside a test's
  // fake-async zone never complete and must not leak into the next test.
  setUp(LiquidGlassShaders.debugReset);

  testWidgets('renders its child with theme foreground color', (tester) async {
    await tester.pumpWidget(
      harness(
        const LiquidGlassSurface(
          padding: EdgeInsets.all(8),
          child: Text('glass'),
        ),
      ),
    );
    expect(find.text('glass'), findsOneWidget);
    final DefaultTextStyle style = tester.widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text('glass'),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );
    expect(style.style.color, const LiquidGlassThemeData().foregroundColor);
  });

  testWidgets('blurred glass creates exactly one backdrop filter', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(const LiquidGlassSurface(child: SizedBox(width: 50, height: 50))),
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(ClipRRect), findsOneWidget);
  });

  testWidgets('clear unadjusted glass has no backdrop filter', (tester) async {
    await tester.pumpWidget(
      harness(
        const LiquidGlassSurface(
          style: LiquidGlassStyle(blur: 0, saturation: 1),
          child: SizedBox(width: 50, height: 50),
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('custom style and quality reach the painter', (tester) async {
    const LiquidGlassStyle style = LiquidGlassStyle(
      opacity: 0.5,
      tintColor: Colors.teal,
      borderWidth: 3,
    );
    await tester.pumpWidget(
      harness(
        const LiquidGlassSurface(
          style: style,
          quality: LiquidGlassQuality.minimal,
          child: SizedBox(width: 50, height: 50),
        ),
      ),
    );
    final GlassBodyPainter painter = _bodyPainter(tester);
    expect(painter.style.tintColor, Colors.teal);
    expect(painter.style.opacity, 0.5);
    expect(painter.quality, LiquidGlassQuality.minimal);
    expect(
      painter.lightingShader,
      isNull,
      reason: 'minimal never uses shaders',
    );
  });

  testWidgets('theme quality and style are inherited', (tester) async {
    await tester.pumpWidget(
      harness(
        const LiquidGlassSurface(child: SizedBox(width: 50, height: 50)),
        glass: LiquidGlassThemeData.light(
          quality: LiquidGlassQuality.premium,
          style: const LiquidGlassStyle.frosted(),
        ),
      ),
    );
    final GlassBodyPainter painter = _bodyPainter(tester);
    expect(painter.style.blur, const LiquidGlassStyle.frosted().blur);
    // Premium degrades to the backdrop filter path without Impeller.
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('dark mode picks the dark style', (tester) async {
    await tester.pumpWidget(
      harness(
        const LiquidGlassSurface(child: SizedBox(width: 50, height: 50)),
        themeMode: ThemeMode.dark,
      ),
    );
    expect(
      _bodyPainter(tester).style.tintColor,
      const LiquidGlassStyle.dark().tintColor,
    );
  });

  testWidgets('reduced transparency renders opaque without blur', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const LiquidGlassSurface(child: SizedBox(width: 50, height: 50)),
        glass: LiquidGlassThemeData.light(reduceTransparency: true),
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    final GlassBodyPainter painter = _bodyPainter(tester);
    expect(painter.style.opacity, 1);
    expect(painter.quality, LiquidGlassQuality.minimal);
  });

  testWidgets(
    'platform high contrast triggers opaque fallback and stronger border',
    (tester) async {
      await tester.pumpWidget(
        harness(
          const LiquidGlassSurface(child: SizedBox(width: 50, height: 50)),
          highContrast: true,
        ),
      );
      final GlassBodyPainter painter = _bodyPainter(tester);
      expect(painter.style.opacity, 1);
      expect(painter.style.borderWidth, greaterThanOrEqualTo(1.5));
    },
  );

  testWidgets('presence scales glass and fades content', (tester) async {
    await tester.pumpWidget(
      harness(
        const LiquidGlassPresence(
          value: 0.5,
          child: LiquidGlassSurface(child: Text('x')),
        ),
      ),
    );
    expect(_bodyPainter(tester).presence, 0.5);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.5);
  });

  testWidgets('borderRadius override resolves directionally', (tester) async {
    await tester.pumpWidget(
      harness(
        const LiquidGlassSurface(
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(30),
          ),
          child: SizedBox(width: 50, height: 50),
        ),
        textDirection: TextDirection.rtl,
      ),
    );
    final BorderRadius r = _bodyPainter(tester).style.borderRadius;
    expect(r.topRight.x, 30);
    expect(r.topLeft.x, 0);
  });

  testWidgets('decorative layers do not steal taps from content', (
    tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      harness(
        LiquidGlassSurface(
          padding: const EdgeInsets.all(20),
          child: GestureDetector(
            key: const Key('content'),
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('content')));
    expect(taps, 1);
  });

  group('LiquidGlassContainer (0.x API)', () {
    testWidgets('keeps its constructor defaults and behaviour', (tester) async {
      await tester.pumpWidget(
        harness(const LiquidGlassContainer(child: Text('legacy'))),
      );
      expect(find.text('legacy'), findsOneWidget);
      final GlassBodyPainter painter = _bodyPainter(tester);
      expect(painter.style.blur, 10);
      expect(painter.style.opacity, 0.2);
      expect(painter.style.tintColor, const Color(0xFFFFFFFF));
      expect(painter.style.borderRadius, BorderRadius.circular(16));
    });

    testWidgets('accepts blur, opacity, padding and borderRadius', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          LiquidGlassContainer(
            blur: 30,
            opacity: 0.4,
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(20),
            child: const Text('legacy'),
          ),
        ),
      );
      final GlassBodyPainter painter = _bodyPainter(tester);
      expect(painter.style.blur, 30);
      expect(painter.style.opacity, 0.4);
      expect(painter.style.borderRadius, BorderRadius.circular(20));
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('legacy import path still works', (tester) async {
      // The 0.x import `package:liquid_glass_widget/widgets/liquid_glass_container.dart`
      // is exercised by legacy_import_test.dart.
      expect(LiquidGlassContainer, isNotNull);
    });
  });

  testWidgets('surfaces dispose cleanly', (tester) async {
    await tester.runAsync(LiquidGlassShaders.ensureLoaded);
    await tester.pumpWidget(
      harness(const LiquidGlassSurface(child: SizedBox(width: 10, height: 10))),
    );
    await tester.pumpWidget(harness(const SizedBox()));
    expect(tester.takeException(), isNull);
  });
}
