sprite_index = lucifer_skeleton_king_idle_forward_spr;

event_inherited();

// skeleton king: boss (10 frame attack, the swing is frame 3)
hp = global.enemy_stats.lucifer_skeleton_king.hp;
movespd = 1.3;
attack_damage = global.enemy_stats.lucifer_skeleton_king.attack_damage;
attack_range = 30;
stop_range = 16;
attack_cooldown_max = 60;
// timed to the attack sprite (12 fps = 5 steps a frame): it hits on the frame the weapon/spell lands
attack_windup = 15;
attack_duration = 50;
knockback_power = 2;

// one steady collision box (the attack frames have big weapon swings and effects in them)
mask_index = lucifer_skeleton_king_idle_forward_spr;

spr_idle = [
    lucifer_skeleton_king_idle_right_spr,
    lucifer_skeleton_king_idle_backward_spr,
    lucifer_skeleton_king_idle_left_spr,
    lucifer_skeleton_king_idle_forward_spr
];

spr_run = [
    lucifer_skeleton_king_walk_right_spr,
    lucifer_skeleton_king_walk_backward_spr,
    lucifer_skeleton_king_walk_left_spr,
    lucifer_skeleton_king_walk_forward_spr
];

spr_attack = [
    lucifer_skeleton_king_attack_right_spr,
    lucifer_skeleton_king_attack_backward_spr,
    lucifer_skeleton_king_attack_left_spr,
    lucifer_skeleton_king_attack_forward_spr
];

spr_hurt = [
    lucifer_skeleton_king_hurt_right_spr,
    lucifer_skeleton_king_hurt_backward_spr,
    lucifer_skeleton_king_hurt_left_spr,
    lucifer_skeleton_king_hurt_forward_spr
];

spr_death = [
    lucifer_skeleton_king_death_right_spr,
    lucifer_skeleton_king_death_backward_spr,
    lucifer_skeleton_king_death_left_spr,
    lucifer_skeleton_king_death_forward_spr
];

