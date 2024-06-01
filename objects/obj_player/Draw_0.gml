if x_speed > 0.1 {
	var _x = x+(abs(x_speed)/x_speed)*0.5;
} else {
	var _x = x
}

if y_speed > 0.1 {
	var _y = y+(abs(y_speed)/y_speed)*0.5;
} else {
	var _y = y
}

//_x = round_by_units(_x-0.1, 1, "round")
//_y = round_by_units(_y-0.1, 1, "round")



var draw_direction = move_direction;
if (move_direction != 0) {
	draw_direction = move_direction
	last_draw_direction = move_direction;
} else {
	draw_direction = last_draw_direction;
}

if draw_direction = -1 {
	_x = _x - 1.5;
}


if (grounded == 1) {
	if (walking > 0) {
		if (damage_cooldown > 45) {
			draw_sprite_ext(spr_player_walk_dmg, frame, _x, _y, draw_direction, 1, 0, c_white, 1)
		}
	draw_sprite_ext(spr_player_walk, frame, _x, _y, draw_direction, 1, 0, c_white, 1)
		
	} else {
		if (damage_cooldown > 45) {
			draw_sprite_ext(spr_player_dmg, 0, _x, _y, draw_direction, 1, 0, c_white, 1)
		}
	draw_sprite_ext(spr_player, 0, _x, _y, draw_direction, 1, 0, c_white, 1)
	}
} else {
	if (damage_cooldown > 45) {
			draw_sprite_ext(spr_player_fly_dmg, 0, _x, _y, draw_direction, 1, 0, c_white, 1)
		}
	draw_sprite_ext(spr_player_fly, 0, _x, _y, draw_direction, 1, 0, c_white, 1)
}





//draw_line(mouse_x+2, mouse_y,mouse_x-3, mouse_y);
//draw_line(mouse_x, mouse_y+2,mouse_x, mouse_y-3);

draw_sprite_ext(spr_mouse, 0, mouse_x, mouse_y, 1, 1, 0, c_red, 1)
