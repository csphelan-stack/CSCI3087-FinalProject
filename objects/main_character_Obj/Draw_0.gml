// (the charge circle / palette sword glow / charge glow are fx functions at the bottom of parryState)

// how full the special's charge is: 0 = just started, 1 = full
var _special_charge = special_charged ? 1 : min(1, special_charge_timer / special_charge_time);

// the whirlwind special has two halves: charging (not full yet), then spinning (full)
var _whirlwind      = (state == PlayerState.SPECIAL && special_equipped == SpecialState.WHIRLWIND);
var _whirl_charging = _whirlwind && !special_charged;
var _whirl_spinning = _whirlwind && special_charged;

// ---- 0. special charge circle on the ground (drawn BEFORE him, so it's underneath) ----
if (_whirl_charging) {
    fxChargeCircleDraw(_special_charge, special_charged);
}

// ---- 1. the player: palette colours up the sword all through the spin ----
if (_whirl_spinning) {
    fxRainbowSwordDraw();
} else {
    draw_self();
}

// ---- 1b. special: glows while charging, wind swirls round him while spinning ----
if (_whirl_charging) {
    fxChargeGlowDraw(_special_charge);
}
if (_whirl_spinning) {
    specialSpinRingDraw();
}

// ---- 2. perfect-parry window: a bright white flash right as the guard goes up, fading as the window closes ----
if (state == PlayerState.PARRY && parry_perfect_timer > 0) {
    gpu_set_fog(true, c_white, 0, 0);
    draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, 0, c_white, 0.8 * parry_perfect_timer / parry_perfect_window);
    gpu_set_fog(false, c_white, 0, 0);
}

// ---- 3. blocked a hit: quick flash in the parry colour ----
if (block_flash > 0) {
    gpu_set_fog(true, parry_fx_colour, 0, 0);
    draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, 0, c_white, 0.7 * block_flash / block_flash_time);
    gpu_set_fog(false, c_white, 0, 0);
}

// ---- 4. blinks white when the guard meter is about to run out (exhausted = long cooldown) ----
if (state == PlayerState.PARRY && parry_exhaust_timer <= parry_blink_time) {
    var _blink_rate = (parry_exhaust_timer < parry_blink_time / 2) ? 3 : 6;   // blinks faster near the end
    if ((parry_exhaust_timer div _blink_rate) mod 2 == 0) {
        gpu_set_fog(true, c_white, 0, 0);
        draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, 0, c_white, 0.75);
        gpu_set_fog(false, c_white, 0, 0);
    }
}

// ---- 5. flashes red while stunned (guard got broken) ----
if (state == PlayerState.STUNNED && (stun_timer div 4) mod 2 == 0) {
    gpu_set_fog(true, c_red, 0, 0);
    draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, 0, c_white, 0.6);
    gpu_set_fog(false, c_white, 0, 0);
}

// ---- 6. guard meter above his head: shows while guarding or refilling ----
if (state == PlayerState.PARRY || parry_exhaust_timer < parry_exhaust_time) {
    var _w = 24;
    var _bx = x - _w / 2;
    var _by = bbox_top - 6;
    var _pct = parry_exhaust_timer / parry_exhaust_time;
    var _col = parry_fx_colour;
    if (parry_exhaust_timer <= parry_blink_time) _col = c_red;      // nearly empty
    if (parry_cooldown > parry_recover_time) _col = c_dkgray;       // on the long cooldown: can't parry yet
    draw_set_colour(c_black);
    draw_rectangle(_bx - 1, _by - 1, _bx + _w, _by + 2, false);
    draw_set_colour(_col);
    if (_pct > 0) draw_rectangle(_bx, _by, _bx + (_w - 1) * _pct, _by + 1, false);
    draw_set_colour(c_white);
}

