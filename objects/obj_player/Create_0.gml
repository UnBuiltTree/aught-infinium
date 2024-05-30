player_initialize = function(){
	_direction = 1;
	player_local_id = 1;
	player_ysize = sprite_get_height(sprite_index);
	player_xsize = sprite_get_width(sprite_index);
	ycenter_offset = player_ysize/2;
	
	speed = 0;
	_speed = 0;
	move_speed_max = 2;
	alarm[0] = 60*4;
	
	global.gun_1_cooldown = 0;
	global.gun_2_cooldown = 0;
	global.gun_3_cooldown = 0;
	global.gun_4_cooldown = 0;
	
	global.gun_ammo = 0;
	
	collision = false
	grounded = false;
	_friction = 0.2;
	
	
	move_direction = 0;
	last_draw_direction = 1;
	walking = 0;
	frame = 0;
	alarm[0] = 60*0.2;
	move_speed = 1.5;
	current_x_speed = 0;
	knock_back_speed = 0;
	x_speed = 0;
	y_speed = 0;
	fly_acceleration = -0.5;
	fly_speed_max = 3;
	grav = 0.25;
	term_velocity = 16;
	_health = 100;
	damage_cooldown = 60;
	
	box_width = 2 * TILE_WIDTH;
	box_height = 2 * TILE_HEIGHT;
	
	placing_tile_id = DIRT
	
	show_debug_message("Player Created")
	
}

health_manager = function(){
	if _health <= 0 {
		instance_destroy(self)
	}
}


update_cam_pos = function(_cam, _x, _y) {
	global._cam.x = _x
	global._cam.y = _y
}

