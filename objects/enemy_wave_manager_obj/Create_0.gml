// ---------- BACK FROM THE INTERIOR (UPGRADE) ROOM: DON'T RESTART THE WAVES ----------
// leaving a room throws away everything in it, so coming back makes a brand new wave manager,
// which would start this room's waves all over again.
// global.prev_room is the room we just walked out of (every door sets it in its Room End).
// if that was the interior room, we've come back to a room whose waves are already beaten
// (its interior door only opens once global.waves_complete is true), so:
//   - say the waves are done, like they were when we left
//   - and get rid of this wave manager before it starts anything
// in any other room (like the next room through the gate) prev_room isn't the interior room,
// so the waves start as normal.
if (variable_global_exists("prev_room") && global.prev_room == interior_room) {
    global.waves_complete = true;
    instance_destroy();
    exit;   // skip setting up the waves below
}

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
    [[enemy_orc_grunt_obj, 1]],

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
        //one of each so you can see them all straight away
        [[enemy_lucifer_cultist_obj, 4],
         [enemy_lucifer_warrior_obj, 3],
         [enemy_lucifer_necromancer_obj,5],
         [enemy_lucifer_ancient_skeleton_obj,4],
         [enemy_lucifer_skeleton_king_obj, 3]],

        [[enemy_lucifer_cultist_obj, 3],
         [enemy_lucifer_warrior_obj, 2]],

        [[enemy_lucifer_warrior_obj, 2],
         [enemy_lucifer_necromancer_obj, 2],
         [enemy_lucifer_ancient_skeleton_obj, 1]],

        [[enemy_lucifer_skeleton_king_obj, 1],
         [enemy_lucifer_ancient_skeleton_obj, 1],
         [enemy_lucifer_cultist_obj, 2]]
    ];
}

// ============================================================
// BOSS WAVES
// ============================================================
// three boss waves are added after the normal waves: the orc boss, then the
// skeleton boss, then the cultist boss, each with a couple of their own group.
//   boss_waves_enabled = false  -> no boss waves
//   boss_waves_first   = true   -> fight the bosses FIRST (handy for testing)
boss_waves_enabled = true;
boss_waves_first   = false;

if (boss_waves_enabled)
{
    var _boss_waves = [
        [[enemy_boss_orc_obj, 1],
         [enemy_orc_grunt_obj, 2]],

        [[enemy_boss_skeleton_obj, 1],
         [enemy_skeleton_soldier_obj, 2]],

        [[enemy_boss_cultist_obj, 1],
         [enemy_lucifer_cultist_obj, 2]]
    ];

    var _all_waves = [];

    if (boss_waves_first)
    {
        for (var _i = 0; _i < array_length(_boss_waves); _i++) array_push(_all_waves, _boss_waves[_i]);
        for (var _i = 0; _i < array_length(wave_data); _i++)   array_push(_all_waves, wave_data[_i]);
    }
    else
    {
        for (var _i = 0; _i < array_length(wave_data); _i++)   array_push(_all_waves, wave_data[_i]);
        for (var _i = 0; _i < array_length(_boss_waves); _i++) array_push(_all_waves, _boss_waves[_i]);
    }

    wave_data = _all_waves;
}

//current wave available to UI code.
global.wave_current = 0;

// this room's waves haven't been beaten yet. the door to the interior room (interior_room_enter_obj)
// stays hidden and locked until Step sets this to true after the last wave.
// (coming back from the interior room never gets this far: the check at the top keeps the waves beaten)
global.waves_complete = false;