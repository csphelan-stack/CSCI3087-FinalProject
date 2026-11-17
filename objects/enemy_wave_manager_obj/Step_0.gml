if (global.gameIsPaused){
    exit;
}

// ---------- first frame in the room ----------
// (done here and not in Create, so the child has already set its waves)
if (wave_first_step)
{
    wave_first_step = false;

    // this room was beaten before: skip straight to "done"
    if (remember_when_beaten && variable_struct_exists(global.waves_beaten, room_get_name(room)))
    {
        current_wave = array_length(wave_data);
        global.wave_current = current_wave;
        global.waves_complete = true;
        exit;
    }
}

if (!wave_active && current_wave < array_length(wave_data)){

    //defined earlier as wave delay
    wave_timer--;

    if (wave_timer <= 0){
        current_wave++;

        //update wave number for the UI
        global.wave_current = current_wave;

        wave_active = true;

        //reset number spawned
        spawned_this_wave = 0;

        //clear previous wave's queue
        wave_queue = [];

        //same for ids
        wave_enemy_ids = [];

        //retrieve this wave's enemy definitions
        var _wave = wave_data[current_wave - 1];

        //process each enemy group
        for (var i = 0; i < array_length(_wave); i++){
            //retrieve the current group
            var _group = _wave[i];

            //get the enemy object
            var _enemy_obj = _group[0];

            //get required quantity
            var _count = _group[1];

            //add the required enemies to queue
            for (var j = 0; j < _count; j++){
                array_push(wave_queue, _enemy_obj);
            }
        }
    }
}

//spawn next enemy if the wave still has enemies queued
if (wave_active && spawned_this_wave < array_length(wave_queue)) {
    enemy_wave_spawn_next();
}

//check if every queued enemy has spawned
var _spawn_complete =
    spawned_this_wave >= array_length(wave_queue);

//count enemies that still exist
var _alive_count = 0;

//examine every instance ID stored
for (var i = 0; i < array_length(wave_enemy_ids); i++) {
    //count the enemy IF it has not been destroyed
    if (instance_exists(wave_enemy_ids[i])){
        _alive_count++;
    }
}

if (wave_active && _spawn_complete && _alive_count == 0) {

    wave_active = false;

    // do additional waves remain?
    if (current_wave < array_length(wave_data)){
        //set the delay before the next wave
        wave_timer = wave_delay;
    } else {
        //all waves completed?
        // this makes the door to the interior room (interior_room_enter_obj) appear and open on D
        global.waves_complete = true;

        // remember that this room is beaten
        global.waves_beaten[$ room_get_name(room)] = true;
    }
}
