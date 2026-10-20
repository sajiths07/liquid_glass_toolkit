import 'package:flutter/material.dart';
import 'package:liquid_glass_ui/liquid_glass_ui.dart';

/// Wraps [child] in a MaterialApp with a colorful background so glass has
/// something to blur.
Widget harness(
  Widget child, {
  ThemeData? theme,
  ThemeMode themeMode = ThemeMode.light,
  LiquidGlassThemeData? glass,
  bool disableAnimations = false,
  bool highContrast = false,
  TextDirection textDirection = TextDirection.ltr,
  double textScale = 1,
}) {
  Widget body = Stack(
    children: <Widget>[
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[Color(0xFF3A7BD5), Color(0xFFF7797D)],
            ),
          ),
        ),
      ),
      Center(child: child),
    ],
  );
  if (glass != null) body = LiquidGlassTheme(data: glass, child: body);
  return MaterialApp(
    theme: theme ?? ThemeData.light(),
    darkTheme: ThemeData.dark(),
    themeMode: themeMode,
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: disableAnimations,
        highContrast: highContrast,
        textScaler: TextScaler.linear(textScale),
      ),
      child: Directionality(textDirection: textDirection, child: child!),
    ),
    home: Scaffold(backgroundColor: Colors.transparent, body: body),
  );
}
