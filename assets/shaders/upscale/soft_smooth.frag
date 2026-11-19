#include <flutter/runtime_effect.glsl>

uniform float uWidth;
uniform float uHeight;
uniform float uSigmaColor;
uniform sampler2D uInput;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / vec2(uWidth, uHeight);
    vec2 texel = 1.0 / vec2(uWidth, uHeight);
    vec4 center = texture(uInput, uv);
    vec4 accum = vec4(0.0);
    float weightSum = 0.0;
    float invTwoSigmaSq = 1.0 / max(2.0 * uSigmaColor * uSigmaColor, 0.0001);

    for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
            vec4 s = texture(uInput, uv + vec2(float(dx), float(dy)) * texel);
            float colorDist = length(s.rgb - center.rgb);
            float w = exp(-colorDist * colorDist * invTwoSigmaSq);
            accum += s * w;
            weightSum += w;
        }
    }
    fragColor = accum / max(weightSum, 0.0001);
}
