import 'package:flutter/material.dart';
import 'package:liquid_glass_toolkit/liquid_glass_toolkit.dart';

import 'demo_config.dart';
import 'pages/controls_page.dart';
import 'pages/gallery_page.dart';
import 'pages/overlays_page.dart';
import 'pages/settings_page.dart';

void main() => runApp(LiquidGlassDemoApp(config: DemoConfig()));

class LiquidGlassDemoApp extends StatelessWidget {
  const LiquidGlassDemoApp({super.key, required this.config});

  final DemoConfig config;

  @override
  Widget build(BuildContext context) {
    return DemoConfigScope(
      config: config,
      child: ListenableBuilder(
        listenable: config,
        builder: (context, _) => LiquidGlassTheme(
          data: config.themeFor(Brightness.light),
          darkData: config.themeFor(Brightness.dark),
          child: MaterialApp(
            title: 'Liquid Glass Toolkit',
            debugShowCheckedModeBanner: false,
            themeMode: config.themeMode,
            theme: ThemeData(
              colorSchemeSeed: const Color(0xFF0A84FF),
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: <TargetPlatform, PageTransitionsBuilder>{
                  TargetPlatform.android: LiquidGlassPageTransitionsBuilder(),
                  TargetPlatform.windows: LiquidGlassPageTransitionsBuilder(),
                  TargetPlatform.linux: LiquidGlassPageTransitionsBuilder(),
                },
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorSchemeSeed: const Color(0xFF0A84FF),
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations:
                    config.reduceMotion ||
                    MediaQuery.of(context).disableAnimations,
              ),
              child: child!,
            ),
            home: const HomeShell(),
          ),
        ),
      ),
    );
  }
}

/// Background image shared by all pages so the glass has something to bend.
class DemoBackground extends StatelessWidget {
  const DemoBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final bool dark = LiquidGlassTheme.brightnessOf(context) == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset('assets/images/background.jpg', fit: BoxFit.cover),
        if (dark) const ColoredBox(color: Color(0x88000000)),
      ],
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = const int.fromEnvironment('DEMO_TAB').clamp(0, 3);

  static const List<String> _titles = <String>[
    'Gallery',
    'Controls',
    'Overlays',
    'Configure',
  ];

  @override
  Widget build(BuildContext context) {
    final Widget page = switch (_index) {
      0 => const GalleryPage(),
      1 => const ControlsPage(),
      2 => const OverlaysPage(),
      _ => const SettingsPage(),
    };
    final DemoConfig config = DemoConfigScope.of(context);
    Color? tabColor(int i) =>
        config.perTabColors ? DemoConfig.tabColors[i] : null;
    return LiquidGlassScaffold(
      background: const DemoBackground(),
      appBar: LiquidGlassAppBar(title: Text(_titles[_index])),
      navigationBar: LiquidGlassNavigationBar(
        dropStyle: config.dropStyle,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: <LiquidGlassNavigationDestination>[
          LiquidGlassNavigationDestination(
            icon: const Icon(Icons.auto_awesome_mosaic_outlined),
            selectedIcon: const Icon(Icons.auto_awesome_mosaic),
            label: 'Gallery',
            selectedColor: tabColor(0),
          ),
          LiquidGlassNavigationDestination(
            icon: const Icon(Icons.tune_outlined),
            selectedIcon: const Icon(Icons.tune),
            label: 'Controls',
            selectedColor: tabColor(1),
          ),
          LiquidGlassNavigationDestination(
            icon: const Icon(Icons.layers_outlined),
            selectedIcon: const Icon(Icons.layers),
            label: 'Overlays',
            selectedColor: tabColor(2),
          ),
          LiquidGlassNavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: 'Configure',
            selectedColor: tabColor(3),
          ),
        ],
      ),
      body: KeyedSubtree(key: ValueKey<int>(_index), child: page),
    );
  }
}
