// ============================================================
// WAVE MANAGER (the parent)
// ============================================================
// put ONE wave object in a room and it runs that room's waves.
// each room's wave object works on its own: it has its own list of
// waves, its own counter, and it remembers when its room is beaten.
//
// the ready-made wave objects (children of this one):
//   enemy_wave_orc_obj       orcs,      ends with the Orc boss
//   enemy_wave_skeleton_obj  skeletons, ends with the Skeleton boss
//   enemy_wave_cultist_obj   cultists,  ends with the Cultist boss
//
// TO MAKE A NEW ONE: make an object, set its parent to
// enemy_wave_manager_obj, give it a Create event, call event_inherited(),
// then set wave_name and wave_data (copy one of the children).
// the Step event and the spawning are all done here, in the parent.
//
// placing this parent object itself still works: it uses the waves below.
// ============================================================

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

// shown nowhere yet, but handy for a "Wave 2 - Orc Pit" title later
wave_name = "Waves";

// true  = once this room's waves are beaten, coming back to the room
//         doesn't start them again (the door stays open)
// false = the waves start over every time you enter the room
remember_when_beaten = true;

// the room's Step runs one check on its first frame (after the child has set its waves)
wave_first_step = true;

// the layer enemies are put on. if the room has no "Instances" layer,
// the layer this wave object is on is used instead.
wave_layer = "Instances";

// how far from the player an enemy is allowed to appear (pixels)
wave_spawn_min_dist = 250;

// ---------- the default waves (only used if this parent itself is placed) ----------
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

// remembers which rooms have been beaten. made once, kept for the whole game.
if (!variable_global_exists("waves_beaten"))
{
    global.waves_beaten = {};
}

//current wave available to UI code.
global.wave_current = 0;

// this room's waves haven't been beaten yet. the door to the interior room (interior_room_enter_obj)
// stays hidden and locked until Step sets this to true after the last wave.
// (if this room was beaten before and remember_when_beaten is true, Step sets it back to true on its first frame)
global.waves_complete = false;
    