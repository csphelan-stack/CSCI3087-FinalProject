/// @desc - Health orb + cooldown orbs + HUD

//variable takes off gui hud if inside
if(global.safeInside == false){

// Butterfly Effect: the glow and butterflies round the edges of the screen (drawn first, so the HUD sits on top)
butterflyScreenDraw();


// =====================================================
// HEALTH ORB (top left)
// =====================================================
var _x = 20;
var _y = 20;

var _pct = clamp(hp / total_hp, 0, 1);
var _w = sprite_get_width(orb_fill_spr);
var _h = sprite_get_height(orb_fill_spr);

// 1. empty background
draw_sprite_ext(orb_back_spr, 0, _x, _y, 1, 1, 0, c_white, 0.5);

/*
// not currently using face, could use new adventurer face
// 2. face
var _frame_off_x_face = 6;
var _frame_off_y_face = 8;
draw_sprite_ext(face_portrait_spr, 0, _x + _frame_off_x_face, _y + _frame_off_y_face, 1, 1, 0, c_white, 0.25);

*/

// 3. red fill, cropped from the bottom up
var _fill_h = _h * _pct;
if (_fill_h > 0) {
    draw_sprite_part_ext(
        orb_fill_spr, 0,
        0, _h - _fill_h,
        _w, _fill_h,
        _x, _y + (_h - _fill_h),
        1, 1, c_white, 0.5
    );
}

// 4. frame/glass on top
// 4. frame ring (semi-transparent) and glass highlight (brighter)
var _frame_off_x = -4;
var _frame_off_y = -4;
draw_sprite_ext(orb_frame_spr, 0, _x + _frame_off_x, _y + _frame_off_y, 1, 1, 0, c_white, 0.6);   // ring
draw_sprite_ext(orb_frame_glass_spr, 0, _x + _frame_off_x, _y + _frame_off_y, 1, 1, 0, c_white, 1.0);   // highlight

// =====================================================
// COOLDOWN ORBS (bottom left)
// =====================================================

// track each cooldown's starting value so the sweep is accurate
if (dash_cooldown    > dash_cd_prev)    dash_cd_max    = dash_cooldown;
if (parry_cooldown   > parry_cd_prev)   parry_cd_max   = parry_cooldown;
if (special_cooldown > special_cd_prev) special_cd_max = special_cooldown;
dash_cd_prev    = dash_cooldown;
parry_cd_prev   = parry_cooldown;
special_cd_prev = special_cooldown;

// layout
var _r_small = 18;
var _r_big   = 28;
var _pad     = 20;
var _spacing = 10;

var _cy_small = display_get_gui_height() - _pad - _r_small;
var _cy_big   = display_get_gui_height() - _pad - _r_big;

var _x_special = _pad + _r_big;
var _x_dash    = _x_special + _r_big + _spacing + _r_small;
var _x_parry   = _x_dash + _r_small * 2 + _spacing;

// draw the three orbs onto one surface, then fade the surface as a whole
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();

if (!surface_exists(orb_surf)) orb_surf = surface_create(_gw, _gh);

surface_set_target(orb_surf);
    draw_clear_alpha(c_black, 0);
    gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_one, bm_inv_src_alpha);

    //                  x            y          radius    remaining         total            icon              offx offy frame
    draw_cooldown_orb(_x_special, _cy_big,   _r_big,   special_cooldown, special_cd_max, skull_knight_attack_forward_icon_spr, 0, 0, 0);
    draw_cooldown_orb(_x_dash,    _cy_small, _r_small, dash_cooldown,    dash_cd_max,    dash_icon_spr,    2, 2, 0);
    draw_cooldown_orb(_x_parry,   _cy_small, _r_small, parry_cooldown,   parry_cd_max,   parry_icon_spr,   1, 0, 0);

    gpu_set_blendmode(bm_normal);
surface_reset_target();

draw_surface_ext(orb_surf, 0, 0, 1, 1, 0, c_white, 0.6);   // 0.6 = overall opacity of the cluster

// damage numbers / "Crit!" above enemies (hidden behind the pause menu)
if (!global.gameIsPaused) {
    damagePopupsDraw();
    specialHudDraw();   // "Special ready" / cooldown seconds above the health bar
    butterflyPhaseHudDraw();   // Butterfly Effect: the rewind's tint, and how many butterflies are left to send
}






}
