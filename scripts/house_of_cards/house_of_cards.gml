// house_of_cards: the House of Cards ability. Once the player's kill streak (kill_counter_current)
// reaches kill_number_HOC and cooldown_HOC is 0, it finds up to 7 enemies within 300 pixels,
// creates a house_of_cards_obj that targets them, and resets the kill streak.
// Called every step from main_character_Obj Step while house_of_cards_unlock is true
// (runs as the player); takes nothing in.
function house_of_cards(){

var number_of_enemies_effected =7;



	if(kill_counter_current >= kill_number_HOC && cooldown_HOC<=0){

		// 1. Create a data structure to store the results (do this in the Create Event to avoid memory leaks)
		var _list = ds_list_create();

		var _radius = 300;
		var _target_object = Enemy_base_obj;

		// 2. Check the circle and store matching instance IDs in _list
		var _num = collision_circle_list(x, y, _radius, _target_object, false, true, _list, false);

		var _object = instance_create_depth(x,y,-100,house_of_cards_obj);

		// 3. Pick the targets: up to 7 enemies that are still ALIVE.
		// An enemy in ENEMY_STATE.DEAD is only playing its death animation and is about to be destroyed,
		// which would take its strike with it. Skip those and keep looking: loop over EVERY enemy found,
		// not just the first 7, so dying enemies don't use up the slots.
		for (var i = 0; i < _num; ++i) {
			var _inst_id = _list[| i];
			if (instance_exists(_inst_id) && _inst_id.state != ENEMY_STATE.DEAD) {
				array_push(_object.targets, _inst_id);   // adds to the end, so the list never has gaps
				if (array_length(_object.targets) >= number_of_enemies_effected) break;   // got 7, stop looking
			}
		}
		// how many we actually got (could be fewer than 7, or 0)
		_object.number_of_targets_HOC = array_length(_object.targets);
					
		

		    
		



		// 4. Clean up the DS list immediately after use
		ds_list_destroy(_list);
		kill_counter_current=0;
	}

}
