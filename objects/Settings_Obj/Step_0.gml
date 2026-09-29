//to add onto this we need a variable to indicate when we can pause the game
// and when we cant if we dont want the user to be able to pause whenever they want.

if(keyboard_check_pressed(global.pauseGameBtn)){
	global.gameIsPaused= !global.gameIsPaused;	
}

if(global.gameIsPaused){
	
	window_set_cursor(gui_cursor_spr);
	
	  
	  if (!surface_exists(pause_surface)) { pause_surface = surface_create(room_width, room_height); }
	// Draw the room to the surface 
	surface_set_target(pause_surface); 
	draw_clear_alpha(c_aqua, 0); 
	draw_self(); // or draw the room manually if needed 
	surface_reset_target();
	  
	   
	
	
	
}
else{
	global.gameIsPaused = false;

if (surface_exists(pause_surface)) {
    surface_free(pause_surface);
}
pause_surface = -1;
}