// Copyright 2024 Elloramir.
// All rights over the code are reserved.

varying vec4 screenPosition;
varying vec4 viewPosition;

// Bayer matrix for dithering
float bayerMatrix[16] = float[16](
    0.0,  8.0,  2.0, 10.0,
   12.0,  4.0, 14.0,  6.0,
    3.0, 11.0,  1.0,  9.0,
   15.0,  7.0, 13.0,  5.0
);

vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ) {
	vec4 pixel = Texel(texture, texture_coords);

	float fogDensity = 0.1;
	float dist = length(viewPosition - screenPosition);
	vec4 fogColor = vec4(0, 0, 0, 1.0);

	// Exponential fog
	float fogFactor = 1.0 / exp((dist * fogDensity) * (dist * fogDensity));
	fogFactor = clamp(fogFactor, 0.0, 1.0);

	// Dithering
	int x = int(mod(screen_coords.x, 4.0));
	int y = int(mod(screen_coords.y, 4.0));
	float threshold = bayerMatrix[y * 4 + x] / 32.0;

	// Apply dithering to fog factor
	float ditheredFogFactor = fogFactor > threshold ? fogFactor : fogFactor * 0.6;
	fogColor *= ditheredFogFactor;

	// Apply dithered fog to the pixel
	return mix(pixel, fogColor, 1.0 - ditheredFogFactor);

	// return mix(pixel, fogColor, 1.0 - fogFactor);
}
