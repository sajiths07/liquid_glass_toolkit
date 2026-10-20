import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Load state of the package's fragment shaders.
enum LiquidGlassShaderStatus {
  /// [LiquidGlassShaders.ensureLoaded] has not been called yet.
  notLoaded,

  /// Shader programs are being loaded.
  loading,

  /// Both shader programs loaded successfully.
  ready,

  /// Loading failed or shader assets are not available. Surfaces keep using
  /// canvas fallbacks. See [LiquidGlassShaders.loadError].
  unavailable,
}

/// Loads and owns the fragment programs used by liquid-glass surfaces.
///
/// Loading happens lazily the first time a surface with
/// `LiquidGlassQuality.standard` or `premium` is built, so calling anything
/// here is optional. Call [ensureLoaded] early (for example before
/// `runApp`) to avoid the first frames using the canvas fallback.
///
/// Loading reads the compiled shader assets and creates
/// [ui.FragmentProgram]s. It does not guarantee that the GPU pipeline is
/// already compiled; with Impeller shaders are compiled ahead of time, with
/// Skia the first draw may still compile the shader.
///
/// Exactly two programs are cached for the lifetime of the process; no
/// per-surface caches exist.
abstract final class LiquidGlassShaders {
  static const String _lightingName = 'shaders/glass_lighting.frag';
  static const String _refractionName = 'shaders/glass_refraction.frag';
  static const String _packagePrefix = 'packages/liquid_glass_widget/';

  static final ValueNotifier<LiquidGlassShaderStatus> _status =
      ValueNotifier<LiquidGlassShaderStatus>(LiquidGlassShaderStatus.notLoaded);
  static Future<void>? _loading;
  static ui.FragmentProgram? _lighting;
  static ui.FragmentProgram? _refraction;
  static Object? _loadError;

  /// Current load state. Surfaces listen to this and repaint when the
  /// shaders become available.
  static ValueListenable<LiquidGlassShaderStatus> get status => _status;

  /// The error that made shaders [LiquidGlassShaderStatus.unavailable].
  static Object? get loadError => _loadError;

  /// The rim/specular lighting program, or `null` if not loaded.
  static ui.FragmentProgram? get lightingProgram => _lighting;

  /// The backdrop refraction program, or `null` if not loaded.
  static ui.FragmentProgram? get refractionProgram => _refraction;

  /// Whether the active renderer can run backdrop shader filters
  /// (`ImageFilter.shader`). True on Impeller, false on Skia and web.
  static bool get rendererSupportsBackdropShaders =>
      ui.ImageFilter.isShaderFilterSupported;

  /// Whether premium refraction can currently render.
  static bool get supportsRefraction =>
      _refraction != null && rendererSupportsBackdropShaders;

  /// Loads the shader programs once. Safe to call repeatedly and from
  /// multiple places; all callers share the same future. Never throws:
  /// failures are reported through [FlutterError.reportError] and reflected
  /// in [status] and [loadError].
  static Future<void> ensureLoaded() => _loading ??= _load();

  static Future<void> _load() async {
    // ensureLoaded may be called from a build method; notifying listeners
    // synchronously there would mark other widgets dirty during build.
    await Future<void>.microtask(() {});
    _status.value = LiquidGlassShaderStatus.loading;
    try {
      final String prefix = await _resolvePrefix();
      final List<ui.FragmentProgram> programs =
          await Future.wait(<Future<ui.FragmentProgram>>[
            ui.FragmentProgram.fromAsset('$prefix$_lightingName'),
            ui.FragmentProgram.fromAsset('$prefix$_refractionName'),
          ]);
      _lighting = programs[0];
      _refraction = programs[1];
      _status.value = LiquidGlassShaderStatus.ready;
    } catch (error, stack) {
      _loadError = error;
      _status.value = LiquidGlassShaderStatus.unavailable;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'liquid_glass_widget',
          context: ErrorDescription(
            'while loading liquid glass shaders; surfaces will use the '
            'canvas fallback',
          ),
        ),
      );
    }
  }

  /// Shader assets are keyed with a `packages/liquid_glass_widget/` prefix when
  /// the package is a dependency, and without it when this package is the
  /// root project (its own tests). The manifest tells us which one exists.
  static Future<String> _resolvePrefix() async {
    final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(
      rootBundle,
    );
    final List<String> assets = manifest.listAssets();
    if (assets.contains('$_packagePrefix$_lightingName')) {
      return _packagePrefix;
    }
    if (assets.contains(_lightingName)) {
      return '';
    }
    throw StateError(
      'liquid_glass_widget shader assets were not found in the asset manifest. '
      'Make sure the package is a regular pub dependency so its `shaders:` '
      'section is bundled.',
    );
  }

  /// Resets the loader. Only for tests.
  @visibleForTesting
  static void debugReset() {
    _loading = null;
    _lighting = null;
    _refraction = null;
    _loadError = null;
    _status.value = LiquidGlassShaderStatus.notLoaded;
  }
}
