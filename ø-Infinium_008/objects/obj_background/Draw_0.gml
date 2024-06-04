var cam_x = global._cam.x;
var cam_y = global._cam.y;

// Calculate the parallax offset (quarter speed of the camera)
// Adjust for the initial camera position at the center of the room
var parallax_x = (cam_x - room_width / 2) * 1;
var parallax_y = (cam_y - room_height / 2) * 1;

draw_sprite_tiled_ext(spr_background, 3, room_width / 2 + parallax_x, room_height / 2 + parallax_y, 8, 8, c_white, 1)


parallax_x = (cam_x - room_width / 2) * 0.5;
parallax_y = (cam_y - room_height / 2) * 0.5;

draw_sprite_tiled_ext(spr_background, 2, room_width / 2 + parallax_x, room_height / 2 + parallax_y, 4, 4, c_white, 1)

parallax_x = (cam_x - room_width / 2) * 0.25;
parallax_y = (cam_y - room_height / 2) * 0.25;

draw_sprite_tiled_ext(spr_background, 1, room_width / 2 + parallax_x, room_height / 2 + parallax_y, 3, 3, c_white, 1)

parallax_x = (cam_x - room_width / 2) * 0.125;
parallax_y = (cam_y - room_height / 2) * 0.125;

draw_sprite_tiled_ext(spr_background, 0, room_width / 2 + parallax_x, room_height / 2 + parallax_y, 2, 2, c_white, 1)
