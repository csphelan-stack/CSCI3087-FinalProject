// having a Draw event turns off GameMaker's automatic drawing, so draw it ourselves.
// (it has no sprite, so draw_self doesn't actually draw anything at the moment)
draw_self();

// the player is within "radius" pixels of the door: show the prompt
if(collision_circle(x,y,radius,main_character_Obj,false,false)){
	draw_menu_text(x ,y,"Press D to re-enter the fight",c_white,1,fa_center);
}
