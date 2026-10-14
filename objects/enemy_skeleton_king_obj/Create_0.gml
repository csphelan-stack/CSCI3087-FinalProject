sprite_index = skeleton_king_idle_forward_spr;

event_inherited();

hp = 12;
movespd = 1.5;
attack_damage = 3;
attack_range = 25;
attack_cooldown_max = 45;
attack_windup = 12;
attack_duration = 30;
knockback_power = 4;

spr_idle = [
    skeleton_king_idle_right_spr,
    skeleton_king_idle_backward_spr,
    skeleton_king_idle_left_spr,
    skeleton_king_idle_forward_spr
];

spr_run = [
    skeleton_king_walk_right_spr,
    skeleton_king_walk_backward_spr,
    skeleton_king_walk_left_spr,
    skeleton_king_walk_forward_spr
];

spr_attack = [
    skeleton_king_idle_right_spr,
    skeleton_king_idle_backward_spr,
    skeleton_king_idle_left_spr,
    skeleton_king_idle_forward_spr
];

spr_hurt = [
    skeleton_king_idle_right_spr,
    skeleton_king_idle_backward_spr,
    skeleton_king_idle_left_spr,
    skeleton_king_idle_forward_spr
];

spr_death = [
    skeleton_king_idle_right_spr,
    skeleton_king_idle_backward_spr,
    skeleton_king_idle_left_spr,
    skeleton_king_idle_forward_spr
];