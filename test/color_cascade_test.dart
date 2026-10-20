import 'package:flutter/cupertino.dart' show CupertinoTextField;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widget/liquid_glass_widget.dart';

import 'helpers.dart';

const Color _red = Color(0xFFE53935);
const Color _green = Color(0xFF43A047);
const Color _purple = Color(0xFF8E24AA);
const Color _orange = Color(0xFFFB8C00);
const Color _themeAccent = Color(0xFF00A0B0);
const Color _themeSecondary = Color(0xFF607D8B);

final LiquidGlassThemeData _glass = LiquidGlassThemeData.light(
  accentColor: _themeAccent,
  secondaryForegroundColor: _themeSecondary,
);

Color? _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

Color? _defaultTextColor(WidgetTester tester, String text) =>
    DefaultTextStyle.of(tester.element(find.text(text))).style.color;

Color? _surfaceForeground(WidgetTester tester, Finder of) => tester
    .widget<LiquidGlassSurface>(
      find.descendant(of: of, matching: find.byType(LiquidGlassSurface)).first,
    )
    .foregroundColor;

void main() {
  setUp(LiquidGlassShaders.debugReset);

  group('LiquidGlassThemeData colors', () {
    test('defaults', () {
      final LiquidGlassThemeData light = LiquidGlassThemeData.light();
      expect(light.destructiveColor, const Color(0xFFFF3B30));
      expect(light.onAccentColor, const Color(0xFFFFFFFF));
      expect(light.secondaryForegroundColor, isNull);
      expect(
        light.effectiveSecondaryForegroundColor,
        light.foregroundColor.withValues(alpha: 0.72),
      );
      expect(
        LiquidGlassThemeData.dark().destructiveColor,
        const Color(0xFFFF453A),
      );
    });

    test('factories accept every color', () {
      final LiquidGlassThemeData t = LiquidGlassThemeData.dark(
        foregroundColor: _red,
        accentColor: _green,
        secondaryForegroundColor: _purple,
        onAccentColor: _orange,
        destructiveColor: _themeAccent,
      );
      expect(t.foregroundColor, _red);
      expect(t.accentColor, _green);
      expect(t.effectiveSecondaryForegroundColor, _purple);
      expect(t.onAccentColor, _orange);
      expect(t.destructiveColor, _themeAccent);
    });

    test('copyWith, equality and lerp include the new colors', () {
      final LiquidGlassThemeData a = LiquidGlassThemeData.light();
      final LiquidGlassThemeData b = a.copyWith(
        secondaryForegroundColor: _purple,
        onAccentColor: _orange,
        destructiveColor: _green,
      );
      expect(a == b, isFalse);
      expect(
        b,
        a.copyWith(
          secondaryForegroundColor: _purple,
          onAccentColor: _orange,
          destructiveColor: _green,
        ),
      );
      expect(a.lerp(b, 1).destructiveColor, _green);
      expect(a.lerp(b, 1).onAccentColor, _orange);
      expect(a.lerp(b, 1).secondaryForegroundColor, _purple);
    });
  });

  group('navigation bar', () {
    Widget bar({
      Color? selected,
      Color? unselected,
      List<LiquidGlassNavigationDestination>? destinations,
    }) => SizedBox(
      width: 400,
      child: LiquidGlassNavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        selectedColor: selected,
        unselectedColor: unselected,
        destinations:
            destinations ??
            const <LiquidGlassNavigationDestination>[
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

    testWidgets('falls back to the theme colors', (tester) async {
      await tester.pumpWidget(harness(bar(), glass: _glass));
      await tester.pumpAndSettle();
      expect(_textColor(tester, 'Home'), _themeAccent);
      expect(_textColor(tester, 'Search'), _themeSecondary);
    });

    testWidgets('bar colors override the theme', (tester) async {
      await tester.pumpWidget(
        harness(
          bar(selected: _red, unselected: _green),
          glass: _glass,
        ),
      );
      await tester.pumpAndSettle();
      expect(_textColor(tester, 'Home'), _red);
      expect(_textColor(tester, 'Search'), _green);
    });

    testWidgets('destination colors override the bar', (tester) async {
      await tester.pumpWidget(
        harness(
          bar(
            selected: _red,
            unselected: _green,
            destinations: const <LiquidGlassNavigationDestination>[
              LiquidGlassNavigationDestination(
                icon: Icon(Icons.home),
                label: 'Home',
                selectedColor: _purple,
              ),
              LiquidGlassNavigationDestination(
                icon: Icon(Icons.search),
                label: 'Search',
                unselectedColor: _orange,
              ),
              LiquidGlassNavigationDestination(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
          glass: _glass,
        ),
      );
      await tester.pumpAndSettle();
      expect(_textColor(tester, 'Home'), _purple);
      expect(_textColor(tester, 'Search'), _orange);
      expect(_textColor(tester, 'Settings'), _green);
      expect(
        IconTheme.of(tester.element(find.byIcon(Icons.home))).color,
        _purple,
      );
    });
  });

  testWidgets('segmented control cascades per segment, widget, theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        SizedBox(
          width: 360,
          child: LiquidGlassSegmentedControl<int>(
            segments: const <int, Widget>{
              0: Text('A'),
              1: Text('B'),
              2: Text('C'),
            },
            selected: 0,
            onChanged: (_) {},
            unselectedColor: _green,
            selectedColors: const <int, Color>{0: _red},
            unselectedColors: const <int, Color>{2: _orange},
          ),
        ),
        glass: _glass,
      ),
    );
    await tester.pumpAndSettle();
    expect(_defaultTextColor(tester, 'A'), _red);
    expect(_defaultTextColor(tester, 'B'), _green);
    expect(_defaultTextColor(tester, 'C'), _orange);
  });

  group('buttons', () {
    testWidgets('prominent button uses theme onAccent and accent', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          LiquidGlassButton(
            prominent: true,
            onPressed: () {},
            child: const Text('Go'),
          ),
          glass: _glass.copyWith(onAccentColor: _orange),
        ),
      );
      final Finder button = find.byType(LiquidGlassButton);
      expect(_surfaceForeground(tester, button), _orange);
      final LiquidGlassSurface surface = tester.widget<LiquidGlassSurface>(
        find.descendant(of: button, matching: find.byType(LiquidGlassSurface)),
      );
      expect(surface.style!.tintColor, _themeAccent);
    });

    testWidgets('button colors override the theme', (tester) async {
      await tester.pumpWidget(
        harness(
          LiquidGlassButton(
            prominent: true,
            color: _purple,
            foregroundColor: _green,
            onPressed: () {},
            child: const Text('Go'),
          ),
          glass: _glass,
        ),
      );
      final Finder button = find.byType(LiquidGlassButton);
      expect(_surfaceForeground(tester, button), _green);
      final LiquidGlassSurface surface = tester.widget<LiquidGlassSurface>(
        find.descendant(of: button, matching: find.byType(LiquidGlassSurface)),
      );
      expect(surface.style!.tintColor, _purple);
    });

    testWidgets('icon button and card colors', (tester) async {
      await tester.pumpWidget(
        harness(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LiquidGlassIconButton(
                icon: const Icon(Icons.add),
                semanticLabel: 'Add',
                color: _red,
                onPressed: () {},
              ),
              const LiquidGlassCard(
                foregroundColor: _green,
                child: Text('Card'),
              ),
            ],
          ),
          glass: _glass,
        ),
      );
      expect(
        _surfaceForeground(tester, find.byType(LiquidGlassIconButton)),
        _red,
      );
      expect(_defaultTextColor(tester, 'Card'), _green);
    });
  });

  testWidgets('app bar foreground cascades to its back button and title', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const SizedBox(
          width: 400,
          child: LiquidGlassAppBar(
            title: Text('Title'),
            leading: LiquidGlassBackButton(),
            foregroundColor: _red,
          ),
        ),
        glass: _glass,
      ),
    );
    expect(_defaultTextColor(tester, 'Title'), _red);
    expect(
      _surfaceForeground(tester, find.byType(LiquidGlassBackButton)),
      _red,
    );
  });

  testWidgets('text field colors', (tester) async {
    await tester.pumpWidget(
      harness(
        const SizedBox(
          width: 300,
          child: LiquidGlassTextField(
            placeholder: 'Search',
            foregroundColor: _green,
            placeholderColor: _orange,
            cursorColor: _red,
          ),
        ),
        glass: _glass,
      ),
    );
    final CupertinoTextField field = tester.widget<CupertinoTextField>(
      find.byType(CupertinoTextField),
    );
    expect(field.cursorColor, _red);
    expect(field.style!.color, _green);
    expect(field.placeholderStyle!.color, _orange);
  });

  testWidgets('switch and slider accept inactive and thumb colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LiquidGlassSwitch(
              value: false,
              onChanged: (_) {},
              inactiveColor: _red,
              thumbColor: _green,
            ),
            SizedBox(
              width: 200,
              child: LiquidGlassSlider(
                value: 0.5,
                onChanged: (_) {},
                inactiveColor: _purple,
                thumbColor: _orange,
              ),
            ),
          ],
        ),
        glass: _glass,
      ),
    );
    List<Color> tints(Type type) => tester
        .widgetList<LiquidGlassSurface>(
          find.descendant(
            of: find.byType(type),
            matching: find.byType(LiquidGlassSurface),
          ),
        )
        .map((LiquidGlassSurface s) => s.style!.tintColor)
        .toList();
    expect(tints(LiquidGlassSwitch), containsAll(<Color>[_red, _green]));
    expect(tints(LiquidGlassSlider), containsAll(<Color>[_purple, _orange]));
  });

  testWidgets('menu item color beats menu color beats theme color', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        LiquidGlassMenuButton(
          menuForegroundColor: _green,
          items: <LiquidGlassMenuItem>[
            LiquidGlassMenuItem(label: 'Own', color: _purple, onPressed: () {}),
            LiquidGlassMenuItem(label: 'Menu', onPressed: () {}),
            LiquidGlassMenuItem(
              label: 'Delete',
              destructive: true,
              onPressed: () {},
            ),
          ],
          child: const Text('Open'),
        ),
        glass: _glass.copyWith(destructiveColor: _orange),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(_textColor(tester, 'Own'), _purple);
    expect(_textColor(tester, 'Menu'), _green);
    expect(_textColor(tester, 'Delete'), _orange);
  });
}
