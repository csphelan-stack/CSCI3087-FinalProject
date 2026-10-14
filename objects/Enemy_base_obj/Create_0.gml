//work on steps 9, 10, 11, 12, 13, 14
//create more sprites for skeleton characters (hurt,attack,dead)
//need map
//work on placement for enemies after waves
//adjust enemy stats
//maybe look into ranged attacks
//rescale enemie sprites
//create boss for each type of enemy or maybe ->
//=>just orc and skeleton and then game master
// ---------- defaults (children override these after event_inherited) ----------
hp         = 10;
movespd    = 1.6;   // chase speed
wander_spd = 0.6;

//animation and such 
run_anim_spd   = 1.2;
idle_anim_spd  = 0.5;
death_anim_spd = 1.2;
hurt_anim_spd = 1.0;
attack_anim_spd = 1.0;

//vision
sight_range = 150;  // spotting distance
view_angle  = 120;  // vision cone width (360 = sees all around)
lose_range  = 220;  // keeps chasing out to this range
attack_range = 22;
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
spr_attack = [-1, -1, -1, -1];
spr_death = [-1, -1, -1, -1];
spr_hurt = [-1, -1, -1, -1];

// ============================================================
// ATTACK SETTINGS and knockbakc i guess
// ============================================================

// set the damage this enemy deals
attack_damage = 3;

// set how long the entire attack state lasts
attack_duration = 30

// set how many frames pass before the attack actually hits
attack_windup = 12;

// set how many frames must pass before the enemy can attack again
attack_cooldown_max = 45;

// store current cooldown
attack_cooldown = 0;

// track whether current attack already dealt damage
attack_hit_done = false;

knockback_power = 4;// when he gets hit btw


// ============================================================
// WANDER / STATE TIMERS
// ============================================================

// set the maximum distance from home that the enemy can wander
wander_radius = 64;

// set how long a wander attempt may last
wander_give_up = 180;

// set minimum idle duration
idle_min = 40;

// set maximum idle duration
idle_max = 120;

// set search duration to approximately three seconds
search_time = game_get_speed(gamespeed_fps) * 3;

// set hurt-state duration
hurt_time = 12;

// set knockback friction
kb_friction = 0.8;

// ---------- runtime ----------
facing   = 270;
kb_x = 0;
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

