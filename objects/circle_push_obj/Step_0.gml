
max(main_character_Obj.invuln, 10);

if (radius < max_radius) {
    radius += grow_speed;
} else {
	main_character_Obj.flood_formation_finished = true;
    instance_destroy(); // Optional: destroy once it reaches max size
}


