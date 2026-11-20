#include <flutter/runtime_effect.glsl>

uniform float uWidth;
uniform float uHeight;
uniform float uSigmaSpace;
uniform float uSigmaColor;
uniform sampler2D uInput;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / vec2(uWidth, uHeight);
    vec2 texel = 1.0 / vec2(uWidth, uHeight);
    vec4 center = texture(uInput, uv);
    vec4 accum = vec4(0.0);
    float weightSum = 0.0;

    float invTwoSpaceSq = 1.0 / max(2.0 * uSigmaSpace * uSigmaSpace, 0.0001);
    float invTwoColorSq = 1.0 / max(2.0 * uSigmaColor * uSigmaColor, 0.0001);

    for (int dx = -2; dx <= 2; dx++) {
        for (int dy = -2; dy <= 2; dy++) {
            float spaceDist = float(dx * dx + dy * dy);
            float sw = exp(-spaceDist * invTwoSpaceSq);
            vec4 s = texture(uInput, uv + vec2(float(dx), float(dy)) * texel);
            float colorDist = length(s.rgb - center.rgb);
            float cw = exp(-colorDist * colorDist * invTwoColorSq);
            float w = sw * cw;
            accum += s * w;
            weightSum += w;
        }
    }
    fragColor = accum / max(weightSum, 0.0001);
}
