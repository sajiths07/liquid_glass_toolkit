@Tags(<String>['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_toolkit/liquid_glass_toolkit.dart';

// Goldens are rasterised by the host's software renderer and differ slightly
// between operating systems; the reference images were generated on Windows.
final bool _skip = !Platform.isWindows;

Widget _scene(
  Widget child, {
  Brightness brightness = Brightness.light,
  bool reduce = false,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: brightness),
    home: LiquidGlassTheme(
      data: brightness == Brightness.dark
          ? LiquidGlassThemeData.dark(reduceTransparency: reduce)
          : LiquidGlassThemeData.light(reduceTransparency: reduce),
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: CustomPaint(painter: _StripesPainter())),
            Center(child: child),
          ],
        ),
      ),
    ),
  );
}

class _StripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const List<Color> colors = <Color>[
      Color(0xFFFF6B6B),
      Color(0xFFFFD93D),
      Color(0xFF6BCB77),
      Color(0xFF4D96FF),
    ];
    for (int i = 0; i * 24 < size.width; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * 24.0, 0, 24, size.height),
        Paint()..color = colors[i % colors.length],
      );
    }
  }

  @override
  bool shouldRepaint(_StripesPainter oldDelegate) => false;
}

Widget _card(LiquidGlassQuality quality) => SizedBox(
  width: 260,
  height: 140,
  child: LiquidGlassSurface(
    quality: quality,
    padding: const EdgeInsets.all(16),
    child: const Text('Glass'),
  ),
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Future<void> pumpScene(WidgetTester tester, Widget scene) async {
    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(LiquidGlassShaders.ensureLoaded);
    await tester.pumpWidget(scene);
    await tester.pumpAndSettle();
  }

  testWidgets('minimal quality', (tester) async {
    await pumpScene(tester, _scene(_card(LiquidGlassQuality.minimal)));
    await expectLater(
      find.byType(Stack).first,
      matchesGoldenFile('goldens/surface_minimal.png'),
    );
  }, skip: _skip);

  testWidgets('standard quality (shader lighting)', (tester) async {
    await pumpScene(tester, _scene(_card(LiquidGlassQuality.standard)));
    await expectLater(
      find.byType(Stack).first,
      matchesGoldenFile('goldens/surface_standard.png'),
    );
  }, skip: _skip);

  testWidgets('dark theme', (tester) async {
    await pumpScene(
      tester,
      _scene(_card(LiquidGlassQuality.standard), brightness: Brightness.dark),
    );
    await expectLater(
      find.byType(Stack).first,
      matchesGoldenFile('goldens/surface_dark.png'),
    );
  }, skip: _skip);

  testWidgets('reduced transparency fallback', (tester) async {
    await pumpScene(
      tester,
      _scene(_card(LiquidGlassQuality.standard), reduce: true),
    );
    await expectLater(
      find.byType(Stack).first,
      matchesGoldenFile('goldens/surface_reduced_transparency.png'),
    );
  }, skip: _skip);

  testWidgets('navigation bar', (tester) async {
    await pumpScene(
      tester,
      _scene(
        SizedBox(
          width: 360,
          child: LiquidGlassNavigationBar(
            selectedIndex: 1,
            onDestinationSelected: (_) {},
            destinations: const <LiquidGlassNavigationDestination>[
              LiquidGlassNavigationDestination(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              LiquidGlassNavigationDestination(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              LiquidGlassNavigationDestination(
                icon: Icon(Icons.person),
                label: 'Me',
              ),
            ],
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Stack).first,
      matchesGoldenFile('goldens/navigation_bar.png'),
    );
  }, skip: _skip);
}
