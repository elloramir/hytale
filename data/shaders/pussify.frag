uniform float time;

// This is a distortion effect that gives a hand-drawn cartoon look
// to our sprites. This is extremely useful because it gives us a lot
// of natural dynamics with close to zero lines of code.
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = texture_coords;

	// These values were obtained by doing this
	// so many times until it was good enough.
    uv.y += 0.005 * sin(uv.x * 100 + time*2);
    uv.x += 0.005 * cos(uv.y * 0.5 + time);

    return Texel(texture, uv) * color;
}
