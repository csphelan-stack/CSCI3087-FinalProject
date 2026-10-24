current_wave = 0;

wave_queue = [];

spawned_this_wave = 0;

//store instance IDs of enemies spawned for the current wave
wave_enemy_ids = [];

//wait two seconds before starting a wave
wave_delay = game_get_speed(gamespeed_fps) * 2;

//initial countdown
wave_timer = wave_delay;

//indicate that no wave is currently active
wave_active = false;

wave_data = [
    [[enemy_orc_grunt_obj, 20]],

    [[enemy_orc_grunt_obj, 1], 
     [enemy_orc_beserker_obj, 1]],

    [[enemy_orc_grunt_obj, 1], 
     [enemy_orc_beserker_obj, 1], 
     [enemy_skeleton_soldier_obj, 1]],

    [[enemy_orc_grunt_obj, 1], 
     [enemy_orc_beserker_obj, 1], 
     [enemy_orc_warlord_obj, 1], 
     [enemy_skeleton_soldier_obj, 1]]
];

//true = the waves use the new Lucifer enemies, false = the original orc/skeleton waves above
//(flip to false to change them back)
use_lucifer_enemies = true;

if (use_lucifer_enemies){
    wave_data = [
        [[enemy_lucifer_cultist_obj, 1],
         [enemy_lucifer_warrior_obj, 1],
         [enemy_lucifer_necromancer_obj, 1],
         [enemy_lucifer_ancient_skeleton_obj, 1],
         [enemy_lucifer_skeleton_king_obj, 1]],

        [[enemy_lucifer_cultist_obj, 100],
         [enemy_lucifer_warrior_obj, 2]],

        [[enemy_lucifer_warrior_obj, 2],
         [enemy_lucifer_necromancer_obj, 2],
         [enemy_lucifer_ancient_skeleton_obj, 1]],

        [[enemy_lucifer_skeleton_king_obj, 1],
         [enemy_lucifer_ancient_skeleton_obj, 1],
         [enemy_lucifer_cultist_obj, 2]]
    ];
}

//current wave available to UI code.
global.wave_current = 0;

global.waves_complete = false;