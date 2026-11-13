sprite_index = skeleton_cultist_idle_forward_spr;

event_inherited();

total_hp = 12;
hp = total_hp;

movespd = 1.5;
attack_damage = 3;
attack_range = 25;
attack_cooldown_max = 45;
attack_windup = 12;
attack_duration = 30;
knockback_power = 4;

spr_idle = [
    skeleton_cultist_idle_right_spr,
    skeleton_cultist_idle_backward_spr,
    skeleton_cultist_idle_left_spr,
    skeleton_cultist_idle_forward_spr
];

spr_run = [
    skeleton_cultist_walk_right_spr,
    skeleton_cultist_walk_backward_spr,
    skeleton_cultist_walk_left_spr,
    skeleton_cultist_walk_forward_spr
];

spr_attack = [
    skeleton_cultist_idle_right_spr,
    skeleton_cultist_idle_backward_spr,
    skeleton_cultist_idle_left_spr,
    skeleton_cultist_idle_forward_spr
];

spr_hurt = [
    skeleton_cultist_idle_right_spr,
    skeleton_cultist_idle_backward_spr,
    skeleton_cultist_idle_left_spr,
    skeleton_cultist_idle_forward_spr
];

spr_death = [
    skeleton_cultist_idle_right_spr,
    skeleton_cultist_idle_backward_spr,
    skeleton_cultist_idle_left_spr,
    skeleton_cultist_idle_forward_spr
];

// ---------- magic (see the enemy_magic script) ----------
// this enemy casts fire magic instead of swinging a weapon.
magic_enabled  = true;
magic_elements = [MAGIC_ELEMENT.FIRE];
magic_range    = 120;     // never more than sight_range

// the cast: the orb and circle charge for attack_windup frames, then the spell goes off.
attack_windup       = 45;
attack_duration     = 70;     // the whole cast (must be longer than the windup)
attack_cooldown_max = 100;    // pause between casts
attack_anim_spd     = 0.5;    // slower attack animation so it lasts the whole cast


