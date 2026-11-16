// having a Draw event turns off GameMaker's automatic drawing, so draw the door ourselves.
// (this doesn't run at all while the door is hidden, visible = false: see Step)
draw_self();

// the player is within "radius" pixels of the door: show the prompt above it
if(collision_circle(x,y,radius,main_character_Obj,false,false)){
	draw_menu_text(x ,y - 80,"Press D to travel to the upgrade hall",c_white,1,fa_center);
}
