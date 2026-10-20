import 'package:flutter/material.dart';
import 'package:liquid_glass_toolkit/liquid_glass_toolkit.dart';

import 'section.dart';

/// Dialog, sheet, menu, liquid morph and appear/disappear transitions.
class OverlaysPage extends StatefulWidget {
  const OverlaysPage({super.key});

  @override
  State<OverlaysPage> createState() => _OverlaysPageState();
}

class _OverlaysPageState extends State<OverlaysPage> {
  String _last = 'Nothing selected yet';
  bool _visible = true;

  void _report(String message) => setState(() => _last = message);

  Future<void> _dialog() async {
    final bool? ok = await showLiquidGlassDialog<bool>(
      context: context,
      builder: (context) => LiquidGlassDialog(
        title: const Text('Delete photo?'),
        content: const Text('This photo will be removed from all devices.'),
        actions: <Widget>[
          LiquidGlassButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          LiquidGlassButton(
            prominent: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    _report('Dialog result: ${ok ?? 'dismissed'}');
  }

  Future<void> _sheet() async {
    final String? choice = await showLiquidGlassSheet<String>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Share to',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text('Drag down or fling to dismiss.'),
            const SizedBox(height: 16),
            for (final String target in const <String>[
              'Messages',
              'Mail',
              'Notes',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LiquidGlassButton(
                  onPressed: () => Navigator.pop(context, target),
                  child: Text(target),
                ),
              ),
          ],
        ),
      ),
    );
    _report('Sheet result: ${choice ?? 'dismissed'}');
  }

  Future<void> _morph(BuildContext trigger) async {
    final String? picked = await showLiquidGlassMorph<String>(
      context: trigger,
      size: const Size(260, 220),
      builder: (context) => ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Quick actions',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          for (final String action in const <String>['Scan', 'Record', 'Note'])
            ListTile(
              dense: true,
              title: Text(action),
              onTap: () => Navigator.pop(context, action),
            ),
        ],
      ),
    );
    _report('Morph result: ${picked ?? 'dismissed'}');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: MediaQuery.paddingOf(context) + const EdgeInsets.all(16),
      children: <Widget>[
        LiquidGlassSurface(
          padding: const EdgeInsets.all(14),
          child: Text(_last, semanticsLabel: 'Last result: $_last'),
        ),
        const Section(title: 'Dialog and sheet'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            LiquidGlassButton(onPressed: _dialog, child: const Text('Dialog')),
            LiquidGlassButton(onPressed: _sheet, child: const Text('Sheet')),
          ],
        ),
        const Section(title: 'Menu (morphs from its button)'),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LiquidGlassMenuButton(
            semanticLabel: 'More actions',
            items: <LiquidGlassMenuItem>[
              LiquidGlassMenuItem(
                label: 'Copy',
                leading: const Icon(Icons.copy),
                onPressed: () => _report('Menu: Copy'),
              ),
              LiquidGlassMenuItem(
                label: 'Duplicate',
                leading: const Icon(Icons.control_point_duplicate),
                onPressed: () => _report('Menu: Duplicate'),
              ),
              LiquidGlassMenuItem(
                label: 'Delete',
                leading: const Icon(Icons.delete_outline),
                destructive: true,
                onPressed: () => _report('Menu: Delete'),
              ),
            ],
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.more_horiz),
                SizedBox(width: 6),
                Text('Actions'),
              ],
            ),
          ),
        ),
        const Section(title: 'Liquid morph'),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Builder(
            builder: (trigger) => LiquidGlassIconButton(
              semanticLabel: 'Quick actions',
              icon: const Icon(Icons.add),
              onPressed: () => _morph(trigger),
            ),
          ),
        ),
        const Section(title: 'Appear / disappear'),
        LiquidGlassButton(
          onPressed: () => setState(() => _visible = !_visible),
          child: Text(_visible ? 'Hide card' : 'Show card'),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: LiquidGlassAppear(
            visible: _visible,
            child: const LiquidGlassSurface(
              child: Center(child: Text('Glass fades without breaking blur')),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
