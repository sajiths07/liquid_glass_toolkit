# Agent guidelines

Guidance for AI coding agents working in this repository.

- This is a published Flutter package (`liquid_glass_ui`). Do not rename
  it, change its license or repository URL, or reuse a published version.
- Never run `flutter pub publish` (only `--dry-run`). Releases happen by
  pushing a `v<version>` tag, done by a maintainer.
- Never add tokens or credentials to the repository.
- Keep the public API backwards compatible, including the
  `package:liquid_glass_ui/widgets/liquid_glass_container.dart` import.
- The package depends only on Flutter. Do not add dependencies without
  maintainer approval.
- Before finishing, run `dart format .`, `flutter analyze` and
  `flutter test` in the root and in `example/`.
- Golden images are generated on Windows; regenerate them only for
  intentional visual changes.
- See [CONTRIBUTING.md](CONTRIBUTING.md) for layout and conventions.
