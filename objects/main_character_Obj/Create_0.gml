//This is how you set up a state machine
//you enum x amounts of states 
// and then put the case switch statement of these states in the player objects step event
//then from there you can make scripts corresponding to the function name of the states in the step event. 
//check movement_MC_script for an example
//this makes writing code for a character much more efficient and also more sperated so it is easier to keep control of

//optional
enum PlayerState {
    NORMAL,
    ATTACK,
    DASH,
}


sprite_index = skull_knight_idle_forward_spr;
image_speed =1;
//how big he is drawn on screen (1 = normal size). change this back to 1 to undo the scale-up
char_scale = 2;
image_xscale = char_scale;
image_yscale = char_scale;

//these two var's are used in the tracking of the character's on screen position and direction
_hor = 0;
_ver =0;

//speed variables
kb_x = 0;
kb_y=0;

moving = false;

//how fast he goes
movespd = 3;
//whether or not he can move
can_move = true;
//start with no attack have some condition to show he can attack.
can_attack = false;


//variable that tracks which way the character is facing
//USE TO ASSIGN SPRITES IN CORRECT DIRECTIONS
facing = 270; // start facing down (toward the camera)

total_hp = 50;
hp = total_hp;

healthbar_width = 100;
healthbar_height = 12;

healthbar_x = display_get_gui_width() / 2;
healthbar_y = display_get_gui_height() - 82;
