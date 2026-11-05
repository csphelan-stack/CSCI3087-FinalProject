//work on steps 9, 10, 11, 12, 13, 14
//create more sprites for skeleton characters (hurt,attack,dead)
//need map
//work on placement for enemies after waves
//adjust enemy stats
//maybe look into ranged attacks
//rescale enemie sprites
//create boss for each type of enemy or maybe ->
//=>just orc and skeleton and then game master
//change the cone of view for enemies? perception is too low
//finish hard coding the waves . . . up to 18 maybe (5 before boss wave)
// ---------- defaults (children override these after event_inherited) ----------
total_hp   = 10;
hp         = total_hp;
bf_hits    = 0;     // Butterfly Effect: hits stored on him during the window
bf_stored  = 0;     // and the damage they'd have done (it all lands when the window ends)
burn_timer      = 0;   // burning (the Dance of Dragons sets these): steps left on fire, 0 = not burning
burn_tick_time  = 30;  // steps between burn damage
burn_tick_timer = 0;
burn_damage     = 0;   // damage each tick (at least this much...)
burn_damage_max = 0;   // (...and at most this much, picked at random each tick)
dragon_hit_time = 0;   // the dragon companion can't bite him again until its clock reaches this
movespd    = 1.6;   // chase speed
wander_spd = 0.6;

//how big every enemy is drawn (1 = normal size). change this back to 1 to undo the scale-up
//(their collision box grows with it, attack ranges stay the same)
enemy_scale = 1;
image_xscale = enemy_scale;
image_yscale = enemy_scale;

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
attack_damage = global.enemy_stats.enemy_base.attack_damage;

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
slow_acc = 0;   // slow motion: collects a fraction of a step each frame (see Step, the Dance of Dragons)

target = noone;
last_x = x;  last_y = y;
home_x = x;  home_y = y;
wander_x = x; wander_y = y;

state       = ENEMY_STATE.IDLE;
state_prev  = state;
state_timer = irandom_range(idle_min, idle_max);

// new enemy healthbar fix
hp_initialized = false;


// ---------- magic ----------
// normal enemies fight with weapons. a magic user turns this on in its own
// Create event (after event_inherited) and uses the enemy_magic script.
magic_enabled  = false;                  // true = casts spells instead of fighting up close
magic_elements = [MAGIC_ELEMENT.FIRE];   // the kinds of magic it knows (picks one at random each cast)
magic_range    = 130;                    // how far away it can cast. never more than sight_range
magic_radius   = 36;                     // size of the area the spell hits (the circle's size)

// used while a spell is being cast
magic_element = MAGIC_ELEMENT.FIRE;      // the element of the spell being cast right now
magic_orb     = noone;                   // the orb on this enemy
magic_circle  = noone;                   // the magic circle on the ground

// ---------- boss ----------
// a boss turns boss_enabled on in enemy_boss_base_obj. normal enemies never use these.
boss_enabled    = false;
boss_flash      = 0;       // white flash when a boss takes a hit
boss_force_hurt = false;   // only true for the moment a parry staggers a boss
