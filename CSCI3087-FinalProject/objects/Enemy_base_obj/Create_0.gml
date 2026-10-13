
// ---------- defaults (children override these after event_inherited) ----------
hp         = 10;
movespd    = 1.6;   // chase speed
wander_spd = 0.6;

run_anim_spd   = 1.2;
idle_anim_spd  = 0.5;
death_anim_spd = 1.2;

sight_range = 150;  // spotting distance
view_angle  = 120;  // vision cone width (360 = sees all around)
lose_range  = 220;  // keeps chasing out to this range
stop_range  = 14;   // stops this close to the player

wander_radius  = 64;
wander_give_up = 180;                               // frames before giving up on a wander point
idle_min = 40;
idle_max = 120;
search_time = game_get_speed(gamespeed_fps) * 3;   // how long he searches before giving up
hurt_time   = 12;
kb_friction = 0.8;

// sprites in dir4 order: [right, backward, left, forward] (children fill these in)
spr_idle  = [-1, -1, -1, -1];
spr_run   = [-1, -1, -1, -1];
spr_death = [-1, -1, -1, -1];

// ---------- runtime ----------
facing   = 270;
kb_x     = 0;
kb_y     = 0;
move_spd = 0;
move_dir = 0;

target = noone;
last_x = x;  last_y = y;
home_x = x;  home_y = y;
wander_x = x; wander_y = y;

state       = ENEMY_STATE.IDLE;
state_prev  = state;
state_timer = irandom_range(idle_min, idle_max);
