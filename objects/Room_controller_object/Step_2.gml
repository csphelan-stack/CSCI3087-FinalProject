
//background end step: the sky is pinned to the camera so it stays perfectly still on screen
//(the parallax version below moved it by fractions of a pixel every step, and because the sky is
// scaled by a non-whole number that made a rolling/shimmering glitch in it)

var cx = camera_get_view_x(view_camera[0]);
var cy = camera_get_view_y(view_camera[0]);
for (var i = 0; i < array_length(sky_layers); i++) {
    layer_x(sky_layers[i], cx);
    layer_y(sky_layers[i], cy);
}

//old parallax version (swap it back in for moving clouds)
/*
for (var i = 0; i < array_length(sky_layers); i++) {
    sky_offset[i] += sky_drift[i];
    layer_x(sky_layers[i], cx * sky_follow[i] + sky_offset[i]);
    layer_y(sky_layers[i], cy);   // keep it filling the screen vertically
}
*/
