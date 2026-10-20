import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_toolkit/liquid_glass_toolkit.dart';

import 'helpers.dart';

final BorderRadius _r6 = BorderRadius.circular(6);

BorderRadius? _radius(WidgetTester tester, Finder of) {
  final LiquidGlassSurface s = tester.widget<LiquidGlassSurface>(
    find.descendant(of: of, matching: find.byType(LiquidGlassSurface)).first,
  );
  return s.borderRadius?.resolve(TextDirection.ltr) ?? s.style?.borderRadius;
}

void main() {
  setUp(LiquidGlassShaders.debugReset);

  testWidgets('style borderRadius is honored by button, text field, card', (
    tester,
  ) async {
    final LiquidGlassStyle square = const LiquidGlassStyle().copyWith(
      borderRadius: _r6,
    );
    await tester.pumpWidget(
      harness(
        SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LiquidGlassButton(
                style: square,
                onPressed: () {},
                child: const Text('B'),
              ),
              LiquidGlassTextField(style: square),
              LiquidGlassCard(style: square, child: const Text('C')),
              LiquidGlassCard(
                borderRadius: BorderRadius.circular(2),
                child: const Text('D'),
              ),
            ],
          ),
        ),
      ),
    );
    expect(_radius(tester, find.byType(LiquidGlassButton)), _r6);
    expect(_radius(tester, find.byType(LiquidGlassTextField)), _r6);
    expect(_radius(tester, find.byType(LiquidGlassCard).first), _r6);
    expect(
      _radius(tester, find.byType(LiquidGlassCard).last),
      BorderRadius.circular(2),
    );
  });

  testWidgets('icon button is a circle by default and accepts a radius', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LiquidGlassIconButton(
              key: const Key('round'),
              icon: const Icon(Icons.add),
              semanticLabel: 'Round',
              onPressed: () {},
            ),
            LiquidGlassIconButton(
              key: const Key('square'),
              icon: const Icon(Icons.add),
              semanticLabel: 'Square',
              borderRadius: _r6,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
    expect(
      _radius(tester, find.byKey(const Key('round'))),
      BorderRadius.circular(22),
    );
    expect(_radius(tester, find.byKey(const Key('square'))), _r6);
  });

  testWidgets('segmented control track and indicator follow borderRadius', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        SizedBox(
          width: 300,
          child: LiquidGlassSegmentedControl<int>(
            segments: const <int, Widget>{0: Text('A'), 1: Text('B')},
            selected: 0,
            onChanged: (_) {},
            borderRadius: _r6,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final List<BorderRadius?> radii = tester
        .widgetList<LiquidGlassSurface>(
          find.descendant(
            of: find.byType(LiquidGlassSegmentedControl<int>),
            matching: find.byType(LiquidGlassSurface),
          ),
        )
        .map((LiquidGlassSurface s) => s.style?.borderRadius)
        .toList();
    expect(radii, everyElement(_r6));
  });

  group('navigation bar', () {
    Widget bar({BorderRadius? radius, LiquidGlassDropStyle? drop}) => SizedBox(
      width: 400,
      child: LiquidGlassNavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        borderRadius: radius,
        dropStyle: drop ?? const LiquidGlassDropStyle(),
        destinations: const <LiquidGlassNavigationDestination>[
          LiquidGlassNavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          LiquidGlassNavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
      ),
    );

    testWidgets('capsule is a pill by default and accepts a radius', (
      tester,
    ) async {
      await tester.pumpWidget(harness(bar()));
      await tester.pumpAndSettle();
      expect(
        _radius(tester, find.byType(LiquidGlassNavigationBar)),
        BorderRadius.circular(32),
      );
      await tester.pumpWidget(harness(bar(radius: _r6)));
      await tester.pumpAndSettle();
      expect(_radius(tester, find.byType(LiquidGlassNavigationBar)), _r6);
    });

    for (final (LiquidGlassDropShape shape, double expected) in const [
      (LiquidGlassDropShape.capsule, 24),
      (LiquidGlassDropShape.circle, 24),
      (LiquidGlassDropShape.roundedRectangle, 10),
    ]) {
      testWidgets('drop shape ${shape.name} changes the indicator', (
        tester,
      ) async {
        await tester.pumpWidget(
          harness(
            bar(
              drop: LiquidGlassDropStyle(
                shape: shape,
                size: const Size(80, 48),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final List<LiquidGlassSurface> surfaces = tester
            .widgetList<LiquidGlassSurface>(
              find.descendant(
                of: find.byType(LiquidGlassNavigationBar),
                matching: find.byType(LiquidGlassSurface),
              ),
            )
            .toList();
        final LiquidGlassSurface drop = surfaces.last;
        expect(drop.style!.borderRadius, BorderRadius.circular(expected));
        final Size size = tester.getSize(find.byWidget(drop));
        if (shape == LiquidGlassDropShape.circle) {
          expect(size.width, closeTo(size.height, 0.01));
        } else {
          expect(size.width, closeTo(80, 0.01));
        }
      });
    }
  });
}
