sprite_index = lucifer_necromancer_idle_forward_spr;

event_inherited();

// necromancer: dark ring spell (7 frame attack, the ring is frame 4)
hp = global.enemy_stats.lucifer_necromancer.hp;
movespd = 1.4;
attack_damage = global.enemy_stats.lucifer_necromancer.attack_damage;
attack_range = 28;
stop_range = 16;
attack_cooldown_max = 55;
// timed to the attack sprite (12 fps = 5 steps a frame): it hits on the frame the weapon/spell lands
attack_windup = 20;
attack_duration = 35;
knockback_power = 4;

// one steady collision box (the attack frames have big weapon swings and effects in them)
mask_index = lucifer_necromancer_idle_forward_spr;

spr_idle = [
    lucifer_necromancer_idle_right_spr,
    lucifer_necromancer_idle_backward_spr,
    lucifer_necromancer_idle_left_spr,
    lucifer_necromancer_idle_forward_spr
];

spr_run = [
    lucifer_necromancer_run_right_spr,
    lucifer_necromancer_run_backward_spr,
    lucifer_necromancer_run_left_spr,
    lucifer_necromancer_run_forward_spr
];

spr_attack = [
    lucifer_necromancer_attack_right_spr,
    lucifer_necromancer_attack_backward_spr,
    lucifer_necromancer_attack_left_spr,
    lucifer_necromancer_attack_forward_spr
];

spr_hurt = [
    lucifer_necromancer_hurt_right_spr,
    lucifer_necromancer_hurt_backward_spr,
    lucifer_necromancer_hurt_left_spr,
    lucifer_necromancer_hurt_forward_spr
];

spr_death = [
    lucifer_necromancer_death_right_spr,
    lucifer_necromancer_death_backward_spr,
    lucifer_necromancer_death_left_spr,
    lucifer_necromancer_death_forward_spr
];

// ---------- magic (see the enemy_magic script) ----------
// this enemy casts dark magic instead of swinging a weapon.
magic_enabled  = true;
magic_elements = [MAGIC_ELEMENT.DARK];
magic_range    = 140;     // never more than sight_range

// the cast: the orb and circle charge for attack_windup frames, then the spell goes off.
attack_windup       = 50;
attack_duration     = 75;     // the whole cast (must be longer than the windup)
attack_cooldown_max = 110;    // pause between casts
attack_anim_spd     = 0.5;    // slower attack animation so it lasts the whole cast
