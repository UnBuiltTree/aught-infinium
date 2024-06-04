if (global.debug_mode){
	if (global.cam_mode != 3) {
		draw_sim_space(x, y, global.true_sim_size, _scarce_mode, border_size)
	}
	
	if (global.cam_mode < 2) {
		draw_set_color(#ffff00);
		draw_set_alpha(0.5)
		with (obj_tile_object) {
			draw_rectangle(x+2, y+2, x + TILE_WIDTH-3, y + TILE_HEIGHT-3, true); 
		}
		draw_set_alpha(1)
		draw_set_color(c_white); 
	}
	draw_set_color(c_blue); 
	var middle_xview = _xview + camera_get_view_width(camera_get_active())/2
	var middle_yview = _yview + camera_get_view_height(camera_get_active())/2
	draw_point(middle_xview, middle_yview)
	draw_set_color(c_white); 
}