// (the charge circle / palette sword glow / charge glow are fx functions at the bottom of parryState)

// how full the special's charge is: 0 = just started, 1 = full
var _special_charge = tsunami_charged ? 1 : min(1, tsunami_charge_timer / tsunami_charge_time);

// the Bladed Tsunami has two halves: charging (not full yet), then the tsunami itself (full)
var _tsunami          = (state == PlayerState.SPECIAL && special_equipped == SpecialState.TSUNAMI);
var _tsunami_charging = _tsunami && !tsunami_charged;
var _tsunami_going    = _tsunami && tsunami_charged;

/* DO NOT UNCOMMENT - WILL BRICK
// the whirlwind special has two halves: charging (not full yet), then spinning (full)
var _whirlwind      = (state == PlayerState.SPECIAL && special_equipped == SpecialState.WHIRLWIND);
var _whirl_charging = _whirlwind && !special_charged;
var _whirl_spinning = _whirlwind && special_charged;
*/

// ---- 0. special charge circle on the ground (drawn BEFORE him, so it's underneath) ----
if (_tsunami_charging) {
    fxChargeCircleDraw(_special_charge, tsunami_charged);
}

// ---- 0b. Dance of Dragons: the orange-red trail, then the timing rings, aim line, swoosh and grade (all under him) ----
danceTrailDraw();
danceDraw();

// ---- 0c. Bladed Tsunami: the water droplets (they finish falling after it ends) ----
tsunamiDropsDraw();

// ---- 1. the player: blue and green up the sword all through the tsunami ----
if (_tsunami_going) {
    fxRainbowSwordDraw();
} else {
    draw_self();
}

// ---- 1b. special: glows while charging, the waves swirl round him during the tsunami ----
if (_tsunami_charging) {
    fxChargeGlowDraw(_special_charge);
}
if (_tsunami_going) {
    tsunamiRingDraw();
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

// ---- 7. Butterfly Effect: "x12" stored-hit counters on the enemies, and the butterflies in the air ----
butterfliesDraw();

// ---- 8. the Dance of Dragons' dragon companion (drawn last so it flies over him) ----
dragonDraw();

