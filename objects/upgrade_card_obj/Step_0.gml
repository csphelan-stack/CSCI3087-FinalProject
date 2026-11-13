
if (!instance_exists(Upgrade_system_obj)) exit;

//only the "choose" part of the event lets you hover and click cards
if (Upgrade_system_obj.phase != "choose") {
	hovered = false;
	exit;
}

var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);

hovered = point_in_rectangle(_mx,_my,card_x,card_y,card_x+card_w,card_y+card_h);

if(hovered){
revealed = true;	
}

if(revealed && flip <1){
	flip = min(1,flip+flip_spd);
}

//Make a confirm upgrade yes or no
//it should make the card even bigger and fade out the background then once it is done
//it should burn the card picked and end the event.
//click a face-up card to pick it (the dealer, Upgrade_system_obj, runs the confirm + burn)
if (hovered && flip >= 1 && mouse_check_button_pressed(mb_left)) {
	Upgrade_system_obj.chosen = id;
	Upgrade_system_obj.phase  = "confirm";
	depth = Upgrade_system_obj.depth - 2;   //draw over the other cards while it's big
}
