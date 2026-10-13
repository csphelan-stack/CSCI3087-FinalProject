gpu_set_fog(true,ghost_colour,0,0);

draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, 0, c_white, image_alpha);

gpu_set_fog(false, c_white,0,0);
