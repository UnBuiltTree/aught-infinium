/// @description Insert description here
// You can write your code in this editor
gpu_set_blendenable(false);
var _scale = window_get_width()/cam_width;
draw_surface_ext(
	application_surface,
	0 - (frac(x)*_scale),
	0 - (frac(y)*_scale),
	_scale,
	_scale,
	0,
	c_white,
	1.0
);

gpu_set_blendenable(true);