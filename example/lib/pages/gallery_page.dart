import 'package:flutter/material.dart';
import 'package:liquid_glass_widget/liquid_glass_widget.dart';
// The 0.x import path keeps working.
import 'package:liquid_glass_widget/widgets/liquid_glass_container.dart'
    as legacy;

import '../main.dart';
import 'section.dart';

/// Surfaces, cards, quality comparison, page transition and the legacy API.
class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: MediaQuery.paddingOf(context) + const EdgeInsets.all(16),
      children: <Widget>[
        const Section(title: 'Surface'),
        const SizedBox(
          height: 140,
          child: LiquidGlassSurface(
            padding: EdgeInsets.all(20),
            child: Text(
              'Glass bends the content behind it.\nScroll to see it move.',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const Section(title: 'Quality modes'),
        const Row(
          children: <Widget>[
            Expanded(child: _QualityTile(LiquidGlassQuality.minimal)),
            SizedBox(width: 10),
            Expanded(child: _QualityTile(LiquidGlassQuality.standard)),
            SizedBox(width: 10),
            Expanded(child: _QualityTile(LiquidGlassQuality.premium)),
          ],
        ),
        const SizedBox(height: 10),
        LiquidGlassSurface(
          quality: LiquidGlassQuality.minimal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: ValueListenableBuilder<LiquidGlassShaderStatus>(
            valueListenable: LiquidGlassShaders.status,
            builder: (context, status, _) => Text(
              'Shaders: ${status.name} · backdrop refraction '
              '${LiquidGlassShaders.supportsRefraction ? 'available' : 'unavailable, premium uses the standard path'}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        const Section(title: 'Styles'),
        const Row(
          children: <Widget>[
            Expanded(child: _StyleTile('Clear', LiquidGlassStyle.clear())),
            SizedBox(width: 10),
            Expanded(child: _StyleTile('Frosted', LiquidGlassStyle.frosted())),
            SizedBox(width: 10),
            Expanded(
              child: _StyleTile(
                'Tinted',
                LiquidGlassStyle.tinted(Color(0xFF0A84FF), opacity: 0.3),
              ),
            ),
          ],
        ),
        const Section(title: 'Cards and page transition'),
        for (final (int i, String name) in const <String>[
          'Lagoon',
          'Aurora',
          'Ember',
        ].indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LiquidGlassCard(
              semanticLabel: 'Open $name',
              onTap: () => Navigator.of(context).push(
                LiquidGlassPageRoute<void>(
                  builder: (_) => _DetailPage(name: name),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    const <IconData>[
                      Icons.water,
                      Icons.nights_stay,
                      Icons.local_fire_department,
                    ][i],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        const Section(title: 'Legacy LiquidGlassContainer (0.x API)'),
        const legacy.LiquidGlassContainer(
          blur: 10,
          opacity: 0.2,
          padding: EdgeInsets.all(16),
          child: Text('Existing apps keep compiling unchanged.'),
        ),
        const SizedBox(height: 600, child: _ScrollHint()),
      ],
    );
  }
}

class _QualityTile extends StatelessWidget {
  const _QualityTile(this.quality);

  final LiquidGlassQuality quality;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: LiquidGlassSurface(
        quality: quality,
        child: Center(
          child: Text(
            quality.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _StyleTile extends StatelessWidget {
  const _StyleTile(this.label, this.style);

  final String label;
  final LiquidGlassStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: LiquidGlassSurface(
        style: style,
        child: Center(child: Text(label)),
      ),
    );
  }
}

class _ScrollHint extends StatelessWidget {
  const _ScrollHint();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 24),
        child: Text('Content scrolls underneath the glass bars.'),
      ),
    );
  }
}

class _DetailPage extends StatelessWidget {
  const _DetailPage({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      background: const DemoBackground(),
      appBar: LiquidGlassAppBar(title: Text(name)),
      body: Center(
        child: LiquidGlassSurface(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$name opened with LiquidGlassPageRoute.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
