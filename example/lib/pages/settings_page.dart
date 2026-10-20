import 'package:flutter/material.dart';
import 'package:liquid_glass_ui/liquid_glass_ui.dart';

import '../demo_config.dart';
import 'section.dart';

/// Live configuration of the app-wide glass theme.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const List<Color> _tints = <Color>[
    Colors.white,
    Color(0xFF0A84FF),
    Color(0xFFFF375F),
    Color(0xFF30D158),
    Color(0xFFFFD60A),
    Color(0xFF1C1C1E),
  ];

  @override
  Widget build(BuildContext context) {
    final DemoConfig c = DemoConfigScope.of(context);
    return ListView(
      padding: MediaQuery.paddingOf(context) + const EdgeInsets.all(16),
      children: <Widget>[
        SizedBox(
          height: 120,
          child: LiquidGlassSurface(
            child: Center(
              child: Text(
                'Preview · ${c.quality.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const Section(title: 'Material'),
        _Panel(
          children: <Widget>[
            _SliderRow(
              label: 'Blur',
              value: c.blur,
              max: 40,
              display: c.blur.toStringAsFixed(0),
              onChanged: (v) => c.update(() => c.blur = v),
            ),
            _SliderRow(
              label: 'Opacity',
              value: c.opacity,
              display: c.opacity.toStringAsFixed(2),
              onChanged: (v) => c.update(() => c.opacity = v),
            ),
            _SliderRow(
              label: 'Border width',
              value: c.borderWidth,
              max: 4,
              display: c.borderWidth.toStringAsFixed(1),
              onChanged: (v) => c.update(() => c.borderWidth = v),
            ),
            _SliderRow(
              label: 'Border opacity',
              value: c.borderOpacity,
              display: c.borderOpacity.toStringAsFixed(2),
              onChanged: (v) => c.update(() => c.borderOpacity = v),
            ),
            _SliderRow(
              label: 'Corner radius',
              value: c.cornerRadius,
              max: 40,
              display: c.cornerRadius.toStringAsFixed(0),
              onChanged: (v) => c.update(() => c.cornerRadius = v),
            ),
            const SizedBox(height: 6),
            const Text('Tint'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: <Widget>[
                for (final Color color in _tints)
                  Semantics(
                    button: true,
                    selected: c.tint == color,
                    label: 'Tint ${_tints.indexOf(color) + 1}',
                    child: GestureDetector(
                      onTap: () => c.update(() => c.tint = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c.tint == color
                                ? LiquidGlassTheme.of(context).accentColor
                                : Colors.black26,
                            width: c.tint == color ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const Section(title: 'Lighting and refraction'),
        _Panel(
          children: <Widget>[
            _SwitchRow(
              label: 'Highlights',
              value: c.highlights,
              onChanged: (v) => c.update(() => c.highlights = v),
            ),
            _SwitchRow(
              label: 'Refraction (premium)',
              value: c.refraction,
              onChanged: (v) => c.update(() => c.refraction = v),
            ),
            _SliderRow(
              label: 'Refraction strength',
              value: c.refractionStrength,
              display: c.refractionStrength.toStringAsFixed(2),
              onChanged: (v) => c.update(() => c.refractionStrength = v),
            ),
            const SizedBox(height: 8),
            LiquidGlassSegmentedControl<LiquidGlassQuality>(
              selected: c.quality,
              onChanged: (q) => c.update(() => c.quality = q),
              segments: const <LiquidGlassQuality, Widget>{
                LiquidGlassQuality.minimal: Text('Minimal'),
                LiquidGlassQuality.standard: Text('Standard'),
                LiquidGlassQuality.premium: Text('Premium'),
              },
            ),
          ],
        ),
        const Section(title: 'Navigation drop'),
        _Panel(
          children: <Widget>[
            LiquidGlassSegmentedControl<LiquidGlassDropShape>(
              selected: c.dropShape,
              onChanged: (s) => c.update(() => c.dropShape = s),
              segments: const <LiquidGlassDropShape, Widget>{
                LiquidGlassDropShape.capsule: Text('Capsule'),
                LiquidGlassDropShape.circle: Text('Circle'),
                LiquidGlassDropShape.roundedRectangle: Text('Rounded'),
              },
            ),
            const SizedBox(height: 8),
            _SliderRow(
              label: 'Drop width',
              value: c.dropWidth,
              min: 40,
              max: 140,
              display: c.dropWidth >= 140
                  ? 'fill'
                  : c.dropWidth.round().toString(),
              onChanged: (v) => c.update(() => c.dropWidth = v),
            ),
            _SliderRow(
              label: 'Drop height',
              value: c.dropHeight,
              min: 32,
              max: 56,
              display: c.dropHeight >= 56
                  ? 'fill'
                  : c.dropHeight.round().toString(),
              onChanged: (v) => c.update(() => c.dropHeight = v),
            ),
            _SliderRow(
              label: 'Magnification',
              value: c.dropMagnification,
              min: 1,
              max: 1.6,
              display: '${c.dropMagnification.toStringAsFixed(2)}x',
              onChanged: (v) => c.update(() => c.dropMagnification = v),
            ),
            const SizedBox(height: 6),
            const Text('Shadow color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: <Widget>[
                for (final (String name, Color color)
                    in const <(String, Color)>[
                      ('None', Color(0x00000000)),
                      ('Soft black', Color(0x29000000)),
                      ('Blue', Color(0x660A84FF)),
                      ('Pink', Color(0x66FF375F)),
                    ])
                  LiquidGlassButton(
                    prominent: c.dropShadow == color,
                    onPressed: () => c.update(() => c.dropShadow = color),
                    child: Text(name),
                  ),
              ],
            ),
          ],
        ),
        const Section(title: 'Colors'),
        _Panel(
          children: <Widget>[
            const Text('Accent (theme-wide)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: <Widget>[
                for (final (String name, Color color)
                    in const <(String, Color)>[
                      ('Blue', Color(0xFF0A84FF)),
                      ('Pink', Color(0xFFFF375F)),
                      ('Green', Color(0xFF30D158)),
                      ('Purple', Color(0xFFBF5AF2)),
                    ])
                  LiquidGlassButton(
                    prominent: c.accent == color,
                    color: color,
                    onPressed: () => c.update(() => c.accent = color),
                    child: Text(name),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _SwitchRow(
              label: 'Per-tab colors (override the accent)',
              value: c.perTabColors,
              onChanged: (v) => c.update(() => c.perTabColors = v),
            ),
          ],
        ),
        const Section(title: 'Motion'),
        _Panel(
          children: <Widget>[
            LiquidGlassSegmentedControl<MotionPreset>(
              selected: c.motion,
              onChanged: (m) => c.update(() => c.motion = m),
              segments: const <MotionPreset, Widget>{
                MotionPreset.fluid: Text('Fluid'),
                MotionPreset.snappy: Text('Snappy'),
                MotionPreset.bouncy: Text('Bouncy'),
                MotionPreset.gentle: Text('Gentle'),
                MotionPreset.curveOnly: Text('Curve'),
              },
            ),
            const SizedBox(height: 8),
            _SliderRow(
              label: 'Duration',
              value: c.durationMs,
              min: 100,
              max: 1200,
              display: '${c.durationMs.round()} ms',
              onChanged: (v) => c.update(() => c.durationMs = v),
            ),
            const Text(
              'Spring presets drive interactive motion; the duration applies '
              'to curve-based transitions and overlays.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        const Section(title: 'Appearance and accessibility'),
        _Panel(
          children: <Widget>[
            _SwitchRow(
              label: 'Dark mode',
              value: c.themeMode == ThemeMode.dark,
              onChanged: (v) => c.update(
                () => c.themeMode = v ? ThemeMode.dark : ThemeMode.light,
              ),
            ),
            _SwitchRow(
              label: 'Reduce motion',
              value: c.reduceMotion,
              onChanged: (v) => c.update(() => c.reduceMotion = v),
            ),
            _SwitchRow(
              label: 'Reduce transparency',
              value: c.reduceTransparency,
              onChanged: (v) => c.update(() => c.reduceTransparency = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: LiquidGlassButton(
            onPressed: c.reset,
            child: const Text('Reset to defaults'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.display,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
  });

  final String label;
  final double value;
  final String display;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            Text(display),
          ],
        ),
        LiquidGlassSlider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          semanticLabel: label,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label)),
        LiquidGlassSwitch(
          value: value,
          semanticLabel: label,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
