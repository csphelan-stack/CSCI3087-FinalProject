
	
	    draw_timer--; // Count down visibility frame-by-frame


	//draw_sprite_pos(lightning_strike_HOC_sprite,1,);
	
	strike_frame += 0.1;	
	
for(var i =0; i<=number_of_targets_HOC-1;i++){
		if(instance_exists(targets[i]) && strike_frame <= number_of_targets_HOC){
		draw_sprite(lightning_strike_HOC_sprite,floor(strike_frame) mod number_of_targets_HOC,targets[i].x,targets[i].y);
		}
}
