import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_ui/liquid_glass_ui.dart';
import 'package:liquid_glass_ui_example/demo_config.dart';
import 'package:liquid_glass_ui_example/main.dart';
import 'package:liquid_glass_ui_example/pages/gallery_page.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, DemoConfig config) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(LiquidGlassDemoApp(config: config));
    await tester.pumpAndSettle();
  }

  testWidgets('every tab renders without errors', (tester) async {
    await pumpApp(tester, DemoConfig());
    for (final String tab in <String>[
      'Controls',
      'Overlays',
      'Configure',
      'Gallery',
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byType(LiquidGlassNavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(LiquidGlassAppBar),
          matching: find.text(tab),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('configuration changes flow into the theme', (tester) async {
    final DemoConfig config = DemoConfig();
    await pumpApp(tester, config);
    config.update(() {
      config.blur = 30;
      config.quality = LiquidGlassQuality.minimal;
      config.themeMode = ThemeMode.dark;
      config.reduceTransparency = true;
      config.reduceMotion = true;
    });
    await tester.pumpAndSettle();
    final BuildContext context = tester.element(find.byType(GalleryPage));
    final LiquidGlassThemeData theme = LiquidGlassTheme.of(context);
    expect(theme.style.blur, 30);
    expect(theme.quality, LiquidGlassQuality.minimal);
    expect(theme.reduceTransparency, isTrue);
    expect(LiquidGlassTheme.brightnessOf(context), Brightness.dark);
    expect(LiquidGlassTheme.reduceMotionOf(context), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialog opens and closes from the overlays tab', (tester) async {
    await pumpApp(tester, DemoConfig());
    await tester.tap(
      find.descendant(
        of: find.byType(LiquidGlassNavigationBar),
        matching: find.text('Overlays'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Delete photo?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Dialog result: false'), findsOneWidget);
  });
}
