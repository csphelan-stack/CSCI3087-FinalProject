sprite_index = lucifer_cultist_idle_forward_spr;

event_inherited();

// cultist: weak caster, slow spell (11 frame attack, the burst is frame 5)
hp = 10;
movespd = 1.5;
attack_damage = 3;
attack_range = 25;
stop_range = 14;
attack_cooldown_max = 50;
// timed to the attack sprite (12 fps = 5 steps a frame): it hits on the frame the weapon/spell lands
attack_windup = 25;
attack_duration = 55;
knockback_power = 4;

// one steady collision box (the attack frames have big weapon swings and effects in them)
mask_index = lucifer_cultist_idle_forward_spr;


// MAGIC ATTACK CONFIGURATION
magic_enabled = true;
magic_element = "fire";
magic_color = make_color_rgb(255, 75, 28);
magic_range = sight_range;
magic_aoe_radius = 26;
magic_orb_duration = 10;
magic_effect_duration = 14;
attack_duration = 40;
attack_windup = 18;

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
