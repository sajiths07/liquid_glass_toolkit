#version 460 core
// liquid_glass_toolkit: directional rim light, inner bevel and specular lobe for a
// rounded-rectangle glass surface. Painted on top of the tint, below content.

#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uSize;        // surface size in logical pixels
uniform vec4 uRadii;       // corner radii: top-left, top-right, bottom-right, bottom-left
uniform vec2 uLight;       // unit vector pointing from the centre towards the light
uniform float uThickness;  // bevel width in logical pixels
uniform float uRim;        // rim light intensity [0, 1]
uniform float uSpecular;   // specular intensity [0, 1]
uniform float uOpacity;    // global highlight opacity [0, 1]
uniform vec4 uColor;       // highlight color (rgb), alpha unused

out vec4 fragColor;

float roundedBoxSdf(vec2 p, vec2 halfSize, vec4 r) {
  float radius = p.x > 0.0 ? (p.y > 0.0 ? r.z : r.y) : (p.y > 0.0 ? r.w : r.x);
  radius = min(radius, min(halfSize.x, halfSize.y));
  vec2 q = abs(p) - halfSize + radius;
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;
}

void main() {
  vec2 halfSize = uSize * 0.5;
  vec2 p = FlutterFragCoord().xy - halfSize;
  float d = roundedBoxSdf(p, halfSize, uRadii);

  const float e = 0.75;
  vec2 grad = vec2(
    roundedBoxSdf(p + vec2(e, 0.0), halfSize, uRadii) -
      roundedBoxSdf(p - vec2(e, 0.0), halfSize, uRadii),
    roundedBoxSdf(p + vec2(0.0, e), halfSize, uRadii) -
      roundedBoxSdf(p - vec2(0.0, e), halfSize, uRadii));
  vec2 normal = length(grad) > 0.0001 ? normalize(grad) : vec2(0.0, -1.0);

  float t = max(uThickness, 1.0);
  float depth = clamp(-d / t, 0.0, 1.0);
  float edge = 1.0 - depth;

  float facing = dot(normal, uLight);
  float lit = max(facing, 0.0);
  float bounce = max(-facing, 0.0) * 0.4;
  float rim = pow(edge, 4.0) * (lit + bounce) * uRim;
  float bevel = pow(edge, 2.0) * 0.12 * uRim;

  vec2 specCentre = uLight * halfSize * 0.62;
  vec2 specRadius = max(halfSize * vec2(0.85, 0.5), vec2(1.0));
  vec2 sp = (p - specCentre) / specRadius;
  float spec = exp(-dot(sp, sp) * 2.6) * uSpecular * 0.28;

  float alpha = clamp((rim + bevel + spec) * uOpacity, 0.0, 1.0);
  alpha *= 1.0 - smoothstep(-0.5, 0.5, d);
  fragColor = vec4(uColor.rgb * alpha, alpha);
}
