#include <flutter/runtime_effect.glsl>

uniform float uWidth;
uniform float uHeight;
uniform sampler2D uInput;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / vec2(uWidth, uHeight);
    vec4 c = texture(uInput, uv);
    float luma = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
    float clampFactor = luma > 0.95 ? (0.95 / max(luma, 0.001)) : 1.0;
    fragColor = vec4(c.rgb * clampFactor, c.a);
}
