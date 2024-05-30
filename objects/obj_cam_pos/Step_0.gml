/// @description Insert description here
// You can write your code in this editor
if (global.game_start == true) {
    var current_x = global._cam.x;
    var current_y = global._cam.y;
	current_x = ceil(current_x)
	current_y = floor(current_y)
	
	if (global.cam_mode == 1) {
		var cam_ = view_camera[1];
	} else if (global.cam_mode == 2) {
		var cam_ = view_camera[2];
	} else if (global.cam_mode == 3) {
		var cam_ = view_camera[3];
	} else {
		var cam_ = view_camera[0];
	}
    
	/*
    var _xview = floor(obj_player.x) - camera_get_view_width(cam_)/2;
    var _yview = floor(obj_player.y) - camera_get_view_height(cam_)/2;
    */
	_xview = current_x - camera_get_view_width(cam_)/2;
    _yview = current_y - camera_get_view_height(cam_)/2;
    camera_set_view_pos(cam_, _xview, _yview);
	

	if (global.true_sim_size < global.sim_size) { global.true_sim_size += 4; } 
	//if (global.true_refresh_size < global.refresh_size) { global.true_refresh_size += 4; } 
	
	if (abs(obj_player.x_speed)+abs(obj_player.y_speed)> 8){
		_border_size = 6;
	} else {
		border_size = 2;
	}
	
	sim_space(current_x, current_y, global.true_sim_size, _scarce_mode, border_size);
	/*
	var rounded_x = round_by_units(current_x, TILE_WIDTH, "floor");
	var rounded_y = round_by_units(current_y, TILE_HEIGHT, "floor");
	refresh_box(rounded_x, rounded_y, global.true_refresh_size, global.refresh_rate);

	global.simulation_box_x = current_x;
	global.simulation_box_y = current_y;
	*/
}