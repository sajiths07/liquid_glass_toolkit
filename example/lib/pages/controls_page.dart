import 'package:flutter/material.dart';
import 'package:liquid_glass_toolkit/liquid_glass_toolkit.dart';

import 'section.dart';

/// Buttons, switch, slider, segmented control and text field.
class ControlsPage extends StatefulWidget {
  const ControlsPage({super.key});

  @override
  State<ControlsPage> createState() => _ControlsPageState();
}

class _ControlsPageState extends State<ControlsPage> {
  bool _wifi = true;
  bool _bluetooth = false;
  double _volume = 0.6;
  double _steps = 3;
  String _segment = 'Day';
  int _taps = 0;
  bool _favorite = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: MediaQuery.paddingOf(context) + const EdgeInsets.all(16),
      children: <Widget>[
        const Section(title: 'Buttons'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            LiquidGlassButton(
              onPressed: () => setState(() => _taps++),
              child: Text('Tapped $_taps'),
            ),
            LiquidGlassButton(
              prominent: true,
              onPressed: () => setState(() => _taps = 0),
              child: const Text('Reset'),
            ),
            const LiquidGlassButton(onPressed: null, child: Text('Disabled')),
            LiquidGlassIconButton(
              semanticLabel: _favorite ? 'Remove favorite' : 'Add favorite',
              icon: Icon(_favorite ? Icons.favorite : Icons.favorite_border),
              onPressed: () => setState(() => _favorite = !_favorite),
            ),
            LiquidGlassIconButton(
              semanticLabel: 'Share',
              icon: const Icon(Icons.ios_share),
              onPressed: () {},
            ),
          ],
        ),
        const Section(title: 'Switches'),
        LiquidGlassSurface(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: <Widget>[
              _row(
                'Wi-Fi',
                LiquidGlassSwitch(
                  value: _wifi,
                  semanticLabel: 'Wi-Fi',
                  onChanged: (v) => setState(() => _wifi = v),
                ),
              ),
              _row(
                'Bluetooth',
                LiquidGlassSwitch(
                  value: _bluetooth,
                  semanticLabel: 'Bluetooth',
                  activeColor: const Color(0xFF30D158),
                  onChanged: (v) => setState(() => _bluetooth = v),
                ),
              ),
              _row(
                'Disabled',
                const LiquidGlassSwitch(value: true, onChanged: null),
              ),
            ],
          ),
        ),
        const Section(title: 'Sliders'),
        LiquidGlassSurface(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Volume ${(_volume * 100).round()}%'),
              LiquidGlassSlider(
                value: _volume,
                semanticLabel: 'Volume',
                onChanged: (v) => setState(() => _volume = v),
              ),
              const SizedBox(height: 8),
              Text('Steps ${_steps.round()} of 5'),
              LiquidGlassSlider(
                value: _steps,
                min: 1,
                max: 5,
                divisions: 4,
                semanticLabel: 'Steps',
                onChanged: (v) => setState(() => _steps = v),
              ),
            ],
          ),
        ),
        const Section(title: 'Segmented control'),
        LiquidGlassSegmentedControl<String>(
          selected: _segment,
          onChanged: (v) => setState(() => _segment = v),
          segments: const <String, Widget>{
            'Day': Text('Day'),
            'Week': Text('Week'),
            'Month': Text('Month'),
            'Year': Text('Year'),
          },
        ),
        const SizedBox(height: 6),
        Text('Drag the indicator or tap a segment. Selected: $_segment'),
        const Section(title: 'Text field'),
        const LiquidGlassTextField(
          placeholder: 'Search',
          prefix: Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(Icons.search, size: 20),
          ),
        ),
        const SizedBox(height: 10),
        const LiquidGlassTextField(placeholder: 'Password', obscureText: true),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _row(String label, Widget control) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: <Widget>[
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        control,
      ],
    ),
  );
}
