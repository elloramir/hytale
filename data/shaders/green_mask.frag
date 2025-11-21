uniform Image mask;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 maskPixel = Texel(mask, (screen_coords - vec2(10, 0))/vec2(33, 40));
    vec4 pixel = Texel(texture, texture_coords);

    if (maskPixel != vec4(0, 1, 0, 1)) {
        discard;
    }

    return pixel * color;
}