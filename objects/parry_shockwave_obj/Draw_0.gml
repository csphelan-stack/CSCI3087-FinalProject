// fade as it spreads: bright near the start, invisible at full size
var _alpha = 1 - (radius / max_radius);

gpu_set_blendmode(bm_add);
draw_set_colour(colour);

// the ring: a few outlines drawn next to each other make a thicker line
draw_set_alpha(_alpha);
for (var i = 0; i < thickness; i++) {
    var _r = radius - i;
    draw_ellipse(x - _r, y - _r * squash, x + _r, y + _r * squash, true);
}

// a faint fill inside, so it looks like a wave of light, not just a line
draw_set_alpha(_alpha * 0.25);
draw_ellipse(x - radius, y - radius * squash, x + radius, y + radius * squash, false);

// put the global draw settings back
draw_set_alpha(1);
draw_set_colour(c_white);
gpu_set_blendmode(bm_normal);
