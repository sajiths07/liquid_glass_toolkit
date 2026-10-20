#version 460 core
// liquid_glass_toolkit: backdrop refraction for a rounded-rectangle glass surface.
// Used through ImageFilter.shader on a BackdropFilter (Impeller only).
// Content behind the edge band is sampled further inwards, which makes the rim
// look like a thick, convex lens. A small amount of chromatic dispersion is
// applied in the same band.

#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uTextureSize;  // set by the engine: size of the backdrop texture
uniform vec4 uRect;         // surface origin (xy) and size (zw) in texture pixels
uniform vec4 uRadii;        // corner radii in texture pixels (tl, tr, br, bl)
uniform float uThickness;   // refraction band width in texture pixels
uniform float uStrength;    // refraction strength [0, 1]
uniform float uDispersion;  // chromatic dispersion [0, 1]

uniform sampler2D uTexture; // set by the engine: the backdrop

out vec4 fragColor;

float roundedBoxSdf(vec2 p, vec2 halfSize, vec4 r) {
  float radius = p.x > 0.0 ? (p.y > 0.0 ? r.z : r.y) : (p.y > 0.0 ? r.w : r.x);
  radius = min(radius, min(halfSize.x, halfSize.y));
  vec2 q = abs(p) - halfSize + radius;
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;
}

vec4 sampleBackdrop(vec2 px) {
  vec2 uv = clamp(px / uTextureSize, vec2(0.0), vec2(1.0));
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  return texture(uTexture, uv);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 halfSize = uRect.zw * 0.5;
  vec2 p = frag - (uRect.xy + halfSize);
  float d = roundedBoxSdf(p, halfSize, uRadii);

  if (d > 0.0 || uStrength <= 0.0 || halfSize.x < 1.0 || halfSize.y < 1.0) {
    fragColor = sampleBackdrop(frag);
    return;
  }

  const float e = 1.0;
  vec2 grad = vec2(
    roundedBoxSdf(p + vec2(e, 0.0), halfSize, uRadii) -
      roundedBoxSdf(p - vec2(e, 0.0), halfSize, uRadii),
    roundedBoxSdf(p + vec2(0.0, e), halfSize, uRadii) -
      roundedBoxSdf(p - vec2(0.0, e), halfSize, uRadii));
  vec2 normal = length(grad) > 0.0001 ? normalize(grad) : vec2(0.0);

  float t = max(uThickness, 1.0);
  float depth = clamp(-d / t, 0.0, 1.0);
  float bend = (1.0 - depth) * (1.0 - depth);

  vec2 offset = -normal * bend * t * uStrength - p * 0.035 * uStrength;
  vec2 base = frag + offset;

  vec2 shift = normal * bend * uDispersion * t * 0.18;
  vec4 centre = sampleBackdrop(base);
  float r = sampleBackdrop(base + shift).r;
  float b = sampleBackdrop(base - shift).b;
  // Keep the result a valid premultiplied color.
  fragColor = vec4(min(r, centre.a), centre.g, min(b, centre.a), centre.a);
}
