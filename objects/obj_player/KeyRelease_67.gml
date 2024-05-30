/// @description Insert description here
// You can write your code in this editor
if (global.cam_mode == 1) {
	view_visible[0] = 0;
	view_visible[1] = 0;
	view_visible[2] = 1;
	view_visible[3] = 0;
	global.cam_mode = 2;
} else if (global.cam_mode == 2){
	view_visible[0] = 0;
	view_visible[1] = 0;
	view_visible[2] = 0;
	view_visible[3] = 1;
	global.cam_mode = 3;
}else if (global.cam_mode == 3){
	view_visible[0] = 1;
	view_visible[1] = 0;
	view_visible[2] = 0;
	view_visible[3] = 0;
	global.cam_mode = 0;
} else {
	view_visible[0] = 0;
	view_visible[1] = 1;
	view_visible[2] = 0;
	view_visible[3] = 0;
	global.cam_mode = 1;
}