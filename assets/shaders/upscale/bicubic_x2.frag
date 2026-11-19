#include <flutter/runtime_effect.glsl>

uniform float uSrcWidth;
uniform float uSrcHeight;
uniform float uDstWidth;
uniform float uDstHeight;
uniform sampler2D uInput;

out vec4 fragColor;

float cubic(float t) {
    float a = -0.5;
    float at = abs(t);
    if (at < 1.0) {
        return (a + 2.0) * at * at * at - (a + 3.0) * at * at + 1.0;
    }
    if (at < 2.0) {
        return a * at * at * at - 5.0 * a * at * at + 8.0 * a * at - 4.0 * a;
    }
    return 0.0;
}

vec4 cubicSample(vec2 uv) {
    vec2 srcSize = vec2(uSrcWidth, uSrcHeight);
    vec2 pixel = uv * srcSize - 0.5;
    vec2 fracVal = fract(pixel);
    vec2 base = floor(pixel);

    vec4 result = vec4(0.0);
    for (int j = -1; j <= 2; j++) {
        float wy = cubic(float(j) - fracVal.y);
        for (int i = -1; i <= 2; i++) {
            float wx = cubic(float(i) - fracVal.x);
            vec2 sampleUV = (base + vec2(float(i), float(j)) + 0.5) / srcSize;
            result += texture(uInput, clamp(sampleUV, 0.0, 1.0)) * wx * wy;
        }
    }
    return clamp(result, 0.0, 1.0);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / vec2(uDstWidth, uDstHeight);
    fragColor = cubicSample(uv);
}
