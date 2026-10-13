// how full the charge circle is: 0 = just started, 1 = full
var _charge = 0;
if (state == PlayerState.PARRY) {
    if (parry_raising) {
        _charge = min(1, image_index / image_number);              // how far through the raise animation
    } else {
        _charge = min(1, parry_charge_timer / parry_charge_time);  // no raise animation: use the timer
    }
    if (parry_charged) _charge = 1;   // guard is up: circle stays full
}

// ---- 1. the charge circle on the ground (drawn BEFORE him, so it's underneath) ----
if (state == PlayerState.PARRY) {
    var _R = parry_circle_radius;

    gpu_set_blendmode(bm_add);
    draw_set_colour(parry_fx_colour);

    // the outline: full size from the start, so you can see what's being filled
    draw_set_alpha(0.5);
    for (var i = 0; i < 2; i++) {
        var _o = _R - i;
        draw_ellipse(x - _o, y - _o * 0.4, x + _o, y + _o * 0.4, true);
    }

    // the fill: grows from the middle out to the outline as it charges
    var _r = _R * _charge;
    draw_set_alpha(0.35);
    if (parry_charged) draw_set_alpha(0.2);   // softer once full, while you hold the guard
    if (_r > 1) {
        draw_ellipse(x - _r, y - _r * 0.4, x + _r, y + _r * 0.4, false);
    }

    draw_set_alpha(1);
    draw_set_colour(c_white);
    gpu_set_blendmode(bm_normal);
}

// ---- 2. the knight: with the rainbow sword shader once fully charged ----
if (state == PlayerState.PARRY && parry_charged) {
    shader_set(parryShader);

    var _uvs = sprite_get_uvs(sprite_index, image_index);
    shader_set_uniform_f(u_uvs, _uvs[0], _uvs[1], _uvs[2], _uvs[3]);
    shader_set_uniform_f(u_sweep, sword_sweep);
    shader_set_uniform_f(u_band, sword_band);
    shader_set_uniform_f(u_trail_len, sword_trail_len);
    shader_set_uniform_f(u_colours, sword_colours);
    shader_set_uniform_f(u_hue, sword_hue);
    shader_set_uniform_f(u_saturation, sword_saturation);
    shader_set_uniform_f(u_trail,
        colour_get_red(sword_trail_colour)   / 255,
        colour_get_green(sword_trail_colour) / 255,
        colour_get_blue(sword_trail_colour)  / 255);

    draw_self();
    shader_reset();
} else {
    draw_self(); // draw the knight normally
}

// ---- 3. he glows in the parry colour while charging ----
if (state == PlayerState.PARRY && !parry_charged) {
    gpu_set_fog(true, parry_fx_colour, 0, 0);
    draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, 0, c_white, 0.6 * _charge);
    gpu_set_fog(false, c_white, 0, 0);
}

// draw the hitbox outline in red
draw_rectangle_colour(bbox_left, bbox_top, bbox_right, bbox_bottom,
                      c_red, c_red, c_red, c_red, true);
