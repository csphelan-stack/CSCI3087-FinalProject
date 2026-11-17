// having a Draw event turns off GameMaker's automatic drawing, so draw the door ourselves
draw_self();

// the player is within "radius" pixels of the door: show the prompt above it
// (collision_circle checks for main_character_Obj inside a circle round the door's x,y)
if(collision_circle(x,y,radius,main_character_Obj,false,false)){
	draw_menu_text(x ,y - 80,"Press D to open the door",c_white,1,fa_center);
}
