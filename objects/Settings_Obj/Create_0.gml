global.gameIsPaused = false;
global.pauseGameBtn = vk_escape;

pause_surface=-1;

settingsA = array_create(4);

btn_num = array_length(settingsA);


settingsA[0] = {label:" Resume:",obj: resume_btn_obj ,spr: gui_menu_play_spr};
settingsA[1] = {label:" Settings",obj: settings_btn_obj ,spr: gui_menu_settings_spr};
settingsA[2] = {label:" Options",obj: options_btn_obj ,spr: gui_menu_options_spr};
settingsA[3] = {label:" Exit? ",obj: exit_btn_obj ,spr: gui_menu_exit_spr};



startx= x-200;
starty=y-210;

startwidth = 0;
startheight = 0;

spaced= 100;
