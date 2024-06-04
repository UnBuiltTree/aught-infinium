/*
	global varables are defined here
*/
global.player_alive = false;
global.debug_mode = false;

global._base_width = 720;
global._base_height = 400;

menu_initialize  = function(){
	randomize();
	room_set_width(rm_main_menu, global._base_width);
    room_set_height(rm_main_menu, global._base_height);

    var _display_width = display_get_width();
    var _display_height = display_get_height();

    var _scale_factor = min(_display_width / global._base_width, _display_height / global._base_height);
	//_scale_factor = (floor((_scale_factor/0.25)))*0.25
	show_debug_message("scale_factor: " + string(_scale_factor))

    var _new_width = round(global._base_width * _scale_factor);
    var _new_height = round(global._base_height * _scale_factor);

    window_set_size(global._base_width*2, global._base_height*2);
    window_center();
	//display_set_gui_size(_new_width, _new_height)
	window_set_cursor(cr_cross);
}


create_buttons = function(){
	instance_create_layer(room_width/2, room_height/2, "Instances", obj_btn_start);
}

menu_initialize();
create_buttons();