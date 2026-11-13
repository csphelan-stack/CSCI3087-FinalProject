damage = global.player_attack.damage;

knockback = main_character_Obj.knockback;



life = 8;

image_alpha = 0.4;

owner = noone;

//was this swing a counter from a parry? (shows "Crit!" above the enemy)
is_crit = false;

//this list will track which enemies where hit
hit_list=[];

//Butterfly Effect: true = store the hit on the enemy instead of doing damage now (attackStatePlayer sets it)
bf_store = false;
