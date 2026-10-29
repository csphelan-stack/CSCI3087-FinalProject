sprite_index = lucifer_ancient_skeleton_idle_forward_spr;

event_inherited();

// ancient skeleton: big slow brute with a greatsword (7 frame attack, the swing lands on frame 5)
hp = 80;
movespd = 1.8;
attack_damage = 10;
attack_range = 30;
stop_range = 20;
attack_cooldown_max = 90;

attack_anim_spd = 1.2;
// timed to the attack sprite (12 fps = 5 steps a frame): it hits on the frame the weapon/spell lands
attack_windup = 20;
attack_duration = 25;
knockback_power = 20;

// one steady collision box (the attack frames have big weapon swings and effects in them)
mask_index = lucifer_ancient_skeleton_idle_forward_spr;

spr_idle = [
    lucifer_ancient_skeleton_idle_right_spr,
    lucifer_ancient_skeleton_idle_backward_spr,
    lucifer_ancient_skeleton_idle_left_spr,
    lucifer_ancient_skeleton_idle_forward_spr
];

spr_run = [
    lucifer_ancient_skeleton_walk_right_spr,
    lucifer_ancient_skeleton_walk_backward_spr,
    lucifer_ancient_skeleton_walk_left_spr,
    lucifer_ancient_skeleton_walk_forward_spr
];

spr_attack = [
    lucifer_ancient_skeleton_attack_right_spr,
    lucifer_ancient_skeleton_attack_backward_spr,
    lucifer_ancient_skeleton_attack_left_spr,
    lucifer_ancient_skeleton_attack_forward_spr
];

spr_hurt = [
    lucifer_ancient_skeleton_hurt_right_spr,
    lucifer_ancient_skeleton_hurt_backward_spr,
    lucifer_ancient_skeleton_hurt_left_spr,
    lucifer_ancient_skeleton_hurt_forward_spr
];

spr_death = [
    lucifer_ancient_skeleton_death_right_spr,
    lucifer_ancient_skeleton_death_backward_spr,
    lucifer_ancient_skeleton_death_left_spr,
    lucifer_ancient_skeleton_death_forward_spr
];
