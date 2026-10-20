import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widget/liquid_glass_widget.dart';

import 'helpers.dart';

void main() {
  setUp(LiquidGlassShaders.debugReset);

  group('LiquidGlassButton', () {
    testWidgets('taps, exposes button semantics and meets touch target', (
      tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      int taps = 0;
      await tester.pumpWidget(
        harness(
          LiquidGlassButton(onPressed: () => taps++, child: const Text('Go')),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(
        tester.getSemantics(find.byType(LiquidGlassButton)),
        matchesSemantics(
          label: 'Go',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      final Size size = tester.getSize(find.byType(LiquidGlassSurface));
      expect(size.height, greaterThanOrEqualTo(44));
      expect(size.width, greaterThanOrEqualTo(44));
      semantics.dispose();
    });

    testWidgets('disabled button ignores taps and reports disabled', (
      tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        harness(const LiquidGlassButton(onPressed: null, child: Text('No'))),
      );
      await tester.tap(find.text('No'), warnIfMissed: false);
      await tester.pumpAndSettle();
      final SemanticsNode node = tester.getSemantics(
        find.byType(LiquidGlassButton),
      );
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      semantics.dispose();
    });

    testWidgets('press feedback scales down and springs back', (tester) async {
      await tester.pumpWidget(
        harness(
          LiquidGlassButton(onPressed: () {}, child: const Text('Press')),
        ),
      );
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('Press')),
      );
      // Tap-down is delivered after the press timeout; the press animation
      // then needs further frames.
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));
      final Transform pressed = tester.widget<Transform>(
        find
            .descendant(
              of: find.byType(LiquidGlassButton),
              matching: find.byType(Transform),
            )
            .first,
      );
      expect(pressed.transform.storage[0], lessThan(1));
      await gesture.up();
      await tester.pumpAndSettle();
      final Transform released = tester.widget<Transform>(
        find
            .descendant(
              of: find.byType(LiquidGlassButton),
              matching: find.byType(Transform),
            )
            .first,
      );
      expect(released.transform.storage[0], closeTo(1, 1e-6));
    });

    testWidgets('reduced motion disables press scaling', (tester) async {
      await tester.pumpWidget(
        harness(
          LiquidGlassButton(onPressed: () {}, child: const Text('Press')),
          disableAnimations: true,
        ),
      );
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('Press')),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final Transform t = tester.widget<Transform>(
        find
            .descendant(
              of: find.byType(LiquidGlassButton),
              matching: find.byType(Transform),
            )
            .first,
      );
      expect(t.transform.storage[0], 1);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('keyboard activation with Enter and Space', (tester) async {
      int taps = 0;
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        harness(
          LiquidGlassButton(
            focusNode: node,
            onPressed: () => taps++,
            child: const Text('Key'),
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(taps, 2);
    });

    testWidgets('prominent button uses the accent tint', (tester) async {
      await tester.pumpWidget(
        harness(
          LiquidGlassButton(
            prominent: true,
            onPressed: () {},
            child: const Text('Buy'),
          ),
          glass: LiquidGlassThemeData.light(accentColor: Colors.green),
        ),
      );
      final LiquidGlassSurface surface = tester.widget(
        find.byType(LiquidGlassSurface),
      );
      expect(surface.style!.tintColor.toARGB32(), Colors.green.toARGB32());
    });
  });

  testWidgets('LiquidGlassIconButton has a semantic label and 44 px target', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    int taps = 0;
    await tester.pumpWidget(
      harness(
        LiquidGlassIconButton(
          icon: const Icon(Icons.add),
          semanticLabel: 'Add',
          size: 32,
          onPressed: () => taps++,
        ),
      ),
    );
    expect(find.bySemanticsLabel('Add'), findsOneWidget);
    expect(
      tester.getSize(find.byType(LiquidGlassIconButton)),
      const Size(44, 44),
    );
    await tester.tap(find.byType(LiquidGlassIconButton));
    await tester.pumpAndSettle();
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('LiquidGlassCard is static without onTap and pressable with it', (
    tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      harness(const LiquidGlassCard(child: Text('static'))),
    );
    expect(find.byType(FocusableActionDetector), findsNothing);
    await tester.pumpWidget(
      harness(LiquidGlassCard(onTap: () => taps++, child: const Text('tap'))),
    );
    await tester.tap(find.text('tap'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  group('LiquidGlassSwitch', () {
    testWidgets('toggles on tap and reports toggled semantics', (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      bool value = false;
      await tester.pumpWidget(
        harness(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) =>
                LiquidGlassSwitch(
                  value: value,
                  semanticLabel: 'Wi-Fi',
                  onChanged: (bool v) => setState(() => value = v),
                ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(LiquidGlassSwitch)),
        matchesSemantics(
          label: 'Wi-Fi',
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await tester.tap(find.byType(LiquidGlassSwitch));
      await tester.pumpAndSettle();
      expect(value, isTrue);
      expect(
        tester
            .getSemantics(find.byType(LiquidGlassSwitch))
            .flagsCollection
            .isToggled,
        Tristate.isTrue,
      );
      semantics.dispose();
    });

    testWidgets('dragging the thumb switches on', (tester) async {
      bool value = false;
      await tester.pumpWidget(
        harness(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) =>
                LiquidGlassSwitch(
                  value: value,
                  onChanged: (bool v) => setState(() => value = v),
                ),
          ),
        ),
      );
      await tester.drag(find.byType(LiquidGlassSwitch), const Offset(40, 0));
      await tester.pumpAndSettle();
      expect(value, isTrue);
    });

    testWidgets('springs back when the parent rejects the change', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(LiquidGlassSwitch(value: false, onChanged: (_) {})),
      );
      await tester.tap(find.byType(LiquidGlassSwitch));
      await tester.pumpAndSettle();
      // Thumb returned to the off position (left inset).
      final Rect thumb = tester.getRect(find.byType(LiquidGlassSurface).last);
      final Rect track = tester.getRect(find.byType(LiquidGlassSurface).first);
      expect(thumb.left - track.left, closeTo(3, 0.5));
    });

    testWidgets('disabled switch does not toggle', (tester) async {
      await tester.pumpWidget(
        harness(const LiquidGlassSwitch(value: false, onChanged: null)),
      );
      await tester.tap(find.byType(LiquidGlassSwitch), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('LiquidGlassSlider', () {
    Widget slider(
      ValueNotifier<double> v, {
      int? divisions,
      TextDirection dir = TextDirection.ltr,
      FocusNode? focusNode,
    }) {
      return harness(
        SizedBox(
          width: 300,
          child: ValueListenableBuilder<double>(
            valueListenable: v,
            builder: (BuildContext context, double value, _) =>
                LiquidGlassSlider(
                  value: value,
                  divisions: divisions,
                  focusNode: focusNode,
                  semanticLabel: 'Volume',
                  onChanged: (double n) => v.value = n,
                ),
          ),
        ),
        textDirection: dir,
      );
    }

    testWidgets('tapping the track sets the value', (tester) async {
      final ValueNotifier<double> v = ValueNotifier<double>(0);
      addTearDown(v.dispose);
      await tester.pumpWidget(slider(v));
      final Rect r = tester.getRect(find.byType(LiquidGlassSlider));
      await tester.tapAt(Offset(r.right - 17, r.center.dy));
      await tester.pumpAndSettle();
      expect(v.value, closeTo(1, 0.02));
    });

    testWidgets('respects divisions', (tester) async {
      final ValueNotifier<double> v = ValueNotifier<double>(0);
      addTearDown(v.dispose);
      await tester.pumpWidget(slider(v, divisions: 4));
      final Rect r = tester.getRect(find.byType(LiquidGlassSlider));
      await tester.tapAt(Offset(r.left + r.width * 0.42, r.center.dy));
      await tester.pumpAndSettle();
      expect(v.value * 4, closeTo((v.value * 4).roundToDouble(), 1e-9));
    });

    testWidgets('right-to-left mirrors the direction', (tester) async {
      final ValueNotifier<double> v = ValueNotifier<double>(0.5);
      addTearDown(v.dispose);
      await tester.pumpWidget(slider(v, dir: TextDirection.rtl));
      final Rect r = tester.getRect(find.byType(LiquidGlassSlider));
      await tester.tapAt(Offset(r.left + 17, r.center.dy));
      await tester.pumpAndSettle();
      expect(v.value, closeTo(1, 0.02));
    });

    testWidgets('semantics increase/decrease and arrow keys', (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final ValueNotifier<double> v = ValueNotifier<double>(0.5);
      addTearDown(v.dispose);
      final FocusNode focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(slider(v, divisions: 10, focusNode: focus));
      final SemanticsNode node = tester.getSemantics(
        find.byType(LiquidGlassSlider),
      );
      expect(node.value, '50%');
      expect(node.increasedValue, '60%');
      tester.semantics.performAction(
        find.semantics.byLabel('Volume'),
        SemanticsAction.increase,
      );
      await tester.pumpAndSettle();
      expect(v.value, closeTo(0.6, 1e-9));

      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(v.value, closeTo(0.5, 1e-9));
      semantics.dispose();
    });
  });

  group('LiquidGlassSegmentedControl', () {
    testWidgets('selects segments and indicator settles under selection', (
      tester,
    ) async {
      String selected = 'a';
      await tester.pumpWidget(
        harness(
          SizedBox(
            width: 300,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) =>
                  LiquidGlassSegmentedControl<String>(
                    segments: const <String, Widget>{
                      'a': Text('Alpha'),
                      'b': Text('Beta'),
                      'c': Text('Gamma'),
                    },
                    selected: selected,
                    onChanged: (String v) => setState(() => selected = v),
                  ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Gamma'));
      await tester.pump(const Duration(milliseconds: 16));
      expect(selected, 'c');
      await tester.pumpAndSettle();
      final Rect indicator = tester.getRect(
        find.byType(LiquidGlassSurface).at(1),
      );
      final Rect gamma = tester.getRect(find.text('Gamma'));
      expect(indicator.center.dx, closeTo(gamma.center.dx, 2));
    });

    testWidgets('exposes selected state in a mutually exclusive group', (
      tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        harness(
          SizedBox(
            width: 300,
            child: LiquidGlassSegmentedControl<int>(
              segments: const <int, Widget>{1: Text('One'), 2: Text('Two')},
              selected: 2,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      final SemanticsNode two = tester.getSemantics(find.text('Two'));
      expect(two.flagsCollection.isSelected, Tristate.isTrue);
      expect(two.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      semantics.dispose();
    });

    testWidgets('dragging the indicator selects the nearest segment', (
      tester,
    ) async {
      int selected = 0;
      await tester.pumpWidget(
        harness(
          SizedBox(
            width: 300,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) =>
                  LiquidGlassSegmentedControl<int>(
                    segments: const <int, Widget>{
                      0: Text('A'),
                      1: Text('B'),
                      2: Text('C'),
                    },
                    selected: selected,
                    onChanged: (int v) => setState(() => selected = v),
                  ),
            ),
          ),
        ),
      );
      await tester.timedDrag(
        find.text('A'),
        const Offset(200, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();
      expect(selected, 2);
    });
  });

  group('LiquidGlassTextField', () {
    testWidgets('accepts input and highlights focus', (tester) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);
      String? submitted;
      await tester.pumpWidget(
        harness(
          SizedBox(
            width: 300,
            child: LiquidGlassTextField(
              controller: controller,
              placeholder: 'Search',
              onSubmitted: (String v) => submitted = v,
            ),
          ),
          glass: LiquidGlassThemeData.light(accentColor: Colors.orange),
        ),
      );
      expect(find.text('Search'), findsOneWidget);
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      final LiquidGlassSurface surface = tester.widget(
        find.byType(LiquidGlassSurface),
      );
      expect(surface.style!.borderColor.toARGB32(), Colors.orange.toARGB32());
      await tester.enterText(find.byType(EditableText), 'glass');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(controller.text, 'glass');
      expect(submitted, 'glass');
    });

    testWidgets('owned focus node is disposed with the field', (tester) async {
      await tester.pumpWidget(
        harness(const SizedBox(width: 200, child: LiquidGlassTextField())),
      );
      await tester.pumpWidget(harness(const SizedBox()));
      expect(tester.takeException(), isNull);
    });
  });
}
