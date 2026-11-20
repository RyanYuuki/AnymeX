#include <flutter/runtime_effect.glsl>

uniform float uWidth;
uniform float uHeight;
uniform float uStrength;
uniform sampler2D uInput;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / vec2(uWidth, uHeight);
    vec2 texel = 1.0 / vec2(uWidth, uHeight);

    vec4 center = texture(uInput, uv);
    vec4 blur =
        texture(uInput, uv + vec2(-texel.x, -texel.y)) * 0.0625 +
        texture(uInput, uv + vec2(      0.0, -texel.y)) * 0.125  +
        texture(uInput, uv + vec2( texel.x, -texel.y)) * 0.0625 +
        texture(uInput, uv + vec2(-texel.x,       0.0)) * 0.125  +
        center                                          * 0.25   +
        texture(uInput, uv + vec2( texel.x,       0.0)) * 0.125  +
        texture(uInput, uv + vec2(-texel.x,  texel.y)) * 0.0625 +
        texture(uInput, uv + vec2(      0.0,  texel.y)) * 0.125  +
        texture(uInput, uv + vec2( texel.x,  texel.y)) * 0.0625;

    vec4 diff = center - blur;
    vec4 localMin = min(center, blur);
    vec4 localMax = max(center, blur);
    fragColor = clamp(center + uStrength * diff, localMin, localMax);
}
