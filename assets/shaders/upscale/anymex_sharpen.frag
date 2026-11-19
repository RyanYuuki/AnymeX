#include <flutter/runtime_effect.glsl>

uniform float uWidth;
uniform float uHeight;
uniform float uStrength;
uniform sampler2D uInput;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / vec2(uWidth, uHeight);
    vec2 texel = 1.0 / vec2(uWidth, uHeight);

    vec4 a = texture(uInput, uv + vec2(0.0, -texel.y));
    vec4 b = texture(uInput, uv + vec2(-texel.x, 0.0));
    vec4 c = texture(uInput, uv);
    vec4 d = texture(uInput, uv + vec2(texel.x, 0.0));
    vec4 e = texture(uInput, uv + vec2(0.0, texel.y));

    vec3 minRgb = min(min(min(a.rgb, b.rgb), min(d.rgb, e.rgb)), c.rgb);
    vec3 maxRgb = max(max(max(a.rgb, b.rgb), max(d.rgb, e.rgb)), c.rgb);

    vec3 contrast = min(minRgb, 1.0 - maxRgb);
    vec3 amp = clamp(contrast / max(maxRgb, vec3(0.0001)), 0.0, 1.0);
    vec3 w = -sqrt(amp) * (0.125 * clamp(uStrength, 0.2, 2.5));

    vec3 neighborsSum = a.rgb + b.rgb + d.rgb + e.rgb;
    vec3 result = (c.rgb + neighborsSum * w) / (1.0 + 4.0 * w);

    fragColor = vec4(clamp(result, minRgb, maxRgb), c.a);
}
