sprite_index = lucifer_cultist_idle_forward_spr;

event_inherited();

// cultist: weak caster, slow spell (11 frame attack, the burst is frame 5)
hp = global.enemy_stats.lucifer_cultist.hp;
movespd = 1.5;
attack_damage = global.enemy_stats.lucifer_cultist.attack_damage;
attack_range = 25;
stop_range = 14;
attack_cooldown_max = 50;
// timed to the attack sprite (12 fps = 5 steps a frame): it hits on the frame the weapon/spell lands
attack_windup = 25;
attack_duration = 55;
knockback_power = 4;

// one steady collision box (the attack frames have big weapon swings and effects in them)
mask_index = lucifer_cultist_idle_forward_spr;

spr_idle = [
    lucifer_cultist_idle_right_spr,
    lucifer_cultist_idle_backward_spr,
    lucifer_cultist_idle_left_spr,
    lucifer_cultist_idle_forward_spr
];

spr_run = [
    lucifer_cultist_walk_right_spr,
    lucifer_cultist_walk_backward_spr,
    lucifer_cultist_walk_left_spr,
    lucifer_cultist_walk_forward_spr
];

spr_attack = [
    lucifer_cultist_attack_right_spr,
    lucifer_cultist_attack_backward_spr,
    lucifer_cultist_attack_left_spr,
    lucifer_cultist_attack_forward_spr
];

spr_hurt = [
    lucifer_cultist_hurt_right_spr,
    lucifer_cultist_hurt_backward_spr,
    lucifer_cultist_hurt_left_spr,
    lucifer_cultist_hurt_forward_spr
];

spr_death = [
    lucifer_cultist_death_right_spr,
    lucifer_cultist_death_backward_spr,
    lucifer_cultist_death_left_spr,
    lucifer_cultist_death_forward_spr
];

// ---------- magic (see the enemy_magic script) ----------
// this enemy casts lightning and light magic instead of swinging a weapon.
magic_enabled  = true;
magic_elements = [MAGIC_ELEMENT.LIGHTNING, MAGIC_ELEMENT.LIGHT];
magic_range    = 130;     // never more than sight_range

// the cast: the orb and circle charge for attack_windup frames, then the spell goes off.
attack_windup       = 45;
attack_duration     = 70;     // the whole cast (must be longer than the windup)
attack_cooldown_max = 100;    // pause between casts
attack_anim_spd     = 0.5;    // slower attack animation so it lasts the whole cast

