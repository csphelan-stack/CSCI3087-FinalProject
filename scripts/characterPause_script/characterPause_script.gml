// characterPause_script: characterPause_script() stops the player attacking and moving;
// characterUnPause_script() lets them again. Run on main_character_Obj; no arguments.
function characterPause_script(){

can_attack = false;
can_move=false;



}
function characterUnPause_script(){

can_attack = true;
can_move= true;



}


// inside: walks slower (inside_movespd, set in the player's Create), can't attack, dash, parry or special,
// and global.safeInside hides his HUD (Draw GUI) and swaps the run for the walk animation (applyMovement)
function characterInside_script(){

with(main_character_Obj){
can_attack = false;
can_dash = false;
can_parry = false;
can_special = false;
movespd = inside_movespd;

}

global.safeInside = true;


}
function characterOutside_script(){
	
with(main_character_Obj){
can_attack = true;
can_dash = true;
can_parry = true;
can_special = true;
movespd = fixedmovespd;

}

global.safeInside = false;
}