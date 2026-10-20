import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
// The import path published in 0.1.0 - 0.4.0.
import 'package:liquid_glass_ui/widgets/liquid_glass_container.dart';

void main() {
  testWidgets('0.x import path exposes LiquidGlassContainer', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: LiquidGlassContainer(
            blur: 18,
            opacity: 0.2,
            padding: EdgeInsets.all(24),
            child: Text('Liquid Glass UI'),
          ),
        ),
      ),
    );
    expect(find.text('Liquid Glass UI'), findsOneWidget);
  });
}
