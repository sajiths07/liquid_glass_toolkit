// Route futures are resolved by pumping, not awaited.
// ignore_for_file: unawaited_futures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_toolkit/liquid_glass_toolkit.dart';
import 'package:liquid_glass_toolkit/src/overlays/liquid_glass_overlays.dart'
    show glassMorphDestination;

import 'helpers.dart';

void main() {
  setUp(LiquidGlassShaders.debugReset);

  group('LiquidGlassScaffold', () {
    testWidgets('pads the body for the bars so content scrolls under glass', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
      addTearDown(tester.view.reset);
      late EdgeInsets bodyPadding;
      await tester.pumpWidget(
        MaterialApp(
          home: LiquidGlassScaffold(
            appBar: const LiquidGlassAppBar(title: Text('Title')),
            navigationBar: LiquidGlassNavigationBar(
              selectedIndex: 0,
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
              ],
            ),
            body: Builder(
              builder: (BuildContext context) {
                bodyPadding = MediaQuery.paddingOf(context);
                return ListView(children: const <Widget>[Text('first')]);
              },
            ),
          ),
        ),
      );
      expect(bodyPadding.top, 47 + 56);
      expect(tester.getSize(find.byType(LiquidGlassAppBar)).height, 47 + 56);
      expect(bodyPadding.bottom, 34 + 64 + 12);
      // The first list item starts below the app bar.
      final Rect appBar = tester.getRect(find.byType(LiquidGlassAppBar));
      expect(
        tester.getTopLeft(find.text('first')).dy,
        greaterThanOrEqualTo(appBar.bottom - 1),
      );
      // Dark icons for a light app.
      final AnnotatedRegion<SystemUiOverlayStyle> region = tester.widget(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
      );
      expect(region.value, SystemUiOverlayStyle.dark);
    });

    testWidgets('lays out without overflow on small and large screens', (
      tester,
    ) async {
      for (final Size size in const <Size>[
        Size(320, 568),
        Size(1280, 800),
        Size(800, 1280),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            home: LiquidGlassScaffold(
              appBar: LiquidGlassAppBar(
                title: const Text('A rather long title for a narrow screen'),
                actions: <Widget>[
                  LiquidGlassIconButton(
                    icon: const Icon(Icons.add),
                    semanticLabel: 'Add',
                    onPressed: () {},
                  ),
                ],
              ),
              navigationBar: LiquidGlassNavigationBar(
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
                    label: 'Profile',
                  ),
                  LiquidGlassNavigationDestination(
                    icon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              ),
              body: const SizedBox.expand(),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: 'at $size');
      }
      tester.view.reset();
    });

    testWidgets('survives large text scaling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: LiquidGlassScaffold(
            appBar: const LiquidGlassAppBar(title: Text('Settings')),
            navigationBar: LiquidGlassNavigationBar(
              selectedIndex: 0,
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
              ],
            ),
            body: Center(
              child: LiquidGlassButton(
                onPressed: () {},
                child: const Text('Scaled'),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('LiquidGlassNavigationBar', () {
    testWidgets('selects destinations with semantics', (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      int index = 0;
      await tester.pumpWidget(
        harness(
          SizedBox(
            width: 360,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) =>
                  LiquidGlassNavigationBar(
                    selectedIndex: index,
                    onDestinationSelected: (int i) => setState(() => index = i),
                    destinations: const <LiquidGlassNavigationDestination>[
                      LiquidGlassNavigationDestination(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      LiquidGlassNavigationDestination(
                        icon: Icon(Icons.favorite_border),
                        selectedIcon: Icon(Icons.favorite),
                        label: 'Likes',
                      ),
                    ],
                  ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Likes'));
      await tester.pumpAndSettle();
      expect(index, 1);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      semantics.dispose();
    });
  });

  testWidgets('app bar shows a back button that pops', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Center(
            child: LiquidGlassButton(
              onPressed: () => Navigator.of(context).push(
                LiquidGlassPageRoute<void>(
                  builder: (_) => const LiquidGlassScaffold(
                    appBar: LiquidGlassAppBar(title: Text('Detail')),
                    body: SizedBox.expand(),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Detail'), findsOneWidget);
    await tester.tap(find.byType(LiquidGlassBackButton));
    await tester.pumpAndSettle();
    expect(find.text('Detail'), findsNothing);
  });

  group('page transitions', () {
    testWidgets('LiquidGlassPageRoute uses the configured duration', (
      tester,
    ) async {
      final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(navigatorKey: nav, home: const SizedBox()),
      );
      nav.currentState!.push(
        LiquidGlassPageRoute<void>(
          animationConfig: const LiquidGlassAnimationConfig(
            duration: Duration(milliseconds: 1000),
            curve: Curves.linear,
          ),
          builder: (_) =>
              const ColoredBox(color: Colors.red, child: Text('page')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final double x = tester.getTopLeft(find.text('page')).dx;
      expect(x, greaterThan(100), reason: 'still sliding at half time');
      await tester.pump(const Duration(milliseconds: 520));
      expect(tester.getTopLeft(find.text('page')).dx, closeTo(0, 0.5));
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('page'), findsNothing);
    });

    testWidgets('PageTransitionsBuilder integrates with ThemeData', (
      tester,
    ) async {
      final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: LiquidGlassPageTransitionsBuilder(),
              },
            ),
          ),
          home: const SizedBox(),
        ),
      );
      nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Text('next')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(LiquidGlassPageTransition), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.text('next'), findsOneWidget);
    });

    testWidgets('reduced motion cross-fades instead of sliding', (
      tester,
    ) async {
      final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const SizedBox(),
        ),
      );
      nav.currentState!.push(
        LiquidGlassPageRoute<void>(builder: (_) => const Text('calm')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.getTopLeft(find.text('calm')).dx, 0);
      await tester.pumpAndSettle();
    });
  });

  group('dialog', () {
    testWidgets('presents, returns a value and dismisses', (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      String? result;
      await tester.pumpWidget(
        harness(
          Builder(
            builder: (BuildContext context) => LiquidGlassButton(
              onPressed: () async {
                result = await showLiquidGlassDialog<String>(
                  context: context,
                  builder: (BuildContext context) => LiquidGlassDialog(
                    title: const Text('Delete?'),
                    content: const Text('This cannot be undone.'),
                    actions: <Widget>[
                      LiquidGlassButton(
                        onPressed: () => Navigator.pop(context, 'cancel'),
                        child: const Text('Cancel'),
                      ),
                      LiquidGlassButton(
                        prominent: true,
                        onPressed: () => Navigator.pop(context, 'ok'),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Mid-transition the glass is partially present.
      final LiquidGlassPresence presence = tester.widget(
        find
            .ancestor(
              of: find.text('Delete?'),
              matching: find.byType(LiquidGlassPresence),
            )
            .last,
      );
      expect(presence.value, greaterThan(0));
      await tester.pumpAndSettle();
      expect(find.text('This cannot be undone.'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Delete?')).flagsCollection.isHeader,
        isTrue,
      );
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(result, 'ok');
      expect(find.text('Delete?'), findsNothing);
      semantics.dispose();
    });

    testWidgets('barrier tap dismisses with null', (tester) async {
      bool closed = false;
      await tester.pumpWidget(
        harness(
          Builder(
            builder: (BuildContext context) => LiquidGlassButton(
              onPressed: () async {
                final Object? r = await showLiquidGlassDialog<Object>(
                  context: context,
                  builder: (_) => const LiquidGlassDialog(title: Text('Hi')),
                );
                closed = r == null;
              },
              child: const Text('Show'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(closed, isTrue);
      expect(find.text('Hi'), findsNothing);
    });

    testWidgets('dialog captures LiquidGlassTheme from the caller', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          Builder(
            builder: (BuildContext context) => LiquidGlassButton(
              onPressed: () => showLiquidGlassDialog<void>(
                context: context,
                builder: (_) => const LiquidGlassDialog(title: Text('Themed')),
              ),
              child: const Text('Show'),
            ),
          ),
          glass: LiquidGlassThemeData.light(
            quality: LiquidGlassQuality.minimal,
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      final BuildContext dialogContext = tester.element(find.text('Themed'));
      expect(
        LiquidGlassTheme.of(dialogContext).quality,
        LiquidGlassQuality.minimal,
      );
    });
  });

  group('sheet', () {
    Widget sheetHarness() => harness(
      Builder(
        builder: (BuildContext context) => LiquidGlassButton(
          onPressed: () => showLiquidGlassSheet<void>(
            context: context,
            builder: (_) => const SizedBox(
              height: 300,
              child: Center(child: Text('Sheet body')),
            ),
          ),
          child: const Text('Open sheet'),
        ),
      ),
    );

    testWidgets('slides up and is dismissed by a downward fling', (
      tester,
    ) async {
      await tester.pumpWidget(sheetHarness());
      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet body'), findsOneWidget);
      await tester.fling(find.text('Sheet body'), const Offset(0, 300), 1500);
      await tester.pumpAndSettle();
      expect(find.text('Sheet body'), findsNothing);
    });

    testWidgets('springs back after a short drag', (tester) async {
      await tester.pumpWidget(sheetHarness());
      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();
      final double before = tester.getTopLeft(find.text('Sheet body')).dy;
      await tester.timedDrag(
        find.text('Sheet body'),
        const Offset(0, 40),
        const Duration(milliseconds: 500),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sheet body'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Sheet body')).dy,
        closeTo(before, 0.5),
      );
    });
  });

  group('morph and menu', () {
    test('destination is placed below the trigger when it fits', () {
      final Rect d = glassMorphDestination(
        source: const Rect.fromLTWH(20, 100, 100, 44),
        size: const Size(200, 150),
        bounds: const Rect.fromLTWH(0, 0, 400, 800),
        textDirection: TextDirection.ltr,
      );
      expect(d, const Rect.fromLTWH(20, 152, 200, 150));
    });

    test('destination flips above and stays inside bounds', () {
      final Rect d = glassMorphDestination(
        source: const Rect.fromLTWH(300, 700, 80, 44),
        size: const Size(200, 150),
        bounds: const Rect.fromLTWH(10, 10, 380, 780),
        textDirection: TextDirection.ltr,
      );
      expect(d.bottom, lessThanOrEqualTo(700));
      expect(d.right, lessThanOrEqualTo(390));
      expect(d.left, greaterThanOrEqualTo(10));
    });

    test('destination is clamped when larger than the screen', () {
      final Rect d = glassMorphDestination(
        source: const Rect.fromLTWH(0, 0, 40, 40),
        size: const Size(1000, 1000),
        bounds: const Rect.fromLTWH(0, 0, 300, 500),
        textDirection: TextDirection.rtl,
      );
      expect(d, const Rect.fromLTWH(0, 0, 300, 500));
    });

    testWidgets('menu morphs from the trigger, selects and collapses back', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        harness(
          LiquidGlassMenuButton(
            semanticLabel: 'More',
            items: <LiquidGlassMenuItem>[
              LiquidGlassMenuItem(
                label: 'Copy',
                leading: const Icon(Icons.copy),
                onPressed: () => picked = 'copy',
              ),
              LiquidGlassMenuItem(
                label: 'Delete',
                destructive: true,
                onPressed: () => picked = 'delete',
              ),
              const LiquidGlassMenuItem(label: 'Disabled'),
            ],
            child: const Text('Menu'),
          ),
        ),
      );
      final Rect trigger = tester.getRect(find.byType(LiquidGlassButton));
      await tester.tap(find.text('Menu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      // At the very start the morphing surface coincides with the trigger.
      final Rect start = tester.getRect(find.byType(LiquidGlassSurface).last);
      expect(start.left, closeTo(trigger.left, 2));
      expect(start.top, closeTo(trigger.top, 2));
      await tester.pumpAndSettle();
      final Rect open = tester.getRect(find.byType(LiquidGlassSurface).last);
      expect(open.width, closeTo(240, 0.5));
      expect(open.top, greaterThan(trigger.bottom));
      expect(find.text('Copy'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final Rect closing = tester.getRect(find.byType(LiquidGlassSurface).last);
      expect(closing.height, lessThan(open.height));
      await tester.pumpAndSettle();
      expect(picked, 'delete');
      expect(find.text('Copy'), findsNothing);
    });

    testWidgets('morph survives interruption (dismiss mid-open)', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          Builder(
            builder: (BuildContext context) => LiquidGlassButton(
              onPressed: () => showLiquidGlassMorph<void>(
                context: context,
                size: const Size(200, 120),
                builder: (_) => const Text('Panel'),
              ),
              child: const Text('Morph'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Morph'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Panel'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('implicit transitions', () {
    testWidgets(
      'LiquidGlassAppear animates in and out with a duration override',
      (tester) async {
        Widget build(bool visible) => harness(
          LiquidGlassAppear(
            visible: visible,
            animation: const LiquidGlassAnimationConfig(
              duration: Duration(milliseconds: 400),
              curve: Curves.linear,
            ),
            child: const LiquidGlassSurface(child: Text('hello')),
          ),
        );
        await tester.pumpWidget(build(false));
        expect(find.text('hello'), findsNothing);
        await tester.pumpWidget(build(true));
        await tester.pump(const Duration(milliseconds: 200));
        final LiquidGlassPresence mid = tester.widget(
          find.byType(LiquidGlassPresence).first,
        );
        expect(mid.value, closeTo(0.5, 0.05));
        await tester.pumpAndSettle();
        expect(find.text('hello'), findsOneWidget);
        await tester.pumpWidget(build(false));
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          find.text('hello'),
          findsOneWidget,
          reason: 'still animating out',
        );
        await tester.pumpAndSettle();
        expect(find.text('hello'), findsNothing);
      },
    );

    testWidgets('AnimatedLiquidGlassSurface interpolates style changes', (
      tester,
    ) async {
      Widget build(double blur) => harness(
        AnimatedLiquidGlassSurface(
          style: LiquidGlassStyle(blur: blur),
          animation: const LiquidGlassAnimationConfig(
            duration: Duration(milliseconds: 400),
            curve: Curves.linear,
          ),
          child: const SizedBox(width: 40, height: 40),
        ),
      );
      await tester.pumpWidget(build(0));
      await tester.pumpWidget(build(20));
      await tester.pump(const Duration(milliseconds: 200));
      final LiquidGlassSurface s = tester.widget(
        find.byType(LiquidGlassSurface),
      );
      expect(s.style!.blur, closeTo(10, 0.5));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LiquidGlassSurface>(find.byType(LiquidGlassSurface))
            .style!
            .blur,
        20,
      );
    });
  });
}
