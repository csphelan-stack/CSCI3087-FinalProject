
//parralax background end step

var cx = camera_get_view_x(view_camera[0]);
var cy = camera_get_view_y(view_camera[0]);
for (var i = 0; i < array_length(sky_layers); i++) {
    sky_offset[i] += sky_drift[i];
    layer_x(sky_layers[i], cx * sky_follow[i] + sky_offset[i]);
    layer_y(sky_layers[i], cy);   // keep it filling the screen vertically
}