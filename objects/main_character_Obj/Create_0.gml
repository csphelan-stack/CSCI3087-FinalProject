//This is how you set up a state machine
//you enum x amounts of states
// and then put the case switch statement of these states in the player objects step event
//then from there you can make scripts corresponding to the function name of the states in the step event.
//check movement_MC_script for an example
//this makes writing code for a character much more efficient and also more sperated so it is easier to keep control of

//TEMPORARY
global.temp_upgrade_btn = ord("U");
event_go_upgrade = false;
//optional
enum PlayerState {
	NORMAL,
	ATTACK,
	DASH,
	PARRY,
	STUNNED,
	SPECIAL,   //using whichever special is equipped (special_equipped, see SpecialState below)
	DEAD,
}

//which special attack he has. each one gets its own case in startSpecial() and specialStateMC()
//(top of special_attack_tsunami_script). to add a new special: add a name here, then add its cases there
enum SpecialState {
	NONE,        //no special yet: the special key does nothing
	TSUNAMI,       //Bladed Tsunami: hold to charge, then he whirls round in a wave that throws enemies out and drags them back in
	DANCE,         //Dance of Dragons: a 1 second wind-up, then he dashes enemy to enemy striking each one, and they burn
	BUTTERFLY,     //Butterfly Effect: 10 seconds of harmless fast hits, then they all land at once and butterflies fly out
}

//which state the player is currently in (see PlayerState enum above)
state = PlayerState.NORMAL;


sprite_index = adventurer_idle_forward_spr;
image_speed =1;
//how big he is drawn on screen (1 = normal size)
char_scale = 1;
image_xscale = char_scale;
image_yscale = char_scale;


//player hitbox
mask_index = adventurer_mask_spr;

//---his sprites. every list is in dir4 order: [right, up, left, down]---
idle_spr   = [adventurer_idle_right_spr,   adventurer_idle_backward_spr,
			  adventurer_idle_left_spr,    adventurer_idle_forward_spr];
run_spr    = [adventurer_run_right_spr,    adventurer_run_backward_spr,
			  adventurer_run_left_spr,     adventurer_run_forward_spr];
walk_spr   = [adventurer_walk_right_spr,   adventurer_walk_backward_spr,     //used inside (see characterInside_script)
			  adventurer_walk_left_spr,    adventurer_walk_forward_spr];
attack_spr = [adventurer_attack_right_spr, adventurer_attack_backward_spr,
			  adventurer_attack_left_spr,  adventurer_attack_forward_spr];
dash_spr   = [adventurer_dash_right_spr,   adventurer_dash_backward_spr,
			  adventurer_dash_left_spr,    adventurer_dash_forward_spr];
hurt_spr   = [adventurer_hurt_right_spr,   adventurer_hurt_backward_spr,
			  adventurer_hurt_left_spr,    adventurer_hurt_forward_spr];
death_spr  = [adventurer_death_right_spr,  adventurer_death_backward_spr,
			  adventurer_death_left_spr,   adventurer_death_forward_spr];
//there's no block animation, so he holds his idle pose while guarding / charging the special
parry_block_spr = idle_spr;
parry_raise_spr = idle_spr;

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
//how fast he walks inside (characterInside_script slows him to this)
inside_movespd = 2;
//whether or not he can move
can_move = true;
//start with no attack have some condition to show he can attack.
can_attack = true;
//can he dash / parry / use the special? (characterInside_script turns these off, characterOutside_script back on)
dash_unlock = false;
can_dash = true;
can_parry = true;
can_special = true;


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
//(measured off frame 1, the slash, of each attack sprite at char_scale 1 - attackState multiplies it by char_scale)
//the hitbox's far edge gets lined up with this point
//order matches dir4:   [right,  up,  left,  down]
attack_peak_x =         [  40,    0,   -40,    0 ];
attack_peak_y =         [ -14,  -40,   -14,   13 ];
attack_hit_spawned = false;  //has this swing already made its hitbox?


//which special he's using (see SpecialState). picking a special card sets this, so it lives on the player, not in global
//SpecialState.NONE = locked, no special yet
special_equipped = SpecialState.TSUNAMI;   //TESTING: switch between BUTTERFLY, DANCE and TSUNAMI here

//---Butterfly Effect (special_attack_butterfly_script)---
//for 6 seconds his hits do no damage. instead the first hit on each enemy TAGS it (once per enemy). he swings faster,
//reaches further, knocks back half as hard and runs twice as fast. when it ends time rewinds to when he pressed S and
//freezes, and every tag becomes butterflies he sends to the tagged enemies he picks (the camera pans round the room to them).
//then time restarts: each tagged enemy takes its saved hit (most of them crits) and the butterflies he sent each land a big hit
butterfly_time        = 60 * 6;   //how long the tagging window lasts (6 seconds)
butterfly_timer       = 0;        //counts down while it's on (0 = off)
butterfly_cooldown_t  = 60 * 30;  //cooldown after the window ends (30 seconds)
butterfly_attack_mult = 2.5;      //swings play this many times faster
butterfly_cd_mult     = 3;        //the attack cooldown is this many times shorter
butterfly_range_mult  = 1.5;      //hitboxes are this many times bigger and reach this much further
butterfly_kb_mult     = 0.5;      //knockback is halved
butterfly_move_mult   = 2.5;      //he runs 2.5x faster
butterfly_crit_chance = 0.75;     //chance each stored hit lands as a crit
butterfly_crit_mult   = 2;        //a crit does this many times the damage
butterfly_cap_mult    = 3;        //an enemy takes at most this many times its max health in one payoff
//the rewind and the choice
butterfly_rec_gap     = 2;        //records where everyone is every this many steps during the window
butterfly_rewind_time = 60;       //how long the rewind takes (1 second)
butterfly_sends_per_tag = 2;      //butterflies to send for every enemy he tagged
butterfly_send_max    = 12;       //at most this many butterflies to send
butterfly_send_mult   = 10;       //each butterfly hits for player_damage times this: a massive hit (and can crit, like the stored hits)
butterfly_choose_limit = 60 * 15; //time to place them before any left over go on the enemy being picked (15 seconds, 0 = no limit)
butterfly_go_wait     = 20;       //once the last one's placed, they wait this many steps before they all go (so you can see them)
//the butterflies he sends
butterfly_speed       = 5;        //how fast they fly (pixels per step)
butterfly_life        = 60 * 3;   //they fly off after 3 seconds if they can't reach anyone
butterfly_scale       = 1;        //how big they're drawn (the sprite is butterfly_gif_spr)
butterflies           = [];       //the butterflies in the air (structs, see butterfliesStep)
//the look
butterfly_colours     = [make_colour_rgb(255, 140, 200), make_colour_rgb(180, 130, 255), make_colour_rgb(90, 220, 210), make_colour_rgb(80, 246, 135), make_colour_rgb(255, 210, 100)];   //pink, violet, teal, green, gold (the first one is the screen glow and the hit counters)
butterfly_burst_count = 24;       //butterflies that fly out of him when it starts
butterfly_slash_scale = 2.6;      //how big the butterfly shape each sword swing makes is (it grows with the bigger hitbox too)
butterfly_screen_count = 36;      //butterflies drifting round the edges of the screen during the window
butterfly_screen_band = 40;       //how far in from the edge of the screen they stay (screen pixels)
//runtime (the script sets these)
butterfly_fx          = [];       //the little butterflies and the sword's butterfly shapes (structs, see butterflyFxStep)
butterfly_screen      = [];       //the butterflies round the screen edges (structs, see butterflyScreenStep)
butterfly_screen_alpha = 0;       //they fade in when the window starts and out when it ends
butterfly_trail_timer = 0;        //lets a little butterfly loose behind him every few steps during the window
butterfly_phase       = "";       //"" (normal or the window), "rewind" or "choose"
butterfly_rec         = [];       //the recording: snapshots of where he and every enemy were
butterfly_rec_timer   = 0;
butterfly_rewind_t    = 0;        //steps into the rewind
butterfly_choose_t    = 0;        //steps into the choice
butterfly_choices     = [];       //the enemies he can send butterflies to (every living enemy in the room)
butterfly_sends       = [];       //how many he's sending to each of them
butterfly_sel         = 0;        //which one he's picking
butterfly_budget      = 0;        //how many butterflies he got to send
butterfly_left        = 0;        //how many he hasn't placed yet
butterfly_go_delay    = 0;        //counts down from butterfly_go_wait once they're all placed

//the camera looks at this instead of him while it exists (noone = follow him as normal, see Room_controller_object Step)
cam_target            = noone;

//---Dance of Dragons (special_dance_attack_script)---
//press S: he goes straight away, dashing to the nearest enemy without stopping while enemies slow right down.
//a QTE: press Z as he arrives (when the closing ring meets the small ring) to strike: PERFECT, GOOD or MISS.
//then on to the next nearest enemy, up to 5 in a row (+1 for every PERFECT, the 2nd MISS ends it).
//an orange and red trail follows him and burns what it touches
dance_windup_time    = 0;         //steps he stands still before it goes (0 = goes the moment you press S, 60 = 1 second)
dance_range          = 220;       //how far from where he is (room pixels) it looks for the next enemy
dance_targets_max    = 5;         //most enemies he goes to in a row (before PERFECT bonuses)
dance_dash_speed     = 9;         //how fast he dashes between them (pixels per step)
dance_leg_time_max   = 45;        //skips an enemy he can't reach in this many steps (a wall in the way)
dance_hit_radius     = 56;        //reach of each strike, round the enemy (much bigger than the sword's)
dance_damage_mult    = 1.5;       //each strike does player_damage times this
dance_knockback      = 5;
dance_orbit_radius   = 28;        //how far from the enemy he circles while striking
dance_orbit_time     = 24;        //steps he spends circling each enemy (a late press still counts during this)
dance_orbit_turn     = 200;       //degrees he goes round each enemy
dance_colour         = make_colour_rgb(255, 90, 20);   //orange-red: the strikes, rings and the wind-up circle
dance_ghost_colour   = [make_colour_rgb(255, 90, 20), make_colour_rgb(224, 93, 0), make_colour_rgb(244, 186, 11), make_colour_rgb(154, 40, 29)];   //his afterimages (orange-red, orange, gold, ember)
dance_burn_time      = 60 * 4;    //how long each struck enemy burns (4 seconds)
dance_burn_tick      = 30;        //steps between burn damage (2 a second)
dance_burn_damage    = 1;         //damage each burn tick does
dance_cooldown_t     = 60 * 10;   //cooldown after a dance (10 seconds)
dance_interrupt_cd   = 60 * 8;    //shorter cooldown if he gets hit during the wind-up
dance_enemy_scale    = 0.25;      //slow motion: enemies run at this speed while he dances (0.25 = a quarter speed, 1 = off)
//timed strikes: press Z as he arrives
dance_perfect_frames = 8;         //within this many frames of arriving (early or late) = PERFECT
dance_good_frames    = 20;        //within this many = GOOD. further off, or never = MISS
dance_perfect_mult   = 2;         //a PERFECT strike does this many times the damage (it's a crit)
dance_perfect_radius = 1.3;       //and reaches this much further
dance_miss_mult      = 0.5;       //a MISS still hits, but this weakly
dance_miss_limit     = 2;         //the dance ends on this many MISSes (so the first one is forgiven)
dance_chain_cap      = 10;        //every PERFECT lets the chain go 1 further, up to this many
dance_ring_size      = 14;        //the small ring round the enemy you time against
dance_ring_px        = 1.5;       //how fast the big ring closes in (pixels per frame, lower = it starts further out)
dance_perfect_hitstop = 4;        //a PERFECT freezes him for this many frames, so the hit lands with a punch (0 = off)
dance_grade_time     = 36;        //how long "PERFECT!" / "GOOD" / "MISS" stays up (frames)
//the finisher at the end of the dance
dance_finale_time    = 54;        //how long the finisher lasts (frames)
dance_finale_hit_at  = 16;        //the blast goes off this many frames before the end (the rest is slow-mo knockback)
dance_finale_scale   = 0.05;      //enemies slow even further during it (0.05 = a twentieth of normal speed)
dance_finale_radius  = 70;        //reach of the blast, all round him (small enough to stay on screen)
dance_finale_mult    = 3;         //the blast does player_damage times this (shown as a crit)
dance_finale_knockback = 14;      //how hard it flings enemies
//the trail that follows him
dance_trail_len      = 28;        //how long it is (how many of his recent positions it covers)
dance_trail_width    = 7;         //how thick it is at the front (it thins toward the end)
dance_trail_head     = make_colour_rgb(255, 150, 30);   //orange at the front
dance_trail_tail     = make_colour_rgb(210, 30, 20);    //red toward the end
dance_trail_damage   = 1;         //damage when it touches an enemy (once per enemy per dance), and that enemy will burn
//runtime (the script sets these)
dance_phase          = "windup";  //"windup" -> "dash" (to the next enemy) -> "strike" (circling it) -> "dash" ...
dance_timer          = 0;
dance_route          = [];        //the enemies he's gone to so far this dance (the last one is where he's headed)
dance_index          = 0;         //which one he's on (always the last one in dance_route)
dance_hit_list       = [];        //every enemy a strike or the trail touched (they all burn at the end)
dance_chain_max      = 5;         //how many he can go to this dance (dance_targets_max + PERFECT bonuses)
dance_pressed        = false;     //was Z pressed on the way in to this enemy?
dance_press_grade    = "";        //and how well timed it was
dance_resolved       = false;     //has the strike on this enemy landed yet?
dance_late           = 0;         //frames since he arrived (for a late press)
dance_end_after      = false;     //too many MISSes: the dance ends once he's done circling
dance_misses         = 0;         //MISSes so far this dance
dance_hitstop        = 0;         //frames left of a PERFECT's freeze
dance_sparks         = [];        //sparks flying out of the strikes
dance_fx_age         = 0;         //counts up, turns the ticks round the QTE ring
dance_grade_text     = "";        //"PERFECT!" / "GOOD" / "MISS" floating above the enemy
dance_grade_timer    = 0;
dance_grade_x        = 0;
dance_grade_y        = 0;
dance_cx             = 0;         //the middle of the circle he's going round
dance_cy             = 0;
dance_orbit_start    = 0;
dance_orbit_dir      = 1;         //1 or -1: which way round he circles
dance_angle          = 0;
dance_ghost_timer    = 0;
dance_trail          = [];        //the trail: his recent positions, newest first
dance_trail_hits     = [];        //enemies the trail has already hurt this dance

//---the dragon companion (comes with the Dance of Dragons, bottom of special_dance_attack_script)---
//while the Dance is equipped a small dragon circles him, follows him when he dances, and when he isn't dancing
//bites enemies it touches, setting them on fire. in the finisher it dives into the ground and explodes into flames,
//and comes back once the special is ready again
dragon_on            = true;      //false = no dragon
dragon_len           = 22;        //how long its body is (how many of its recent positions)
dragon_width         = 5;         //how thick its body is at the neck (it tapers to the tail)
dragon_wave          = 4;         //how far its body swings from side to side as it flies
dragon_orbit_radius  = 44;        //how far from him it circles
dragon_orbit_speed   = 2.5;       //how fast it circles (degrees per step)
dragon_follow        = 0.18;      //how quickly its head glides to where it wants to be (0 to 1)
dragon_hit_radius    = 10;        //how close an enemy has to be to its head to get bitten
dragon_hit_cooldown  = 45;        //steps before it can bite the same enemy again
dragon_burn_time     = 60 * 2;    //a bite sets the enemy burning this long (2 seconds)
dragon_burn_tick     = 30;        //steps between burn damage
dragon_burn_min      = 1;         //each burn tick does from this much...
dragon_burn_max      = 3;         //...up to this much (picked at random)
dragon_rise          = 70;        //in the finisher: how high above him it climbs before it dives
dragon_head_col      = make_colour_rgb(255, 90, 20);    //orange-red at the head
dragon_tail_col      = make_colour_rgb(244, 186, 11);   //fading to gold at the tail
dragon_trim_col      = make_colour_rgb(255, 230, 120);  //horns, whiskers and the ridge down its back
dragon_flame_core    = make_colour_rgb(255, 240, 150);  //flames: yellow-white when they're new...
dragon_flame_mid     = make_colour_rgb(255, 140, 20);   //...orange...
dragon_flame_outer   = make_colour_rgb(200, 30, 10);    //...and red as they burn out
//runtime (the script sets these)
dragon_x             = x;         //where its head is
dragon_y             = y - 20;
dragon_angle         = 0;         //where it is on its circle round him
dragon_body          = [];        //its body: its head's recent positions, newest first
dragon_age           = 0;         //counts up: its flowing wave, and when each enemy can be bitten again
dragon_gone          = false;     //exploded in the finisher (it comes back when the special's ready)
dragon_flames        = [];        //the flames in the air (structs, see dragonFlamesStep)

//---Bladed Tsunami (special_attack_tsunami_script): hold S to charge, then he whirls round as a tsunami---
tsunami_charge_time  = 60;       //steps to fully charge (60 = 1 second)
tsunami_charge_timer = 0;
tsunami_charged      = false;
tsunami_dir4         = 3;
tsunami_time         = 300;      //how long the tsunami lasts (300 = 5 seconds)
tsunami_timer        = 0;
tsunami_angle        = 0;
tsunami_turn_rate    = 24;       //degrees he turns each step (bigger = faster whirl)
tsunami_frame        = 2;        //which frame of the attack sprites he holds while whirling (the sword out)
//moving during the tsunami: fast but hard to control (normal walk is 3)
tsunami_speed        = 4.5;      //top speed
tsunami_launch       = 3;        //speed he gets launched at, the way he was facing, when it starts
tsunami_accel        = 0.35;     //how hard the movement keys push him (lower = slower to turn = less control)
tsunami_drag         = 0.95;     //how much speed he keeps each step (closer to 1 = slides more)
tsunami_wobble       = 0.2;      //how hard the current shoves him off course each step
tsunami_vx           = 0;        //his speed during the tsunami
tsunami_vy           = 0;
tsunami_wobble_dir   = 0;        //which way the current is shoving him (wanders round on its own)
tsunami_radius       = 48;       //reach of each wave (room pixels from his middle)
tsunami_damage       = 5;        //damage to each enemy in reach, every wave
tsunami_tick_time    = 12;       //steps between waves (12 = 5 waves a second)
tsunami_tick_timer   = 0;
tsunami_knockback    = 6;        //how hard each wave throws enemies out
//the undertow: between waves, enemies get dragged back in toward him
tsunami_pull_radius  = 120;      //how far out the undertow reaches (bigger than the waves, so thrown enemies come back)
tsunami_pull_speed   = 1.8;      //how fast it drags them in (pixels a step at the edge, half that up close)
tsunami_pull_min     = 18;       //stops pulling this close, so they don't pile up on top of him
tsunami_pull_swirl   = 30;       //degrees the pull is turned sideways, so they swirl round him as they come in (0 = straight in)
tsunami_drops        = [];       //the water droplets (structs, see tsunamiDropsStep)
tsunami_drop_max     = 160;      //most droplets at once
tsunami_ghost_gap    = 3;        //steps between the coloured afterimages
tsunami_ghost_timer  = 0;
tsunami_cooldown_t   = 60*15;    //the HEAVY cooldown after the tsunami (15 seconds)
tsunami_interrupt_cd = 60*8;     //shorter cooldown if you get hit while charging
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

perfect_p_unlocked = false;

//---parry: block + perfect parry (see the top of parryState for how it all fits together)---
//perfect parry: a hit this many steps after pressing parry is parried perfectly (no damage + auto counter)
parry_perfect_window = 6;
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


//adds a double dashing ability
dash_double_unlock = false;
//counts if a dash has happen more than once.
dash_double_counter = 0;
//gives .5 secs to hit the next dash
dash_double_wait_time = 0;
dash_double_w_time_set = 30;

dash_length = 80;  //total pixels one dash travels

dash_timer = 0;
dash_time = 5;

dash_dir = 0;

//---dash afterimages---
dash_ghost_count       = 3;     //how many shadows each dash leaves
dash_ghost_alpha_first = 0.7;   //opacity of the first shadow
dash_ghost_alpha_last  = 0.3;   //opacity of the last shadow (the ones between are spread evenly)
//rainbow colours in order, each one taken from a card pack (repeats if there are more shadows than colours)
dash_ghost_colour      = [
	make_colour_rgb(249, 83, 97),    //red      #f95361 (fantasy)
	make_colour_rgb(224, 93, 0),     //orange   #e05d00 (fire)
	make_colour_rgb(244, 186, 11),   //yellow   #f4ba0b (fire)
	make_colour_rgb(218, 246, 80),   //lime     #daf650 (deco)
	make_colour_rgb(27, 224, 0),     //green    #1be000 (nautical)
	make_colour_rgb(0, 224, 150),    //teal     #00e096 (forest)
	make_colour_rgb(0, 152, 219),    //blue     #0098db (space)
	make_colour_rgb(154, 29, 123)    //purple   #9a1d7b (fantasy)
];
dash_tint              = c_orange;   //what he's tinted while dashing
dash_ghost_hold        = 4;     //steps before the FIRST shadow starts fading
dash_ghost_stagger     = 5;     //steps between each shadow starting to fade
dash_ghost_fade        = 16;    //steps each shadow takes to fade out
dash_ghosts_made       = 0;     //how many shadows this dash has made so far



parry_dir4 = 3;          //which way this parry faces (0 right, 1 up, 2 left, 3 down)
parry_fx_colour = c_aqua;   //colour of the block flash and guard meter (the special has its own colours, tsunami_colour)
parry_circle_radius = 44;   //size of the parry ring (and the saved charge circle below)

//---Bladed Tsunami colours (the Nautical card's greens, and blues)---
tsunami_colour       = make_colour_rgb(0, 152, 219);   //blue: charge circle, charge glow, the big wave rings and the undertow's edge
tsunami_wave_colours = [make_colour_rgb(0, 152, 219), make_colour_rgb(0, 224, 150), make_colour_rgb(27, 224, 0), make_colour_rgb(155, 246, 81)];   //blue, teal, green, light green: the swirling waves, the wave rings and the droplets
tsunami_ghost_colour = [c_white, make_colour_rgb(155, 246, 81), make_colour_rgb(0, 224, 150), make_colour_rgb(0, 152, 219)];   //his afterimages: white, light green, teal, blue


//============================================================
//shockwave / special attack visuals (the old charge-up parry's effects, now used by the special)
//the fx functions at the bottom of parryState use these
//============================================================







//---sword glow (palette colours up the sword once something is fully charged)---
sword_sweep        = 0;      //where the colour band is: 0 = bottom of the sprite, 1 = top (moves on its own)
sword_sweep_speed  = 0.02;   //how fast the band climbs
sword_band         = 0.4;    //how tall the colour band is
sword_trail_len    = 0.4;    //how long the trail behind the band is
sword_trail_colour = make_colour_rgb(24, 124, 46); //colour of the trail (deep sea green)
sword_palette      = [make_colour_rgb(0, 152, 219), make_colour_rgb(27, 224, 0), make_colour_rgb(155, 246, 81)]; //the band's colours, in order (exactly 3: blue, green, light green)
sword_colours      = 2;      //how many colours pass up the sword at once
sword_hue          = 0;      //which sword_palette colour the current pass starts on (moves on by itself)
sword_saturation   = 0.5;    //how strong the sword colours are (1 = full colour, 0 = plain sword)

//shader inputs: look them up once here, use them in Draw
u_uvs       = shader_get_uniform(parryShader, "u_uvs");
u_sweep     = shader_get_uniform(parryShader, "u_sweep");
u_band      = shader_get_uniform(parryShader, "u_band");
u_trail_len = shader_get_uniform(parryShader, "u_trail_len");
u_trail     = shader_get_uniform(parryShader, "u_trail");
u_colours   = shader_get_uniform(parryShader, "u_colours");
u_hue       = shader_get_uniform(parryShader, "u_hue");
u_pal0      = shader_get_uniform(parryShader, "u_pal0");
u_pal1      = shader_get_uniform(parryShader, "u_pal1");
u_pal2      = shader_get_uniform(parryShader, "u_pal2");
u_saturation = shader_get_uniform(parryShader, "u_saturation");

// universal cooldowns
dash_cd_max    = dash_cooldown_t;   dash_cd_prev    = 0;
parry_cd_max   = parry_cooldown_t;  parry_cd_prev   = 0;
special_cd_max = tsunami_cooldown_t; special_cd_prev = 0;

//UI cluster dimmer
orb_surf = -1;




//---hurt flinch + death (see playerHurtDeath)---
hurt_flinch_time = 20;    //steps the hurt animation shows after a hit (4 frames at 12 fps)
hurt_timer = 0;
death_hold_time = 60;     //steps he lies on the ground after the death animation before the restart
death_hold_timer = -1;

sword_damage = 4;




