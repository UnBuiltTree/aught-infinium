/// @description Insert description here
// You can write your code in this editor
cam_width = 480;
cam_height = 270;

surface_resize(application_surface, cam_width+1, cam_height+1);
application_surface_draw_enable(false)

_scarce_mode = false;
_cool_down = true;
_xview = x;
_yview = y;
alarm[0] = 30*6;