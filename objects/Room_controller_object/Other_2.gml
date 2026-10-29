screen_multiple = 3;

// Window size
var win_w = global.BASE_W * screen_multiple;
var win_h = global.BASE_H * screen_multiple;
window_set_size(win_w, win_h);

// Apply viewport to match window size exactly
view_wport[0] = win_w;
view_hport[0] = win_h;
view_xport[0] = 0;
view_yport[0] = 0;

// Application surface stays base resolution
if (application_surface != -1) {
    surface_resize(application_surface, global.BASE_W, global.BASE_H);
}


