# liquid_glass_ui

Configurable **liquid glass** surfaces, controls, navigation, overlays and
spring-driven animations for Flutter, inspired by Apple's Liquid Glass
design language.

<p align="center">
  <img src="https://raw.githubusercontent.com/sajiths07/liquid_glass_ui/main/screenshots/gallery.png" width="260" alt="Glass surfaces and floating navigation bar">
  <img src="https://raw.githubusercontent.com/sajiths07/liquid_glass_ui/main/screenshots/controls.png" width="260" alt="Glass controls">
  <img src="https://raw.githubusercontent.com/sajiths07/liquid_glass_ui/main/screenshots/dark.png" width="260" alt="Dark mode">
</p>

- Real backdrop glass: blur, tint, saturation/contrast, gradient borders,
  rim light, specular highlights and environment reflections.
- GPU lighting shader, plus an edge-refraction shader on Impeller, with
  automatic fallbacks wherever shaders are unavailable.
- Three quality modes (`minimal`, `standard`, `premium`) with real visual and
  cost differences.
- Animation engine with duration, curve and spring settings, reduced motion
  support and liquid morphing between shapes.
- A complete widget set: surface, card, scaffold, app bar, floating
  navigation bar, buttons, switch, slider, segmented control, text field,
  dialog, sheet, menu and page transition.
- Accessibility built in: semantics, keyboard focus and activation, 44 px
  touch targets, text scaling, reduced motion, reduced transparency and
  high contrast.
- No dependencies beyond Flutter itself.

## Installation

```yaml
dependencies:
  liquid_glass_ui: ^0.5.0
```

```dart
import 'package:liquid_glass_ui/liquid_glass_ui.dart';
```

Requires Dart 3.8+ and Flutter 3.32+.

## Quick start

Glass needs something behind it. Put colorful content (an image, gradient or
scrolling list) underneath, then place glass widgets on top:

```dart
LiquidGlassScaffold(
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
    // The scaffold reports the bars as padding so content starts below
    // the app bar and scrolls underneath the glass.
    padding: MediaQuery.paddingOf(context) + const EdgeInsets.all(16),
    children: const [
      LiquidGlassCard(child: Text('Hello, glass')),
    ],
  ),
)
```

## Theming

Wrap your app (or any subtree) in a `LiquidGlassTheme`, or add
`LiquidGlassThemeData` to `ThemeData.extensions`. Widgets fall back to
sensible light and dark defaults when no theme is provided.

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

### `LiquidGlassStyle`

Every visual property of the material is configurable:

| Group | Properties |
| --- | --- |
| Backdrop | `blur`, `saturation`, `brightness`, `contrast` |
| Tint | `tintColor`, `opacity` |
| Shape | `borderRadius`, `borderColor`, `borderWidth` |
| Lighting | `highlightColor`, `highlightOpacity`, `rimLightIntensity`, `specularIntensity`, `lightAlignment`, `thickness`, `enableHighlights` |
| Refraction | `enableRefraction`, `refractionStrength`, `dispersion` |
| Shadow | `shadowColor`, `shadowBlur`, `shadowOffset` |

Presets: `LiquidGlassStyle.clear()`, `.frosted()`, `.tinted(color)` and
`.dark()`. Styles support `copyWith` and `LiquidGlassStyle.lerp`.

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
      icon: Icon(Icons.home), label: 'Home',
      selectedColor: Colors.orange, // only this tab
    ),
    LiquidGlassNavigationDestination(icon: Icon(Icons.search), label: 'Search'),
  ],
)
```

<p align="center">
  <img src="https://raw.githubusercontent.com/sajiths07/liquid_glass_ui/main/screenshots/colors.png" width="260" alt="Pink theme accent with a green per-tab override">
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

### Shapes

Corner radii follow the same order: the widget's own `borderRadius` (or
the `borderRadius` of the `style` you pass), then the theme `style`.

| Widget | How to change the shape |
| --- | --- |
| `LiquidGlassSurface`, `LiquidGlassCard` | `borderRadius`, or `style.borderRadius` |
| `LiquidGlassButton`, `LiquidGlassTextField`, `LiquidGlassDialog`, sheet, menu | `style.borderRadius` |
| `LiquidGlassIconButton` | `borderRadius` (circle by default) |
| `LiquidGlassSegmentedControl` | `borderRadius` (pill by default) |
| `LiquidGlassNavigationBar` | `borderRadius` for the capsule (pill by default); `dropStyle.shape` (`capsule`, `circle`, `roundedRectangle`), `dropStyle.size` and `dropStyle.borderRadius` for the water drop |

Glass appearance follows the same pattern: pass a `style` (and, where
available, `indicatorStyle`, `dropStyle` or `menuStyle`) to one widget to
override the theme `style` for that widget only. To recolor a whole
subtree, wrap it in another `LiquidGlassTheme` with
`LiquidGlassTheme.of(context).copyWith(...)`.

## Quality modes

| Mode | Backdrop | Lighting | Border | Refraction |
| --- | --- | --- | --- | --- |
| `minimal` | blur only | flat sheen | solid | no |
| `standard` | blur + color matrix | GPU shader (gradient fallback) | light-facing gradient | no |
| `premium` | blur + color matrix | GPU shader | light-facing gradient | edge refraction and dispersion on Impeller |

Premium falls back to standard when backdrop shaders are unsupported (Skia,
web, or older renderers). You can inspect support at runtime through
`LiquidGlassShaders.status` and `LiquidGlassShaders.supportsRefraction`.
Use `minimal` for long lists of glass items or low-end devices.

## Widgets

| Widget | Description |
| --- | --- |
| `LiquidGlassSurface` | The base glass material; wraps any child. |
| `AnimatedLiquidGlassSurface` | Animates between styles. |
| `LiquidGlassCard` | Padded, optionally tappable surface with press feedback. |
| `LiquidGlassScaffold` | Layout with background, glass bars, safe-area handling and content scrolling underneath. |
| `LiquidGlassAppBar` | Full-width glass app bar with back button and header semantics. |
| `LiquidGlassNavigationBar` | Floating capsule with reflections, a customizable water-drop indicator (`LiquidGlassDropStyle`) that glides and can be dragged, and evenly spaced, width-capped destinations. |
| `LiquidGlassButton`, `LiquidGlassIconButton` | Pill and circular buttons; `prominent` uses the accent color. |
| `LiquidGlassSwitch` | Switch with a lens thumb that turns clear while pressed. |
| `LiquidGlassSlider` | Continuous or discrete slider with keyboard support. |
| `LiquidGlassSegmentedControl` | Segments with a liquid, draggable indicator. |
| `LiquidGlassTextField` | Glass text field with an animated focus state. |
| `LiquidGlassDialog` / `showLiquidGlassDialog` | Modal dialog. |
| `showLiquidGlassSheet` | Bottom sheet with drag, fling and rubber-band behavior. |
| `showLiquidGlassMenu`, `LiquidGlassMenuButton` | Menus that morph out of their trigger. |
| `showLiquidGlassMorph` | Morph any trigger into a larger glass panel. |
| `LiquidGlassPageRoute`, `LiquidGlassPageTransitionsBuilder` | Glass page transition. |
| `LiquidGlassAppear`, `LiquidGlassTransition` | Appear/disappear without breaking backdrop blur. |
| `LiquidGlassContainer` | The original 0.x widget, still supported. |

### Navigation bar

```dart
LiquidGlassNavigationBar(
  selectedIndex: index,
  onDestinationSelected: (i) => setState(() => index = i),
  maxWidth: 480,          // capsule is centered and never wider than this
  showReflections: true,  // top gloss, inner rim and bottom light bounce
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

Icons sit in fixed slots so they share one baseline and stay evenly spaced;
long labels are truncated instead of shifting the icon.

### Water-drop indicator

The selected destination sits in a clear drop of water. The drop magnifies
the content behind it, and paints the optics of real water: a soft
refraction rim, a bright caustic, a specular highlight towards the light and
a thin bright edge, plus a soft shadow. It stretches like liquid while it
moves or is dragged.

<p align="center">
  <img src="https://raw.githubusercontent.com/sajiths07/liquid_glass_ui/main/screenshots/gallery.png" width="250" alt="Default capsule drop">
  <img src="https://raw.githubusercontent.com/sajiths07/liquid_glass_ui/main/screenshots/drop_circle.png" width="250" alt="Circle drop with blue shadow">
  <img src="https://raw.githubusercontent.com/sajiths07/liquid_glass_ui/main/screenshots/drop_tinted.png" width="250" alt="Rounded drop with pink shadow">
</p>
<p align="center"><em>Capsule (default) Â· Circle with a blue shadow and 1.3Ã— magnification Â· Rounded rectangle with a pink shadow</em></p>

Everything about the drop is configurable with `LiquidGlassDropStyle`:

```dart
LiquidGlassNavigationBar(
  dropStyle: LiquidGlassDropStyle(
    shape: LiquidGlassDropShape.circle,     // capsule, circle, roundedRectangle
    size: const Size(52, 52),               // null dimensions fill the slot
    magnification: 1.3,                     // 1 turns the lens off
    shadowColor: const Color(0x660A84FF),   // transparent removes the shadow
    shadowBlur: 16,
    shadowOffset: const Offset(0, 6),
    tintColor: Colors.white,
    tintOpacity: 0.12,
    borderColor: Colors.white70,
    borderWidth: 1,
    highlightColor: Colors.white,           // caustic, highlight and edge
    opticsIntensity: 0.9,                   // 0 removes the painted optics
    stretch: true,                          // liquid stretch while moving
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

### Overlays

```dart
final ok = await showLiquidGlassDialog<bool>(
  context: context,
  builder: (context) => LiquidGlassDialog(
    title: const Text('Delete photo?'),
    content: const Text('This cannot be undone.'),
    actions: [
      LiquidGlassButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
      LiquidGlassButton(prominent: true, onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
    ],
  ),
);

await showLiquidGlassSheet(context: context, builder: (_) => const MySheet());

LiquidGlassMenuButton(
  semanticLabel: 'More',
  items: [
    LiquidGlassMenuItem(label: 'Copy', onPressed: copy),
    LiquidGlassMenuItem(label: 'Delete', destructive: true, onPressed: delete),
  ],
  child: const Icon(Icons.more_horiz),
)
```

## Animation

`LiquidGlassAnimationConfig` controls duration, curve, an optional spring and
the reduced-motion duration. Presets: `fluid`, `snappy`, `bouncy` and
`gentle`.

```dart
const LiquidGlassAnimationConfig(
  duration: Duration(milliseconds: 400),
  curve: Curves.easeOutCubic,
  spring: SpringDescription(mass: 1, stiffness: 260, damping: 27),
)
```

The theme has three configs: `animation` (indicators and general motion),
`interactionAnimation` (press feedback) and `overlayAnimation` (dialogs,
sheets and menus). Interactive motion uses the spring and keeps velocity
when interrupted; route transitions are time-based and use the curve.

## Accessibility

- All controls expose semantics (buttons, toggles, sliders, selection,
  headers) and accept `semanticLabel`. `LiquidGlassIconButton` requires one.
- Keyboard: focus highlights, Enter/Space activation and arrow keys for
  sliders.
- Touch targets are at least 44 Ã— 44 logical pixels.
- **Reduced motion** (`MediaQuery.disableAnimations` or
  `LiquidGlassThemeData.reduceMotion`) replaces movement with short fades.
- **Reduced transparency** (`LiquidGlassThemeData.reduceTransparency`)
  swaps glass for an opaque surface and removes reflections. Flutter does
  not expose the platform setting, so forward it from your app if needed.
- **High contrast** (`MediaQuery.highContrast`) strengthens borders and the
  foreground color.

## Migrating from 0.4.x

Existing code keeps compiling:

```dart
import 'package:liquid_glass_ui/widgets/liquid_glass_container.dart';

LiquidGlassContainer(blur: 10, opacity: 0.2, child: Text('Still works'));
```

Visual changes in 0.5.0: `LiquidGlassContainer` now renders through the new
glass engine (gradient border, highlights and a soft shadow), and the
default foreground text color comes from the glass theme. Pass
`quality: LiquidGlassQuality.minimal` for a look closer to 0.4.

## Platform support and limitations

- Works on Android, iOS, web, Windows, macOS and Linux. The package has been
  built and tested on Windows (unit, widget and golden tests, and a
  Windows/web build of the example); other platforms have not yet been
  verified on devices.
- Premium refraction requires Impeller (`ImageFilter.isShaderFilterSupported`).
  Elsewhere it falls back to standard quality.
- Backdrop blur is relatively expensive; prefer `minimal` quality for many
  simultaneous surfaces.
- `LiquidGlassPageRoute` does not provide an iOS-style swipe-back gesture.
- Golden images are generated on Windows and are skipped on other hosts.
- The navigation drop's magnifying lens is not used on the web (see
  [Water-drop indicator](#water-drop-indicator)).

## Example

The [`example`](example) app contains a gallery, every control, all
overlays, the quality modes and a live configuration screen for blur,
opacity, tint, borders, highlights, refraction, quality, the navigation drop
(shape, size, magnification and shadow color), motion, dark mode, reduced
motion and reduced transparency.

<p align="center">
  <img src="https://raw.githubusercontent.com/sajiths07/liquid_glass_ui/main/screenshots/overlays.png" width="250" alt="Overlays page">
  <img src="https://raw.githubusercontent.com/sajiths07/liquid_glass_ui/main/screenshots/configure.png" width="250" alt="Live configuration page">
</p>

```sh
cd example
flutter run
```

## License

MIT. See [LICENSE](LICENSE).
