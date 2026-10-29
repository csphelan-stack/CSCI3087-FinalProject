global.gameIsPaused = false;
global.pauseGameBtn = vk_escape;
global.hover_color = c_teal;	// colour of anything the mouse is over in the pause menu (and the control waiting for a key)

pause_surface=-1;

//lower depth draws on top in Draw GUI: -150 puts the menu above the upgrade cards (-100/-101)
//but still under its own buttons (-200)
depth = -150;

settingsA = array_create(4);

btn_num = array_length(settingsA);


settingsA[0] = {label:"Resume",obj: resume_btn_obj ,spr: gui_dark_button_blue_spr};
settingsA[1] = {label:"Settings",obj: settings_btn_obj ,spr: gui_dark_button_black_spr};
settingsA[2] = {label:"Options",obj: options_btn_obj ,spr: gui_dark_button_grey_spr};
settingsA[3] = {label:"Exit",obj: exit_btn_obj ,spr: gui_dark_close_spr}; // exit stays the last entry, it goes in the corner with no text


width_settings_background = 615;
height_settings_background = 425;

background_spr= gui_dark_frame_gold_spr;


// button layout, everything is placed relative to the background frame above
btn_size = 140;			// every menu button is drawn as a 140x140 square so they all match
btn_gap = 40;			// space between the buttons in the row

close_w = 42;			// the exit X (sprite is 35x40)
close_h = 48;
close_inset_x = 72;		// keeps the X off the gold swirls in the top-right corner
close_inset_y = 36;

label_scale = 2;		// size of the text drawn on the buttons, keep it a whole number so the pixel font stays crisp


// pause menu pages: "main" (the three buttons), "settings" (change controls) or "options"
menu_page = "main";
waiting_for_key = -1;	// which control is waiting for a new key on the Settings page, -1 = none
input_delay = 0;		// skips clicks for a couple of steps after switching page

open_page = function(_page){
	menu_page = _page;
	waiting_for_key = -1;
	input_delay = 2;
};

// Settings page rows: Forward/Backward/Left/Right in the left column, Attack/Dash/Parry in the right
controls = controls_list();
ctrl_row_w = 240;		// a row is the control's name on the left and its key box on the right
ctrl_row_h = 34;
ctrl_row_gap = 10;
ctrl_box_w = 104;

// Back button in the bottom right of the frame, hint text in the bottom left
back_w = 112;
back_h = 44;


// where everything goes on screen. the frame is centred on the GUI, so it doesn't matter where
// this object is placed in the room. runs here, and again every time the game pauses
// (in case the GUI size gets set after this object is made)
layout_menu = function(){
	startx_b = floor((display_get_gui_width()  - width_settings_background)  / 2);
	starty_b = floor((display_get_gui_height() - height_settings_background) / 2);

	page_title_x = startx_b + 72;	// page titles go in the top left, just past the gold corner swirls
	page_title_y = starty_b + 54;

	ctrl_col_x = [startx_b + 60, startx_b + 330];
	ctrl_header_y = starty_b + 108;
	ctrl_rows = [];
	for (var i = 0; i < array_length(controls); i++) {
		var col = (i < 4) ? 0 : 1;
		var row = (i < 4) ? i : i - 4;
		ctrl_rows[i] = {x: ctrl_col_x[col], y: starty_b + 130 + row * (ctrl_row_h + ctrl_row_gap)};
	}

	back_x = startx_b + width_settings_background - 72 - back_w;
	back_y = starty_b + height_settings_background - 92;
	hint_x = startx_b + 72;
	hint_y = back_y + back_h / 2;
};
layout_menu();
