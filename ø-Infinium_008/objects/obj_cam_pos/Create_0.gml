/// @description Insert description here
// You can write your code in this editor
cam_width = 720;
cam_height = 400;

surface_resize(application_surface, cam_width, cam_height);
application_surface_draw_enable(false)

_scarce_mode = false;
_cool_down = true;
_xview = x;
_yview = y;
alarm[0] = 30*6;