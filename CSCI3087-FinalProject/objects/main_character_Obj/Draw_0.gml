draw_self(); // draw the knight normally (needed, or he becomes invisible)

// draw the hitbox outline in red
draw_rectangle_colour(bbox_left, bbox_top, bbox_right, bbox_bottom,
                      c_red, c_red, c_red, c_red, true);