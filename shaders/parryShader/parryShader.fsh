//
// Sword glow: recolours ONLY the sword's pixels with a rainbow band that
// climbs from the bottom of the sprite to the top, with a trail colour behind it
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec4  u_uvs;        // where this frame sits on the texture page: left, top, right, bottom
uniform float u_sweep;      // where the rainbow's leading edge is (0 = bottom, 1 = top)
uniform float u_band;       // how tall the rainbow band is
uniform float u_trail_len;  // how long the trail is
uniform vec3  u_trail;      // trail colour (red, green, blue from 0 to 1)
uniform float u_colours;    // how many colours are in the band at once (2)
uniform float u_hue;        // which colour the band starts on this pass (0..1 around the rainbow)
uniform float u_saturation; // how strong the colours are (1 = full rainbow, 0 = plain sword)

// turns 0..1 into a rainbow colour: red -> yellow -> green -> blue -> purple -> red
vec3 rainbow(float h) {
    return clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

void main() {
    vec4 col = texture2D(gm_BaseTexture, v_vTexcoord);

    // is this pixel part of the sword?
    // the blade is bright and cool (white/grey); the skull is bright but warm (more red than blue)
    float bright = (col.r + col.g + col.b) / 3.0;
    float warm   = col.r - col.b;
    bool is_sword = col.a > 0.0 && bright > 0.6 && warm < 0.06;

    if (is_sword) {
        // how high up this pixel is: 0 = bottom of the sprite, 1 = top
        float height = 1.0 - (v_vTexcoord.y - u_uvs.y) / (u_uvs.w - u_uvs.y);

        // how far BELOW the rainbow's leading edge this pixel is
        float behind = u_sweep - height;

        if (behind >= 0.0 && behind < u_band) {
            // inside the band: split it into u_colours solid stripes (0, 1, ...)
            float stripe = floor(behind / u_band * u_colours);

            // each stripe is the next colour round the rainbow
            // (6 colours: red, yellow, green, cyan, blue, purple, so each is 1/6 of the way round)
            // mixed with the sword's own colour, so it's a softer tint that keeps the blade's shading
            col.rgb = mix(col.rgb, rainbow(fract(u_hue + stripe / 6.0)), u_saturation);
        }
        else if (behind >= u_band && behind < u_band + u_trail_len) {
            // inside the trail: trail colour, fading out the further behind it is
            float fade = 1.0 - (behind - u_band) / u_trail_len;
            col.rgb = mix(col.rgb, u_trail, fade);
        }
    }

    gl_FragColor = v_vColour * col;
}