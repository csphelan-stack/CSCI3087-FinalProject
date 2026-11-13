sprite_index = lucifer_warrior_idle_forward_spr;

event_inherited();

// warrior: quick sword swing (6 frame attack, hits on frame 2)
hp = 14;
movespd = 1.7;
attack_damage = 4;
attack_range = 24;
stop_range = 14;
attack_cooldown_max = 45;
// timed to the attack sprite (12 fps = 5 steps a frame): it hits on the frame the weapon/spell lands
attack_windup = 12;
attack_duration = 30;
knockback_power = 4;

// one steady collision box (the attack frames have big weapon swings and effects in them)
mask_index = lucifer_warrior_idle_forward_spr;

spr_idle = [
    lucifer_warrior_idle_right_spr,
    lucifer_warrior_idle_backward_spr,
    lucifer_warrior_idle_left_spr,
    lucifer_warrior_idle_forward_spr
];

spr_run = [
    lucifer_warrior_walk_right_spr,
    lucifer_warrior_walk_backward_spr,
    lucifer_warrior_walk_left_spr,
    lucifer_warrior_walk_forward_spr
];

spr_attack = [
    lucifer_warrior_attack_right_spr,
    lucifer_warrior_attack_backward_spr,
    lucifer_warrior_attack_left_spr,
    lucifer_warrior_attack_forward_spr
];

spr_hurt = [
    lucifer_warrior_hurt_right_spr,
    lucifer_warrior_hurt_backward_spr,
    lucifer_warrior_hurt_left_spr,
    lucifer_warrior_hurt_forward_spr
];

spr_death = [
    lucifer_warrior_death_right_spr,
    lucifer_warrior_death_backward_spr,
    lucifer_warrior_death_left_spr,
    lucifer_warrior_death_forward_spr
];


