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
    PARRY,
}

//which state the player is currently in (see PlayerState enum above)
state = PlayerState.NORMAL;


sprite_index = skull_knight_idle_forward_spr;
image_speed =1;
//how big he is drawn on screen (1 = normal size). change this back to 1 to undo the scale-up
char_scale = 2;
image_xscale = char_scale;
image_yscale = char_scale;


//player hitbox
mask_index = skull_knight_mask_spr;

//these two var's are used in the tracking of the character's on screen position and direction
_hor = 0;
_ver =0;

//speed variables
kb_x = 0;
kb_y=0;

moving = false;

//how fast he goes
fixedmovespd =3;
movespd = fixedmovespd;
//whether or not he can move
can_move = true;
//start with no attack have some condition to show he can attack.
can_attack = true;


//variable that tracks which way the character is facing
//USE TO ASSIGN SPRITES IN CORRECT DIRECTIONS
facing = 270; // start facing down (toward the camera)

total_hp = 50;
hp = total_hp;

//healthbar
healthbar_width = 100;
healthbar_height = 12;

healthbar_x = display_get_gui_width() / 2;
healthbar_y = display_get_gui_height() - 82;
//

attackBtn = ord("Z");
dashBtn = vk_space;
consumeBtn = ord("A");





//---attack settings---
attack_hit_frame = 1;        //which frame of the swing makes the hitbox (0 = first frame)
//the farthest point the sword's swoosh reaches in each direction, measured from his feet
//(measured off the slash frame of each attack sprite at char_scale 2)
//the hitbox's far edge gets lined up with this point
//order matches dir4:   [right,  up,  left,  down]
attack_peak_x =         [  64,   -4,   -64,   -2 ];
attack_peak_y =         [ -12,  -52,   -12,   34 ];
attack_hit_spawned = false;  //has this swing already made its hitbox?



attack_cooldown_time = 30; //60 = 1 sec wait
attack_cooldown = 0;

//cooldown
dash_cooldown_t = 60;
dash_cooldown = 0;





//parry cooldown (only activate cooldown if a parry is used up)
parry_cooldown_t = 60*2;
parry_cooldown = 0;

dash_length = 120;  //total pixels one dash travels

dash_timer = 0;
dash_time = 5;

dash_dir = 0;

