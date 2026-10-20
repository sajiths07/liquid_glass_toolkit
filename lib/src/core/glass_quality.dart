/// Controls how much rendering work a liquid-glass surface performs.
///
/// Each level changes the actual rendering pipeline, not only a label:
///
/// | Level      | Backdrop work                          | Lighting                          |
/// |------------|----------------------------------------|-----------------------------------|
/// | [minimal]  | Gaussian blur only                     | Flat top sheen painted on canvas  |
/// | [standard] | Blur + saturation/brightness/contrast  | Rim, bevel and specular lighting  |
/// | [premium]  | Standard + refraction shader (Impeller)| Same as standard                  |
///
/// [premium] silently degrades to [standard] when the active renderer cannot
/// run backdrop shaders (Skia, web, or when the shader failed to load). Use
/// `LiquidGlassShaders.supportsRefraction` to check at runtime.
enum LiquidGlassQuality {
  /// Lowest cost. Uses a single blur filter, a tint fill, a border and a
  /// simple gradient sheen. Saturation, brightness, contrast, refraction,
  /// rim light and specular settings are ignored. Never requires a shader.
  minimal,

  /// Balanced default. Adds a color-matrix filter (saturation, brightness,
  /// contrast) to the backdrop and draws directional rim light, an inner
  /// bevel and a specular lobe using a fragment shader. Falls back to
  /// canvas gradients while the shader loads or if it is unavailable.
  standard,

  /// Highest fidelity. Adds a backdrop refraction shader that bends and
  /// slightly disperses the content behind the glass near its edges. Only
  /// active on renderers that support `ImageFilter.shader` (Impeller).
  premium,
}
