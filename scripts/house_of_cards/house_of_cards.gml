
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
		
		// 3. Process the found instances
		if (_num > 0) {
		    for (var i = 0; i < min(_num,number_of_enemies_effected); ++i) {
		        var _inst_id = _list[| i]; // Get instance ID from DS list
				if(instance_exists(_inst_id)){
					
					if(array_contains(_object.targets,_inst_id)){
						
					}
					else{
					_object.targets[i] = _inst_id;
					_object.number_of_targets_HOC = min(_num,number_of_enemies_effected);
					}
				}
				
		    }
		}
		
	
		
		// 4. Clean up the DS list immediately after use
		ds_list_destroy(_list);
		kill_counter_current=0;
	}

}
