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


// MAGIC ATTACK CONFIGURATION
magic_enabled = true;
magic_element = "earth";
magic_color = make_color_rgb(120, 190, 85);
magic_range = sight_range;
magic_aoe_radius = 24;
magic_orb_duration = 10;
magic_effect_duration = 14;
attack_duration = 40;
attack_windup = 18;

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