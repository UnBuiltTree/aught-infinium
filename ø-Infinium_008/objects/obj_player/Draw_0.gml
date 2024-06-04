
var _x = round(x);
var _y = round(y);


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

var mouse_x_tile = floor(mouse_x/TILE_WIDTH)*TILE_WIDTH
var mouse_y_tile = floor(mouse_y/TILE_HEIGHT)*TILE_HEIGHT

if (mouse_over_tile) {
    draw_set_color(c_black);
    draw_set_alpha(0.25);
    draw_rectangle(mouse_x_tile + TILE_WIDTH - 1, mouse_y_tile + 1, mouse_x_tile, mouse_y_tile + TILE_HEIGHT - 2, true);

    if (global.debug_mode) {
        draw_set_color(c_lime);
        draw_set_alpha(0.75);
        var tile_state = get_tile_state(mouse_x, mouse_y);
        var tile_id = tile_state[0];
        var ore_id = tile_state[1];
        
        var ore_name = "noone";
        if (ore_id != -1) {
            var ore_keys = ds_map_keys_to_array(global.ore_properties);
            for (var i = 0; i < array_length(ore_keys); i++) {
                var key = ore_keys[i];
                var ore = global.ore_properties[? key];
                if (ore[? "ID"] == ore_id) {
                    ore_name = key;
                    break;
                }
            }
        }
		tile_id = (tile_id-984)/40;
        draw_set_font(fnt_debug);
		if (ore_name != "noone"){
			draw_text(mouse_x + 6, mouse_y, "Tile ID: " + string(tile_id) + "\nOre: " + ore_name);
		} else {
			draw_text(mouse_x + 6, mouse_y, "Tile ID: " + string(tile_id));
		}
    }

    draw_set_color(c_white);
    draw_set_alpha(1);
}


