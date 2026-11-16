// ROOM START: this controller is persistent, so Create only ran in the first room,
// but this runs in every room it's carried into.
// every room starts with the view settings from its own room editor (some have view 0 hidden or views off),
// so switch our camera back on here. without this the screen stops updating in the next room and looks frozen.
view_enabled = true;      // use views (cameras) in this room
view_visible[0] = true;   // show view 0
view_camera[0] = cam;     // and make view 0 use our camera (made in Create, moved to follow the player in Step)
