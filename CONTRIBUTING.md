# Contributing

Thanks for helping improve `liquid_glass_widget`.

## Getting started

```sh
git clone https://github.com/sajiths07/liquid_glass_widget.git
cd liquid_glass_widget
flutter pub get
cd example && flutter pub get && flutter run
```

## Project layout

| Path | Contents |
| --- | --- |
| `lib/liquid_glass_widget.dart` | Public exports. |
| `lib/src/core` | `LiquidGlassStyle` and `LiquidGlassQuality`. |
| `lib/src/rendering` | Backdrop filters, painters and the refraction render object. |
| `lib/src/shaders` | Shader loading and capability detection. |
| `lib/src/animation` | Animation config, presence and transitions. |
| `lib/src/theme` | `LiquidGlassTheme` and `LiquidGlassThemeData`. |
| `lib/src/widgets` | Surface and controls. |
| `lib/src/navigation` | Scaffold, bars and page transitions. |
| `lib/src/overlays` | Dialog, sheet, menu and morph routes. |
| `lib/widgets` | The 0.x `LiquidGlassContainer` import path (keep it working). |
| `shaders` | GLSL fragment shaders. |
| `test` | Unit, widget, golden and shader compile tests. |
| `example` | Showcase app with a live configuration screen. |

## Before opening a pull request

```sh
dart format .
flutter analyze
flutter test
cd example && flutter analyze && flutter test
```

- Add tests for new behavior.
- Every public member needs a doc comment (`public_member_api_docs` is on).
- Keep accessibility intact: semantics, keyboard support, 44 px touch
  targets, reduced motion and reduced transparency.
- Visual changes: regenerate goldens on Windows with
  `flutter test --update-goldens test/golden_test.dart` and include
  before/after screenshots in the PR.
- Shader changes must compile with `impellerc` (covered by
  `test/shaders_test.dart`) and need a fallback when shaders are unavailable.
- Add an entry to `CHANGELOG.md` under an "Unreleased" heading.

## Releases (maintainers)

1. Update `version` in `pubspec.yaml` and move the changelog entries under
   the new version.
2. Run `flutter pub publish --dry-run`.
3. Commit, then tag and push: `git tag v1.0.0 && git push origin v1.0.0`.
   The publish workflow releases to pub.dev once automated publishing is
   enabled for the package.

## Code of conduct

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md).
