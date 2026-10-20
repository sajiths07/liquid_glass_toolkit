import 'package:flutter/material.dart';
import 'package:liquid_glass_toolkit/liquid_glass_toolkit.dart';

/// A small section header used across the demo pages.
class Section extends StatelessWidget {
  const Section({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Semantics(
        header: true,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: LiquidGlassTheme.of(context).foregroundColor,
            shadows: const <Shadow>[
              Shadow(color: Color(0x55FFFFFF), blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}
