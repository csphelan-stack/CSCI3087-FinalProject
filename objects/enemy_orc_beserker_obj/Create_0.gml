sprite_index = orc_berserker_idle_forward_spr; // before event_inherited: this fixes the sprite_get_height crash
event_inherited();

hp      = 10;
movespd = 1.6;

// order: right, backward, left, forward
spr_idle  = [orc_berserker_idle_right_spr,  orc_berserker_idle_backward_spr,  orc_berserker_idle_left_spr,  orc_berserker_idle_forward_spr];
spr_run   = [orc_berserker_run_right_spr,   orc_berserker_run_backward_spr,   orc_berserker_run_left_spr,   orc_berserker_run_forward_spr];
spr_death = [orc_berserker_death_right_spr, orc_berserker_death_backward_spr, orc_berserker_death_left_spr, orc_berserker_death_forward_spr];