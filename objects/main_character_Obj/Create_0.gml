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
	STUNNED,
	SPECIAL_CHARGE,
	SPECIAL_SPIN,
	DEAD,
}

//which state the player is currently in (see PlayerState enum above)
state = PlayerState.NORMAL;


//(use_adventurer_sprites at the bottom of Create swaps all his sprites for the Adventurer ones)
sprite_index = skull_knight_idle_forward_spr;
image_speed =1;
//how big he is drawn on screen (1 = normal size). change this to 2 to make him big again
char_scale = 1;
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

// attack, dash and parry keys are global.attack_button / dash_button / parry_button now
// (set in Room_controller_object, changeable on the pause menu's Settings page)
consumeBtn = ord("A");





//---attack settings---
attack_hit_frame = 1;        //which frame of the swing makes the hitbox (0 = first frame)
//the farthest point the sword's swoosh reaches in each direction, measured from his feet
//(measured off the slash frame of each attack sprite at char_scale 1 - attackState multiplies it by char_scale)
//the hitbox's far edge gets lined up with this point
//order matches dir4:   [right,  up,  left,  down]
attack_peak_x =         [  32,   -2,   -32,   -1 ];
attack_peak_y =         [  -6,  -26,    -6,   17 ];
attack_hit_spawned = false;  //has this swing already made its hitbox?
//attack sprite for each direction. order matches dir4: [right, up, left, down]
attack_spr = [skull_knight_attack_right_spr, skull_knight_attack_backward_spr,
              skull_knight_attack_left_spr,  skull_knight_attack_forward_spr];

//---special attack: hold S to charge, let go to spin like a tornado (functions at the bottom of attackState)---
special_charge_time  = 60;       //steps to fully charge (60 = 1 second)
special_charge_timer = 0;
special_charged      = false;
special_dir4         = 3;
special_spin_time    = 150;      //how long the tornado lasts (150 = 2.5 seconds)
special_spin_timer   = 0;
special_spin_angle   = 0;
special_spin_rate    = 24;       //degrees he turns each step (bigger = faster spin)
special_spin_frame   = 2;        //which frame of the attack sprites he holds while spinning (the sword out)
//moving while spinning: fast but hard to control (normal walk is 3)
special_spin_speed   = 4.5;      //top speed while spinning
special_spin_launch  = 3;        //speed he gets launched at, the way he was facing, when the spin starts
special_spin_accel   = 0.35;     //how hard the movement keys push him (lower = slower to turn = less control)
special_spin_drag    = 0.95;     //how much speed he keeps each step (closer to 1 = slides more)
special_spin_wobble  = 0.2;      //how hard the tornado shoves him off course each step
special_vx           = 0;        //his speed while spinning
special_vy           = 0;
special_wobble_dir   = 0;        //which way the tornado is shoving him (wanders round on its own)
special_radius       = 48;       //reach of the tornado (room pixels from his middle)
special_damage       = 3;        //damage to each enemy in reach, every tick
special_tick_time    = 12;       //steps between damage ticks (12 = 5 hits a second)
special_tick_timer   = 0;
special_knockback    = 6;        //how hard enemies get flung out
special_ghost_gap    = 3;        //steps between the coloured afterimages
special_ghost_timer  = 0;
special_cooldown_t   = 60*15;    //the HEAVY cooldown after a spin (15 seconds)
special_interrupt_cd = 60*8;     //shorter cooldown if you get hit while charging
special_cooldown     = 0;

//tracks opp of swing
opp_swing_dir = 0;
//knockback: a push that slides him and fades out, in any state (applied in Step)
push_x = 0;
push_y = 0;
push_friction = 0.8;    //how much of the push is left each step (lower = stops sooner)
attack_recoil = 3;      //push back when one of his swings lands on an enemy
hit_knockback = 6;      //push back when an enemy hits him

attack_cooldown_time = 10; //60 = 1 sec wait
attack_cooldown = 0;

//cooldown
dash_cooldown_t = 60;
dash_cooldown = 0;



// -----damage taking variables
invuln_time = 30; // steps until he can be hit again
invuln = 0;


//real player damage spot
player_damage = 4;
//normal swing is 4
counter_damage = round(player_damage*1.5);

//---damage counter above enemies (functions at the bottom of attackState)---
dmg_popups = [];       //one counter per enemy being hit
dmg_combo_time = 90;   //steps a counter stays up after the last hit (hit again before then and it adds up)
dmg_fade_time = 6;     //it fades out over the last this-many steps
dmg_fall = 18;         //how far it drops while fading out (room pixels)
dmg_hop_speed = 3;     //how fast it pops up on each hit (bigger = higher hop)
dmg_hop_gravity = 1.3; //how fast it falls back (bigger = snappier)
dmg_text_scale = 1;    //text size (whole numbers stay crisp)
dmg_crit_time = 45;    //how long "Crit!" stays on screen after a counter hit


//if parry is successful
parry_success = false;
parry_was_hit = false;



//---parry: block + perfect parry (see the top of parryState for how it all fits together)---
//perfect parry: a hit this many steps after pressing parry is parried perfectly (no damage + auto counter)
parry_perfect_window = 10;
parry_perfect_timer = 0;

//parry cooldowns
parry_cooldown_t = 60*6;     //the LONG one: after the guard breaks or runs out
parry_recover_time = 15;     //the short one: after letting go, so you can't spam taps for perfect parries
parry_cooldown = 0;

//guard meter: drains while guarding and when blocking hits, refills when not guarding
parry_exhaust_time = 60*3;            //full meter (also = how long you can hold the guard with no hits)
parry_exhaust_timer = parry_exhaust_time;
parry_hit_cost = 15;                  //meter lost per point of damage blocked (a 3 damage hit = 45)
parry_guard_regen = 2;                //meter gained per step while not guarding
parry_perfect_refund = 60;            //meter given back by a perfect parry

//when the meter is nearly empty it begins to blink until eventually
// we exhuast the player.
parry_blink_time = 60;

//quick flash when a hit is blocked
block_flash_time = 8;
block_flash = 0;

//how long the enemy is stunned for after we parry them
parry_stagger_time = 40;

//is the current swing a counter from a parry? (set by startAttackPlayer)
attack_is_countered = false;

//getting your guard broken stuns him
stun_time = 45;    //steps he can't move or act (60 = 1 second)
stun_timer = 0;
//idle sprite for each direction, used while stunned. order matches dir4: [right, up, left, down]
idle_spr = [skull_knight_idle_right_spr, skull_knight_idle_backward_spr,
            skull_knight_idle_left_spr,  skull_knight_idle_forward_spr];



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


//looping block animation while the guard is up. order matches dir4: [right, up, left, down]
parry_block_spr = [skull_knight_parry_right_spr, skull_knight_parry_backward_spr,
                   skull_knight_parry_left_spr,  skull_knight_parry_forward_spr];
parry_dir4 = 3;          //which way this parry faces (0 right, 1 up, 2 left, 3 down)
parry_fx_colour = c_aqua;   //colour of the block flash and guard meter (and the saved shockwave fx below)
parry_circle_radius = 44;   //size of the parry ring (and the saved charge circle below)


//============================================================
//shockwave / special attack visuals (the old charge-up parry's effects, now used by the special)
//the fx functions at the bottom of parryState use these
//============================================================

//guard-raise animation he plays while charging the special. order matches dir4: [right, up, left, down]
//(forward one used for every direction - swap in the others when they're made)
parry_raise_spr = [skull_knight_idle_to_parry_f_spr, skull_knight_idle_to_parry_f_spr,
                   skull_knight_idle_to_parry_f_spr, skull_knight_idle_to_parry_f_spr];

//---sword glow (rainbow up the sword once something is fully charged)---
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

// universal cooldowns
dash_cd_max    = dash_cooldown_t;   dash_cd_prev    = 0;
parry_cd_max   = parry_cooldown_t;  parry_cd_prev   = 0;
special_cd_max = special_cooldown_t; special_cd_prev = 0;

//UI cluster dimmer
orb_surf = -1;

dash_cd_max     = dash_cooldown_t;     dash_cd_prev    = 0;
parry_cd_max    = parry_cooldown_t;    parry_cd_prev   = 0;
special_cd_max  = special_cooldown_t;  special_cd_prev = 0;



//============================================================
//which art he uses
//true = the new Adventurer sprites, false = the old skull knight (flip to false to change him back)
//everything in here only swaps sprites, sizes and the sword reach - the gameplay stays the same
//(the adventurer also gets a hurt flinch and a death animation, which the skull knight has no art for)
//============================================================
use_adventurer_sprites = true;

//run sprite for each direction (used by movement and dash). order matches dir4: [right, up, left, down]
run_spr = [skull_knight_run_right_spr, skull_knight_run_backward_spr,
           skull_knight_run_left_spr,  skull_knight_run_forward_spr];

//dash, hurt and death sprites (see dashStateMC and playerHurtDeath)
//the skull knight has no art for these, so he dashes frozen on his first run frame,
//has no hurt flinch, and restarts straight away when he dies
dash_spr = run_spr;
dash_play_anim = false;   //true = play the dash sprite through over the dash, false = hold its first frame
hurt_spr = undefined;
death_spr = undefined;

hurt_flinch_time = 20;    //steps the hurt animation shows after a hit (4 frames at 12 fps)
hurt_timer = 0;
death_hold_time = 60;     //steps he lies on the ground after the death animation before the restart
death_hold_timer = -1;

if (use_adventurer_sprites) {
	//the adventurer art is already about as big as the skull knight at char_scale 2
	char_scale = 1;
	image_xscale = char_scale;
	image_yscale = char_scale;

	sprite_index = adventurer_idle_forward_spr;
	mask_index = adventurer_mask_spr;   //same size hitbox as the skull knight's

	idle_spr   = [adventurer_idle_right_spr,   adventurer_idle_backward_spr,
	              adventurer_idle_left_spr,    adventurer_idle_forward_spr];
	run_spr    = [adventurer_run_right_spr,    adventurer_run_backward_spr,
	              adventurer_run_left_spr,     adventurer_run_forward_spr];
	attack_spr = [adventurer_attack_right_spr, adventurer_attack_backward_spr,
	              adventurer_attack_left_spr,  adventurer_attack_forward_spr];
	dash_spr   = [adventurer_dash_right_spr,   adventurer_dash_backward_spr,
	              adventurer_dash_left_spr,    adventurer_dash_forward_spr];
	hurt_spr   = [adventurer_hurt_right_spr,   adventurer_hurt_backward_spr,
	              adventurer_hurt_left_spr,    adventurer_hurt_forward_spr];
	death_spr  = [adventurer_death_right_spr,  adventurer_death_backward_spr,
	              adventurer_death_left_spr,   adventurer_death_forward_spr];
	dash_play_anim = true;

	//the adventurer pack has no block animation, so he holds his idle pose while guarding
	parry_block_spr = idle_spr;
	parry_raise_spr = idle_spr;

	//sword reach, measured off frame 1 (the slash) of each adventurer attack sprite at char_scale 1
	//order matches dir4:   [right,  up,  left,  down]
	attack_peak_x =         [  40,    0,   -40,    0 ];
	attack_peak_y =         [ -14,  -40,   -14,   13 ];
}





