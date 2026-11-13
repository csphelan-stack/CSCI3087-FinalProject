sprite_index = orc_grunt_idle_forward_spr;

event_inherited();

//need to change attributes
total_hp = 8;
hp = total_hp; 

movespd = 1.8;
attack_damage = 3;
attack_range = 22;
attack_cooldown_max = 50;
attack_windup = 12;
attack_duration = 30;
knockback_power = 4;

spr_idle = [
    orc_grunt_idle_right_spr,
    orc_grunt_idle_backward_spr,
    orc_grunt_idle_left_spr,
    orc_grunt_idle_forward_spr
];

spr_run = [
    orc_grunt_run_right_spr,
    orc_grunt_run_backward_spr,
    orc_grunt_run_left_spr,
    orc_grunt_run_forward_spr
];

spr_attack = [
    orc_grunt_attack_right_spr,
    orc_grunt_attack_backward_spr,
    orc_grunt_attack_left_spr,
    orc_grunt_attack_forward_spr
];

spr_hurt = [
    orc_grunt_hurt_right_spr,
    orc_grunt_hurt_backward_spr,
    orc_grunt_hurt_left_spr,
    orc_grunt_hurt_forward_spr
];

spr_death = [
    orc_grunt_death_right_spr,
    orc_grunt_death_backward_spr,
    orc_grunt_death_left_spr,
    orc_grunt_death_forward_spr
];



