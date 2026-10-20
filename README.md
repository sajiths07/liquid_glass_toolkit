<p align="center">
  <img src="https://raw.githubusercontent.com/sajiths07/liquid_glass_widget/main/screenshots/banner.png" alt="liquid_glass_widget: liquid glass surfaces, controls, navigation and overlays for Flutter">
</p>

# liquid_glass_widget

[![pub package](https://img.shields.io/pub/v/liquid_glass_widget.svg)](https://pub.dev/packages/liquid_glass_widget)
[![CI](https://github.com/sajiths07/liquid_glass_widget/actions/workflows/ci.yaml/badge.svg)](https://github.com/sajiths07/liquid_glass_widget/actions/workflows/ci.yaml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Configurable **liquid glass** surfaces, controls, navigation, overlays and
spring-driven animations for Flutter, inspired by Apple's Liquid Glass
design language. Pure Flutter, no other dependencies.

<p align="center">
  <img src="https://raw.githubusercontent.com/sajiths07/liquid_glass_widget/main/screenshots/gallery.png" width="240" alt="Glass surfaces and the floating navigation bar">
  <img src="https://raw.githubusercontent.com/sajiths07/liquid_glass_widget/main/screenshots/controls.png" width="240" alt="Glass controls">
  <img src="https://raw.githubusercontent.com/sajiths07/liquid_glass_widget/main/screenshots/dark.png" width="240" alt="Dark mode">
</p>

## Contents

- [What's included](#whats-included)
- [Installation](#installation)
- [Quick start](#quick-start)
- [How it works](#how-it-works)
- [Theming](#theming)
  - [Glass style](#glass-style)
  - [Colors](#colors)
  - [Shapes](#shapes)
- [Quality modes and shaders](#quality-modes-and-shaders)
- [Widgets](#widgets)
  - [Surface and card](#surface-and-card)
  - [Buttons](#buttons)
  - [Switch and slider](#switch-and-slider)
  - [Segmented control](#segmented-control)
  - [Text field](#text-field)
  - [Scaffold and app bar](#scaffold-and-app-bar)
  - [Navigation bar](#navigation-bar)
  - [Water-drop indicator](#water-drop-indicator)
- [Overlays](#overlays)
- [Page transitions](#page-transitions)
- [Animation](#animation)
- [Accessibility](#accessibility)
- [Performance tips](#performance-tips)
- [Migrating from liquid_glass_ui](#migrating-from-liquid_glass_ui)
- [Platform support and limitations](#platform-support-and-limitations)
- [Example app](#example-app)
- [Contributing](#contributing)
- [License](#license)

## What's included

| Area | What you get |
| --- | --- |
| **Glass material** | Backdrop blur, tint, saturation, brightness and contrast, gradient borders, rim light, specular highlights, environment reflections and soft shadows (`LiquidGlassStyle`). |
| **Rendering** | A GPU lighting shader, plus an edge-refraction shader with chromatic dispersion on Impeller. Both fall back automatically when shaders are unavailable (`LiquidGlassShaders`). |
| **Quality modes** | `minimal`, `standard` and `premium`, each a different rendering path with a different cost (`LiquidGlassQuality`). |
| **Theme** | Light and dark theme data with a style, quality, three animation configs and a full color set. Usable as a widget or as a Material `ThemeExtension` (`LiquidGlassTheme`, `LiquidGlassThemeData`). |
| **Customization** | Colors and shapes resolve item, then widget, then theme, so you can restyle one tab, one widget or the whole app. |
| **Animation** | Duration, curve and spring settings with presets, reduced-motion handling, velocity-preserving springs and liquid stretching (`LiquidGlassAnimationConfig`). |
| **Controls** | Card, button, icon button, switch, slider, segmented control and text field. |
| **Navigation** | Scaffold, app bar, back button, a floating navigation bar with a clear water-drop indicator, and a glass page transition. |
| **Overlays** | Dialog, bottom sheet, menu and a morph that grows a panel out of its trigger. |
| **Accessibility** | Semantics, keyboard focus and activation, 44 px touch targets, text scaling, reduced motion, reduced transparency and high contrast. |
| **Compatibility** | The `LiquidGlassContainer` widget from the earlier `liquid_glass_ui` package still works. |

## Installation

```sh
flutter pub add liquid_glass_widget
```

or add it to `pubspec.yaml`:

```yaml
dependencies:
  liquid_glass_widget: ^1.0.0
```

Then import it:

```dart
import 'package:liquid_glass_widget/liquid_glass_widget.dart';
```

Requires Dart 3.8+ and Flutter 3.32+. No platform setup is needed; the
shaders ship with the package.

## Quick start

A complete app with a glass app bar, a floating navigation bar and a card:

```dart
import 'package:flutter/material.dart';
import 'package:liquid_glass_widget/liquid_glass_widget.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassTheme(
      data: LiquidGlassThemeData.light(),
      darkData: LiquidGlassThemeData.dark(),
      child: const MaterialApp(home: HomePage()),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      // Glass needs something colorful behind it.
      background: Image.asset('assets/background.jpg', fit: BoxFit.cover),
      appBar: const LiquidGlassAppBar(title: Text('Home')),
      navigationBar: LiquidGlassNavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          LiquidGlassNavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          LiquidGlassNavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          LiquidGlassNavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: ListView(
        // The scaffold reports its bars as padding, so content starts below
        // the app bar and scrolls underneath the glass.
        padding: MediaQuery.paddingOf(context) + const EdgeInsets.all(16),
        children: [
          LiquidGlassCard(
            child: const Text('Hello, glass'),
            onTap: () {},
          ),
          const SizedBox(height: 16),
          LiquidGlassButton(
            prominent: true,
            onPressed: () {},
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
```

## How it works

1. **Something behind the glass.** Glass blurs and bends whatever is under
   it. Use an image, a gradient or scrolling content as the background;
   on a plain white page glass looks like plain white.
2. **A theme (optional).** `LiquidGlassTheme` sets the default style,
   quality, animations and colors for everything below it. Without one,
   widgets use built-in light and dark defaults.
3. **Glass widgets.** Every widget draws a `LiquidGlassSurface`, which
   stacks a backdrop filter (blur and color), a tint, the lighting shader,
   the border and highlights, and a shadow.
4. **Overrides where you need them.** Pass a `style`, `quality`,
   `animation`, color or `borderRadius` to one widget, or to one item inside
   it, to change only that widget or item.

## Theming

Wrap your app (or any subtree) in a `LiquidGlassTheme`:

```dart
LiquidGlassTheme(
  data: LiquidGlassThemeData.light(
    style: const LiquidGlassStyle(blur: 16, opacity: 0.14),
    quality: LiquidGlassQuality.standard,
    animation: LiquidGlassAnimationConfig.fluid,
    accentColor: const Color(0xFF0A84FF),
  ),
  darkData: LiquidGlassThemeData.dark(),
  child: MaterialApp(home: MyHome()),
)
```

Or register it as a Material theme extension:

```dart
MaterialApp(
  theme: ThemeData(extensions: [LiquidGlassThemeData.light()]),
  darkTheme: ThemeData(
    brightness: Brightness.dark,
    extensions: [LiquidGlassThemeData.dark()],
  ),
)
```

Read the theme anywhere with `LiquidGlassTheme.of(context)`. Lookup order:
the nearest `LiquidGlassTheme`, then the Material extension, then the
built-in defaults for the current brightness.

| Theme property | Purpose |
| --- | --- |
| `style` | Default `LiquidGlassStyle` for every surface. |
| `quality` | Default rendering quality. |
| `animation` | Indicators, thumbs and general motion. |
| `interactionAnimation` | Press, hover and focus feedback. |
| `overlayAnimation` | Dialogs, sheets and menus. |
| `foregroundColor` | Text and icons on glass. |
| `accentColor` | Selection, "on" states and focus rings. |
| `secondaryForegroundColor` | Unselected items. Defaults to the foreground at 72%. |
| `onAccentColor` | Content on accent fills, such as prominent buttons. |
| `destructiveColor` | Destructive menu items. |
| `opaqueSurfaceColor` | Surface used under reduced transparency. |
| `reduceMotion`, `reduceTransparency` | Force accessibility modes on or off; `null` follows the platform. |

`LiquidGlassThemeData` supports `copyWith` and `lerp`, so theme changes
animate.

### Glass style

`LiquidGlassStyle` describes the material. Every property is optional:

| Group | Property | Default |
| --- | --- | --- |
| Backdrop | `blur` | `12` |
| | `saturation` | `1.4` |
| | `brightness` | `0` |
| | `contrast` | `1` |
| Tint | `tintColor` | white |
| | `opacity` | `0.16` |
| Shape | `borderRadius` | circular 22 |
| | `borderColor` | translucent white |
| | `borderWidth` | `1` |
| Lighting | `highlightColor` | white |
| | `highlightOpacity` | `0.6` |
| | `rimLightIntensity` | `0.65` |
| | `specularIntensity` | `0.45` |
| | `lightAlignment` | top left |
| | `thickness` | `14` |
| | `enableHighlights` | `true` |
| Refraction | `enableRefraction` | `true` |
| | `refractionStrength` | `0.35` |
| | `dispersion` | `0.15` |
| Shadow | `shadowColor` | soft black |
| | `shadowBlur` | `24` |
| | `shadowOffset` | `(0, 10)` |

Presets:

```dart
const LiquidGlassStyle.clear()                   // barely-there glass
const LiquidGlassStyle.frosted()                 // heavier blur, milkier
const LiquidGlassStyle.tinted(Color(0xFF0A84FF)) // colored glass
const LiquidGlassStyle.dark()                    // for dark backgrounds
```

Styles support `copyWith` and `LiquidGlassStyle.lerp`:

```dart
LiquidGlassSurface(
  style: LiquidGlassTheme.of(context).style.copyWith(blur: 30, opacity: 0.25),
  child: const Text('Extra frosted'),
)
```

### Colors

Every color resolves in the same order, and the most specific value wins:

1. **Item**: a color set on a single entry (a navigation destination, a
   segment, a menu item).
2. **Widget**: a color set on the widget (the navigation bar, segmented
   control, button, menu and so on).
3. **Theme**: the global color in `LiquidGlassThemeData`.

Set the global colors once:

```dart
LiquidGlassThemeData.light(
  foregroundColor: const Color(0xFF111114),          // text and icons
  accentColor: const Color(0xFFFF375F),              // selection, "on", focus
  secondaryForegroundColor: const Color(0x99111114), // unselected items
  onAccentColor: Colors.white,                       // content on accent fills
  destructiveColor: const Color(0xFFFF3B30),         // destructive menu items
)
```

Override a whole widget, and individual items inside it:

```dart
LiquidGlassNavigationBar(
  selectedColor: Colors.teal,       // all tabs (instead of accentColor)
  unselectedColor: Colors.blueGrey, // all tabs (instead of secondaryForegroundColor)
  selectedIndex: index,
  onDestinationSelected: onSelect,
  destinations: const [
    LiquidGlassNavigationDestination(
      icon: Icon(Icons.home),
      label: 'Home',
      selectedColor: Colors.orange, // only this tab
    ),
    LiquidGlassNavigationDestination(icon: Icon(Icons.search), label: 'Search'),
  ],
)
```

<p align="center">
  <img src="https://raw.githubusercontent.com/sajiths07/liquid_glass_widget/main/screenshots/colors.png" width="260" alt="Pink theme accent with a green per-tab override">
  <br><em>Pink theme accent; the Controls tab overrides it with green.</em>
</p>

| Widget | Widget-level colors | Item-level colors |
| --- | --- | --- |
| `LiquidGlassNavigationBar` | `selectedColor`, `unselectedColor` | `LiquidGlassNavigationDestination.selectedColor` / `unselectedColor` |
| `LiquidGlassSegmentedControl` | `selectedColor`, `unselectedColor` | `selectedColors` / `unselectedColors` maps keyed by value |
| `showLiquidGlassMenu` | `foregroundColor`, `destructiveColor` | `LiquidGlassMenuItem.color` |
| `LiquidGlassMenuButton` | `foregroundColor`, `menuForegroundColor`, `menuDestructiveColor` | `LiquidGlassMenuItem.color` |
| `LiquidGlassButton` | `foregroundColor`, `color` (prominent fill and focus ring) | |
| `LiquidGlassIconButton` | `color`, `focusColor` | |
| `LiquidGlassCard` | `foregroundColor`, `focusColor` | |
| `LiquidGlassSwitch` / `LiquidGlassSlider` | `activeColor`, `inactiveColor`, `thumbColor` | |
| `LiquidGlassTextField` | `foregroundColor`, `placeholderColor`, `cursorColor`, `focusColor` | |
| `LiquidGlassAppBar` | `foregroundColor` (also applies to its back button and glass buttons) | |
| `LiquidGlassBackButton` | `color` | |
| `LiquidGlassDialog` | `foregroundColor` (also applies to its action buttons) | |
| `showLiquidGlassSheet` | `foregroundColor`, `dragHandleColor` | |
| `LiquidGlassSurface` | `foregroundColor` | |

To recolor a whole subtree, wrap it in another theme:

```dart
LiquidGlassTheme(
  data: LiquidGlassTheme.of(context).copyWith(accentColor: Colors.green),
  child: const SettingsSection(),
)
```

### Shapes

Corner radii follow the same order: the widget's own `borderRadius` (or
the `borderRadius` of the `style` you pass), then the theme `style`.

| Widget | How to change the shape |
| --- | --- |
| `LiquidGlassSurface`, `LiquidGlassCard` | `borderRadius`, or `style.borderRadius` |
| `LiquidGlassButton`, `LiquidGlassTextField`, `LiquidGlassDialog`, sheet, menu | `style.borderRadius` |
| `LiquidGlassIconButton` | `borderRadius` (circle by default) |
| `LiquidGlassSegmentedControl` | `borderRadius` (pill by default) |
| `LiquidGlassNavigationBar` | `borderRadius` for the capsule (pill by default); `dropStyle.shape`, `dropStyle.size` and `dropStyle.borderRadius` for the water drop |

```dart
LiquidGlassIconButton(
  icon: const Icon(Icons.add),
  semanticLabel: 'Add',
  borderRadius: BorderRadius.circular(12), // rounded square
  onPressed: () {},
)
```

## Quality modes and shaders

| Mode | Backdrop | Lighting | Border | Refraction |
| --- | --- | --- | --- | --- |
| `minimal` | blur only | flat sheen | solid | no |
| `standard` | blur + color matrix | GPU shader (gradient fallback) | light-facing gradient | no |
| `premium` | blur + color matrix | GPU shader | light-facing gradient | edge refraction and dispersion on Impeller |

Set it in the theme or per widget with `quality:`. Premium falls back to
standard when backdrop shaders are unsupported (Skia, web or older
renderers). Use `minimal` for long lists of glass items or low-end devices.

Shaders load lazily the first time a surface needs them. To avoid the first
frames using the fallback, load them before `runApp`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassShaders.ensureLoaded();
  runApp(const MyApp());
}
```

`LiquidGlassShaders.status` (`notLoaded`, `loading`, `ready`,
`unavailable`) and `LiquidGlassShaders.supportsRefraction` report what is
available at runtime.

## Widgets

| Widget | Description |
| --- | --- |
| `LiquidGlassSurface` | The base glass material; wraps any child. |
| `AnimatedLiquidGlassSurface` | Animates between styles. |
| `LiquidGlassCard` | Padded, optionally tappable surface with press feedback. |
| `LiquidGlassButton` | Pill button; `prominent` fills it with the accent color. |
| `LiquidGlassIconButton` | Circular icon button. |
| `LiquidGlassSwitch` | Switch with a lens thumb that turns clear while pressed. |
| `LiquidGlassSlider` | Continuous or discrete slider with keyboard support. |
| `LiquidGlassSegmentedControl` | Segments with a liquid, draggable indicator. |
| `LiquidGlassTextField` | Text field with an animated focus state. |
| `LiquidGlassScaffold` | Layout with background, glass bars, safe areas and content scrolling underneath. |
| `LiquidGlassAppBar`, `LiquidGlassBackButton` | Full-width glass app bar with a back button. |
| `LiquidGlassNavigationBar` | Floating capsule with reflections and a water-drop indicator. |
| `LiquidGlassDialog`, `showLiquidGlassDialog` | Modal dialog. |
| `showLiquidGlassSheet` | Bottom sheet with drag, fling and rubber-band behavior. |
| `showLiquidGlassMenu`, `LiquidGlassMenuButton` | Menus that morph out of their trigger. |
| `showLiquidGlassMorph` | Morph any trigger into a larger glass panel. |
| `LiquidGlassPageRoute`, `LiquidGlassPageTransitionsBuilder` | Glass page transition. |
| `LiquidGlassAppear`, `LiquidGlassTransition` | Show and hide glass without breaking the backdrop blur. |
| `LiquidGlassContainer` | The original 0.x widget, still supported. |

### Surface and card

```dart
LiquidGlassSurface(
  padding: const EdgeInsets.all(20),
  borderRadius: BorderRadius.circular(28),
  child: const Text('Any content'),
)

LiquidGlassCard(
  onTap: () {},                  // optional; adds press feedback and semantics
  semanticLabel: 'Open album',
  child: const ListTile(title: Text('Album')),
)

AnimatedLiquidGlassSurface(
  style: expanded ? const LiquidGlassStyle.frosted() : const LiquidGlassStyle.clear(),
  child: const Text('Animates between styles'),
)
```

### Buttons

```dart
LiquidGlassButton(onPressed: save, child: const Text('Save'))

LiquidGlassButton(
  prominent: true,               // accent fill, white content
  color: Colors.green,           // custom fill
  onPressed: confirm,
  child: const Text('Confirm'),
)

LiquidGlassIconButton(
  icon: const Icon(Icons.favorite),
  semanticLabel: 'Like',         // required for screen readers
  color: Colors.pink,
  onPressed: like,
)
```

`onPressed: null` disables a button. Buttons react to press, hover and
keyboard focus, and activate with Enter or Space.

### Switch and slider

```dart
LiquidGlassSwitch(
  value: wifi,
  onChanged: (v) => setState(() => wifi = v),
  semanticLabel: 'Wi-Fi',
  activeColor: Colors.green,
)

LiquidGlassSlider(
  value: volume,
  onChanged: (v) => setState(() => volume = v),
  min: 0,
  max: 1,
  divisions: 10,                 // optional; null is continuous
  semanticLabel: 'Volume',
)
```

The thumbs can be dragged, stretch with speed and turn into clear lenses
while held.

### Segmented control

```dart
LiquidGlassSegmentedControl<String>(
  selected: period,
  onChanged: (v) => setState(() => period = v),
  segments: const {
    'day': Text('Day'),
    'week': Text('Week'),
    'month': Text('Month'),
  },
  selectedColors: const {'month': Colors.orange}, // optional per segment
)
```

### Text field

```dart
LiquidGlassTextField(
  controller: controller,
  placeholder: 'Search',
  prefix: const Icon(Icons.search),
  onSubmitted: search,
)
```

It is built on `CupertinoTextField`, so platform text editing, selection,
IME and autofill keep working.

### Scaffold and app bar

`LiquidGlassScaffold` paints the `background`, lets `body` scroll under the
glass `appBar` and `navigationBar`, and reports their heights through
`MediaQuery.paddingOf(context)`. It also sets light or dark status bar
icons to match.

```dart
LiquidGlassScaffold(
  background: const MyGradient(),
  appBar: LiquidGlassAppBar(
    title: const Text('Library'),
    actions: [
      LiquidGlassIconButton(icon: const Icon(Icons.add), semanticLabel: 'Add', onPressed: add),
    ],
  ),
  floatingAction: LiquidGlassButton(onPressed: compose, child: const Text('New')),
  body: ListView(padding: MediaQuery.paddingOf(context), children: items),
)
```

The app bar shows a `LiquidGlassBackButton` automatically when the route
can be popped.

### Navigation bar

```dart
LiquidGlassNavigationBar(
  selectedIndex: index,
  onDestinationSelected: (i) => setState(() => index = i),
  maxWidth: 480,          // the capsule is centered and never wider than this
  height: 64,
  showLabels: true,
  showReflections: true,  // top gloss, inner rim and bottom light bounce
  borderRadius: null,     // null is a pill
  dropStyle: const LiquidGlassDropStyle(), // the water-drop indicator
  destinations: const [
    LiquidGlassNavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    // ...
  ],
)
```

Icons sit in fixed slots, so they share one baseline and stay evenly
spaced; long labels are truncated instead of moving the icon. The indicator
can be tapped or dragged between destinations.

### Water-drop indicator

The selected destination sits in a clear drop of water. The drop magnifies
the content behind it and paints the optics of real water: a soft
refraction rim, a bright caustic, a specular highlight towards the light,
a thin bright edge and a soft shadow. It stretches like liquid while it
moves or is dragged.

<p align="center">
  <img src="https://raw.githubusercontent.com/sajiths07/liquid_glass_widget/main/screenshots/gallery.png" width="240" alt="Default capsule drop">
  <img src="https://raw.githubusercontent.com/sajiths07/liquid_glass_widget/main/screenshots/drop_circle.png" width="240" alt="Circle drop with blue shadow">
  <img src="https://raw.githubusercontent.com/sajiths07/liquid_glass_widget/main/screenshots/drop_tinted.png" width="240" alt="Rounded drop with pink shadow">
  <br><em>Capsule (default), circle with a blue shadow and 1.3x magnification, rounded rectangle with a pink shadow.</em>
</p>

```dart
LiquidGlassNavigationBar(
  dropStyle: LiquidGlassDropStyle(
    shape: LiquidGlassDropShape.circle,      // capsule, circle, roundedRectangle
    size: const Size(52, 52),                // null dimensions fill the slot
    magnification: 1.3,                      // 1 turns the lens off
    shadowColor: const Color(0x660A84FF),    // transparent removes the shadow
    shadowBlur: 16,
    shadowOffset: const Offset(0, 6),
    tintColor: Colors.white,
    tintOpacity: 0.12,
    borderColor: Colors.white70,
    borderWidth: 1,
    highlightColor: Colors.white,            // caustic, highlight and edge
    opticsIntensity: 0.9,                    // 0 removes the painted optics
    stretch: true,                           // liquid stretch while moving
    borderRadius: BorderRadius.circular(14), // for roundedRectangle
  ),
  // ...
)
```

| Property | Default | Effect |
| --- | --- | --- |
| `shape` | `capsule` | Outline of the drop. `circle` stays round at rest and stretches into a capsule while moving. |
| `size` | fills the slot | Preferred width and height, clamped to the destination slot. |
| `magnification` | `1.15` | How much the backdrop is enlarged through the drop. |
| `shadowColor`, `shadowBlur`, `shadowOffset` | soft black, 14, (0, 4) | Shadow under the drop. |
| `tintColor`, `tintOpacity` | white, about 0.16 (light) or 0.06 (dark) | Very light tint inside the drop. |
| `borderColor`, `borderWidth` | translucent white, 0.8 | Edge of the drop. |
| `highlightColor`, `opticsIntensity` | white, 1 | Color and strength of the water optics. |
| `stretch` | `true` | Liquid stretching with speed (always off under reduced motion). |

On the web the magnifying lens is skipped, because backdrop magnification
interferes with blur on other glass surfaces in the browser renderer; the
drop optics, tint and shadow are still painted. Under reduced transparency
the lens and the optics are removed.

## Overlays

```dart
// Dialog
final ok = await showLiquidGlassDialog<bool>(
  context: context,
  builder: (context) => LiquidGlassDialog(
    title: const Text('Delete photo?'),
    content: const Text('This cannot be undone.'),
    actions: [
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

// Bottom sheet: drag down or fling to dismiss
await showLiquidGlassSheet(
  context: context,
  builder: (_) => const Padding(
    padding: EdgeInsets.all(24),
    child: Text('Sheet content'),
  ),
);

// Menu that morphs out of its button
LiquidGlassMenuButton(
  semanticLabel: 'More',
  items: [
    LiquidGlassMenuItem(label: 'Copy', leading: const Icon(Icons.copy), onPressed: copy),
    LiquidGlassMenuItem(label: 'Delete', destructive: true, onPressed: delete),
  ],
  child: const Icon(Icons.more_horiz),
)

// Morph any widget into a panel
Builder(
  builder: (triggerContext) => LiquidGlassButton(
    onPressed: () => showLiquidGlassMorph<void>(
      context: triggerContext,
      size: const Size(300, 220),
      builder: (_) => const Center(child: Text('Expanded panel')),
    ),
    child: const Text('Expand'),
  ),
)
```

Overlays capture the theme from the calling context, use the theme
`overlayAnimation`. Dismissible overlays close on a barrier tap, the back
button or Escape.

## Page transitions

Use the glass transition for one route:

```dart
Navigator.of(context).push(
  LiquidGlassPageRoute(builder: (_) => const DetailPage()),
);
```

or for every route in a Material app:

```dart
MaterialApp(
  theme: ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: LiquidGlassPageTransitionsBuilder(),
        TargetPlatform.iOS: LiquidGlassPageTransitionsBuilder(),
      },
    ),
  ),
)
```

## Animation

`LiquidGlassAnimationConfig` controls duration, curve, an optional spring
and the reduced-motion duration. Presets: `fluid`, `snappy`, `bouncy` and
`gentle`.

```dart
const LiquidGlassAnimationConfig(
  duration: Duration(milliseconds: 400),
  curve: Curves.easeOutCubic,
  spring: SpringDescription(mass: 1, stiffness: 260, damping: 27),
)

LiquidGlassAnimationConfig.bouncy.copyWith(duration: const Duration(milliseconds: 600))
```

The theme has three configs: `animation` (indicators and general motion),
`interactionAnimation` (press feedback) and `overlayAnimation` (dialogs,
sheets and menus). Most widgets also take an `animation` override.
Interactive motion uses the spring and keeps its velocity when interrupted;
route transitions are time-based and use the curve.

To show or hide glass, use `LiquidGlassAppear` instead of `Opacity`, which
would break the backdrop blur:

```dart
LiquidGlassAppear(
  visible: showToolbar,
  child: const MyGlassToolbar(),
)
```

## Accessibility

- All controls expose semantics (buttons, toggles, sliders, selection and
  headers) and accept `semanticLabel`. `LiquidGlassIconButton` requires one.
- Keyboard: focus highlights, Enter or Space to activate, arrow keys for
  sliders, Escape to close dismissible overlays.
- Touch targets are at least 44 x 44 logical pixels.
- Text scales with the system setting; navigation labels are capped at 1.3x
  so the bar keeps its shape.
- **Reduced motion** (`MediaQuery.disableAnimations` or
  `LiquidGlassThemeData.reduceMotion`) replaces movement with short fades
  and turns off liquid stretching.
- **Reduced transparency** (`LiquidGlassThemeData.reduceTransparency`)
  swaps glass for an opaque surface and removes reflections and the lens.
  Flutter does not expose the platform setting, so forward it from your app
  if needed.
- **High contrast** (`MediaQuery.highContrast`) strengthens borders and the
  foreground color.

## Performance tips

- Backdrop blur is the main cost. Prefer `LiquidGlassQuality.minimal` for
  long lists and many small surfaces, and keep `premium` for a few hero
  surfaces.
- Lower `blur` values are cheaper.
- Call `LiquidGlassShaders.ensureLoaded()` before `runApp` to avoid a
  fallback flash on the first frames.
- Avoid wrapping glass in `Opacity`; use `LiquidGlassAppear` or
  `LiquidGlassTransition`.

## Migrating from liquid_glass_ui

This package continues the 0.x `liquid_glass_ui` package under a new
name. Update the dependency and the imports:

```yaml
dependencies:
  liquid_glass_widget: ^1.0.0   # was liquid_glass_ui: ^0.4.0
```

```dart
import 'package:liquid_glass_widget/liquid_glass_widget.dart';

// The original widget and its import path still work:
import 'package:liquid_glass_widget/widgets/liquid_glass_container.dart';

LiquidGlassContainer(blur: 10, opacity: 0.2, child: Text('Still works'));
```

Visual changes: `LiquidGlassContainer` now renders through the new glass
engine (gradient border, highlights and a soft shadow), and the default
text color comes from the glass theme. Pass
`quality: LiquidGlassQuality.minimal` for a look closer to 0.4.

## Platform support and limitations

- Works on Android, iOS, web, Windows, macOS and Linux. It has been built
  and tested on Windows (unit, widget and golden tests, and Windows and web
  builds of the example); other platforms have not yet been verified on
  devices.
- Premium refraction requires Impeller (`ImageFilter.isShaderFilterSupported`).
  Elsewhere it falls back to standard quality.
- The navigation drop's magnifying lens is not used on the web (see
  [Water-drop indicator](#water-drop-indicator)).
- `LiquidGlassPageRoute` does not provide an iOS-style swipe-back gesture.
- Golden images are generated on Windows and are skipped on other hosts.

## Example app

The [`example`](example) app has four tabs:

- **Gallery**: surfaces, the three quality modes, style presets, cards that
  open a detail page with the glass transition, and the legacy container.
- **Controls**: buttons, switches, sliders, segmented controls and text
  fields.
- **Overlays**: dialog, sheet, menu and morph.
- **Configure**: live settings for blur, opacity, tint, borders, corner
  radius, highlights, refraction, quality, the navigation drop (shape, size,
  magnification and shadow), the accent color, per-tab colors, motion, dark
  mode, reduced motion and reduced transparency.

<p align="center">
  <img src="https://raw.githubusercontent.com/sajiths07/liquid_glass_widget/main/screenshots/overlays.png" width="240" alt="Overlays page">
  <img src="https://raw.githubusercontent.com/sajiths07/liquid_glass_widget/main/screenshots/configure.png" width="240" alt="Live configuration page">
</p>

```sh
git clone https://github.com/sajiths07/liquid_glass_widget.git
cd liquid_glass_widget/example
flutter run
```

## Contributing

Issues and pull requests are welcome on
[GitHub](https://github.com/sajiths07/liquid_glass_widget). See
[CONTRIBUTING.md](CONTRIBUTING.md) for the project layout and checks, and
[SECURITY.md](SECURITY.md) to report a vulnerability.

## License

MIT. See [LICENSE](LICENSE).
