x_tile_pos = floor(x / CELL_WIDTH);
y_tile_pos = floor(y / CELL_HEIGHT);

_initialize = function(){
    inside_sim_box_center = false;
    sprite_ysize = sprite_get_height(sprite_index);
    sprite_xsize = sprite_get_width(sprite_index);
    ycenter_offset = -sprite_ysize / 2;

    speed = 0;
    _speed = 0;
    move_speed_max = 2;
    collision = false;
    _friction = 0.2;

    move_direction = 0;
    move_speed = 1;
    x_speed = 0;
    y_speed = 0;
    grav = 0.25;
    term_velocity = 16;
    _state = "wait";
    floor_state = -1;
    wall_state = -1;
    _grounded = true;
    alarm[0] = 1;
    cooldown_timer = 0;
	_jump_attack_cooldown = 0;
    _state_duration = 0;
	_sight_countdown = 0;
	looking_count = 0;
	attack_look_trigger = 30;
	_xscale = 1;

    //show_debug_message("Enemy Created");
}

_initialize();