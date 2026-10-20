import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_toolkit/liquid_glass_toolkit.dart';
import 'package:liquid_glass_toolkit/src/rendering/glass_painters.dart';

import 'helpers.dart';

const List<LiquidGlassNavigationDestination> _destinations =
    <LiquidGlassNavigationDestination>[
      LiquidGlassNavigationDestination(icon: Icon(Icons.home), label: 'Home'),
      LiquidGlassNavigationDestination(
        icon: Icon(Icons.search),
        label: 'Search',
      ),
      LiquidGlassNavigationDestination(
        icon: Icon(Icons.settings),
        label: 'A much longer label',
      ),
    ];

Widget _bar({bool showReflections = true, double maxWidth = 480}) => SizedBox(
  width: 1000,
  child: LiquidGlassNavigationBar(
    selectedIndex: 0,
    onDestinationSelected: (_) {},
    destinations: _destinations,
    showReflections: showReflections,
    maxWidth: maxWidth,
  ),
);

Finder _reflections() => find.byWidgetPredicate(
  (Widget w) => w is CustomPaint && w.painter is GlassReflectionPainter,
);

Finder _drops() => find.byWidgetPredicate(
  (Widget w) => w is CustomPaint && w.painter is GlassDropPainter,
);

void main() {
  setUp(LiquidGlassShaders.debugReset);

  testWidgets('capsule is capped at maxWidth and centered', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(harness(_bar(maxWidth: 400)));
    await tester.pumpAndSettle();
    final Rect capsule = tester.getRect(
      find
          .descendant(
            of: find.byType(LiquidGlassNavigationBar),
            matching: find.byType(LiquidGlassSurface),
          )
          .first,
    );
    final Rect bar = tester.getRect(find.byType(LiquidGlassNavigationBar));
    expect(capsule.width, 400);
    expect(capsule.center.dx, closeTo(bar.center.dx, 0.5));
  });

  testWidgets('icons share one baseline and are evenly spaced', (tester) async {
    await tester.pumpWidget(harness(_bar(maxWidth: 360)));
    await tester.pumpAndSettle();
    final List<Rect> icons = <IconData>[
      Icons.home,
      Icons.search,
      Icons.settings,
    ].map((IconData i) => tester.getRect(find.byIcon(i))).toList();
    expect(icons[1].top, closeTo(icons[0].top, 0.01));
    expect(icons[2].top, closeTo(icons[0].top, 0.01));
    final double gapA = icons[1].center.dx - icons[0].center.dx;
    final double gapB = icons[2].center.dx - icons[1].center.dx;
    expect(gapA, closeTo(gapB, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('capsule reflects and the indicator is a water-drop lens', (
    tester,
  ) async {
    await tester.pumpWidget(harness(_bar()));
    await tester.pumpAndSettle();
    expect(_reflections(), findsOneWidget);
    expect(_drops(), findsOneWidget);
    final RawMagnifier lens = tester.widget(find.byType(RawMagnifier));
    expect(lens.magnificationScale, 1.15);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drop fills the slot by default', (tester) async {
    await tester.pumpWidget(harness(_bar(maxWidth: 360)));
    await tester.pumpAndSettle();
    final RawMagnifier lens = tester.widget(find.byType(RawMagnifier));
    final Size slot = Size((360 - 8) / 3 - 4, 64 - 8);
    expect(lens.size.width, closeTo(slot.width, 0.5));
    expect(lens.size.height, closeTo(slot.height, 0.5));
  });

  Future<void> pumpDrop(WidgetTester tester, LiquidGlassDropStyle drop) async {
    await tester.pumpWidget(
      harness(
        SizedBox(
          width: 360,
          child: LiquidGlassNavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            destinations: _destinations,
            dropStyle: drop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('custom size, circle shape and shadow color apply', (
    tester,
  ) async {
    const Color shadow = Color(0x660A84FF);
    await pumpDrop(
      tester,
      const LiquidGlassDropStyle(
        shape: LiquidGlassDropShape.circle,
        size: Size(70, 48),
        shadowColor: shadow,
        magnification: 1.3,
      ),
    );
    final RawMagnifier lens = tester.widget(find.byType(RawMagnifier));
    expect(lens.size, const Size(48, 48));
    expect(lens.magnificationScale, 1.3);
    final LiquidGlassSurface surface = tester.widget(
      find
          .ancestor(of: _drops(), matching: find.byType(LiquidGlassSurface))
          .first,
    );
    expect(surface.style!.shadowColor, shadow);
    expect(surface.style!.borderRadius, BorderRadius.circular(24));
    expect(tester.takeException(), isNull);
  });

  testWidgets('rounded rectangle uses its radius', (tester) async {
    await pumpDrop(
      tester,
      LiquidGlassDropStyle(
        shape: LiquidGlassDropShape.roundedRectangle,
        borderRadius: BorderRadius.circular(10),
      ),
    );
    final LiquidGlassSurface surface = tester.widget(
      find
          .ancestor(of: _drops(), matching: find.byType(LiquidGlassSurface))
          .first,
    );
    expect(surface.style!.borderRadius, BorderRadius.circular(10));
  });

  testWidgets('magnification 1 disables the lens but keeps the optics', (
    tester,
  ) async {
    await pumpDrop(tester, const LiquidGlassDropStyle(magnification: 1));
    expect(find.byType(RawMagnifier), findsNothing);
    expect(_drops(), findsOneWidget);
  });

  testWidgets('opticsIntensity 0 removes the painted optics', (tester) async {
    await pumpDrop(tester, const LiquidGlassDropStyle(opticsIntensity: 0));
    expect(_drops(), findsNothing);
  });

  group('LiquidGlassDropStyle', () {
    test('resolveSize clamps to the slot and squares circles', () {
      const LiquidGlassDropStyle capsule = LiquidGlassDropStyle(
        size: Size(500, 20),
      );
      expect(capsule.resolveSize(const Size(100, 56)), const Size(100, 20));
      const LiquidGlassDropStyle circle = LiquidGlassDropStyle(
        shape: LiquidGlassDropShape.circle,
      );
      expect(circle.resolveSize(const Size(100, 56)), const Size(56, 56));
    });

    test('capsule radius is half the short side', () {
      const LiquidGlassDropStyle drop = LiquidGlassDropStyle();
      expect(drop.resolveRadius(const Size(80, 40)), BorderRadius.circular(20));
    });

    test('copyWith, equality and lerp', () {
      const LiquidGlassDropStyle a = LiquidGlassDropStyle();
      final LiquidGlassDropStyle b = a.copyWith(
        shadowBlur: 30,
        shape: LiquidGlassDropShape.circle,
      );
      expect(a, const LiquidGlassDropStyle());
      expect(a.hashCode, const LiquidGlassDropStyle().hashCode);
      expect(b == a, isFalse);
      final LiquidGlassDropStyle mid = LiquidGlassDropStyle.lerp(a, b, 0.5);
      expect(mid.shadowBlur, closeTo(22, 1e-9));
      expect(mid.shape, LiquidGlassDropShape.circle);
      expect(LiquidGlassDropStyle.lerp(a, b, 0.2).shape, a.shape);
    });
  });

  testWidgets('reflections are removed when disabled', (tester) async {
    await tester.pumpWidget(harness(_bar(showReflections: false)));
    await tester.pumpAndSettle();
    expect(_reflections(), findsNothing);
    expect(_drops(), findsNothing);
  });

  testWidgets('reduced transparency drops reflections and the lens', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        _bar(),
        glass: LiquidGlassThemeData.light(reduceTransparency: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(_reflections(), findsNothing);
    expect(_drops(), findsNothing);
    expect(find.byType(RawMagnifier), findsNothing);
  });

  test('drop painter repaints only on change', () {
    GlassDropPainter make(double i) =>
        GlassDropPainter(borderRadius: BorderRadius.circular(20), intensity: i);
    expect(make(1).shouldRepaint(make(1)), isFalse);
    expect(make(1).shouldRepaint(make(0.5)), isTrue);
  });

  testWidgets('selection still works with the new layout', (tester) async {
    int? picked;
    await tester.pumpWidget(
      harness(
        SizedBox(
          width: 360,
          child: LiquidGlassNavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (int i) => picked = i,
            destinations: _destinations,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(picked, 1);
  });

  test('reflection painter repaints only on change', () {
    final GlassReflectionPainter a = GlassReflectionPainter(
      borderRadius: BorderRadius.circular(20),
      intensity: 1,
    );
    expect(
      a.shouldRepaint(
        GlassReflectionPainter(
          borderRadius: BorderRadius.circular(20),
          intensity: 1,
        ),
      ),
      isFalse,
    );
    expect(
      a.shouldRepaint(
        GlassReflectionPainter(
          borderRadius: BorderRadius.circular(20),
          intensity: 0.5,
        ),
      ),
      isTrue,
    );
  });
}
