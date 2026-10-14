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
parryBtn = ord("X");





//---attack settings---
attack_hit_frame = 1;        //which frame of the swing makes the hitbox (0 = first frame)
//the farthest point the sword's swoosh reaches in each direction, measured from his feet
//(measured off the slash frame of each attack sprite at char_scale 2)
//the hitbox's far edge gets lined up with this point
//order matches dir4:   [right,  up,  left,  down]
attack_peak_x =         [  64,   -4,   -64,   -2 ];
attack_peak_y =         [ -12,  -52,   -12,   34 ];
attack_hit_spawned = false;  //has this swing already made its hitbox?

//tracks opp of swing
opp_swing_dir = 0;
//knockback variables
player_kbx = 30;
player_kby = 30;

attack_cooldown_time = 10; //60 = 1 sec wait
attack_cooldown = 0;

//cooldown
dash_cooldown_t = 60;
dash_cooldown = 0;

// -----damage taking variables
invuln_time = 30; // steps until he can be hit again
invuln = 0;





//if parry is successful
parry_success = false;
parry_was_hit = false;



//parry cooldown (only activate cooldown if a parry exhuast is used up)
parry_cooldown_t = 60*3;
parry_cooldown = 0;

//timer that decides how long we can parry for.
parry_exhuast_timer = 60*3;
parry_exhuast = 0;

dash_length = 120;  //total pixels one dash travels

dash_timer = 0;
dash_time = 5;

dash_dir = 0;

//---dash afterimages---
dash_ghost_count       = 6;     //how many shadows each dash leaves
dash_ghost_alpha_first = 0.7;   //opacity of the first shadow
dash_ghost_alpha_last  = 0.3;   //opacity of the last shadow (the ones between are spread evenly)
dash_ghost_colour      = [c_orange, c_fuchsia, c_aqua, c_yellow, c_maroon,c_lime,c_purple]; //colours in order (repeats if there are more shadows than colours)
dash_ghost_hold        = 2;     //steps before the FIRST shadow starts fading
dash_ghost_stagger     = 3;     //steps between each shadow starting to fade
dash_ghost_fade        = 16;    //steps each shadow takes to fade out
dash_ghosts_made       = 0;     //how many shadows this dash has made so far


//---parry effects---
parry_fx_colour = c_aqua;   //colour of the charge glow and the shockwave
parry_charged = false;      //has the guard finished rising this parry?

parry_circle_radius = 44;    //size of the charge circle on the ground (was 28)

parry_charge_time  = 45;   //steps it takes to fill the circle (60 = 1 second)
parry_charge_timer = 0;    //counts UP while holding X; full when it reaches parry_charge_time

//guard-raise animation that plays while the parry charges - when it finishes, the guard is up
//order matches dir4: [right, up, left, down]
//(forward one used for every direction for now - swap in the others when they're made)
//put -1 in a slot to skip the animation for that direction and charge on the timer instead
parry_raise_spr = [skull_knight_idle_to_parry_f_spr, skull_knight_idle_to_parry_f_spr,
                   skull_knight_idle_to_parry_f_spr, skull_knight_idle_to_parry_f_spr];
//looping block animation once the guard is up
parry_block_spr = [skull_knight_parry_right_spr, skull_knight_parry_backward_spr,
                   skull_knight_parry_left_spr,  skull_knight_parry_forward_spr];
parry_raising = false;   //is the guard-raise animation playing right now?
parry_dir4 = 3;          //which way this parry faces (0 right, 1 up, 2 left, 3 down)

//---sword glow (once the parry is fully charged)---
sword_sweep        = 0;      //where the rainbow is: 0 = bottom of the sprite, 1 = top (moves on its own)
sword_sweep_speed  = 0.02;   //how fast the rainbow climbs
sword_band         = 0.4;    //how tall the rainbow band is
sword_trail_len    = 0.4;    //how long the trail behind the rainbow is
sword_trail_colour = c_aqua; //colour of the trail
sword_colours      = 2;      //how many colours pass up the sword at once
sword_hue          = 0;      //which colour the current pass starts on (moves on by itself)
sword_saturation   = 0.5;    //how strong the sword colours are (1 = full rainbow, 0 = plain sword)

//shader inputs: look them up once here, use them in Draw
u_uvs       = shader_get_uniform(parryShader, "u_uvs");
u_sweep     = shader_get_uniform(parryShader, "u_sweep");
u_band      = shader_get_uniform(parryShader, "u_band");
u_trail_len = shader_get_uniform(parryShader, "u_trail_len");
u_trail     = shader_get_uniform(parryShader, "u_trail");
u_colours   = shader_get_uniform(parryShader, "u_colours");
u_hue       = shader_get_uniform(parryShader, "u_hue");
u_saturation = shader_get_uniform(parryShader, "u_saturation");