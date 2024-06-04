global._sub_pixel = 0.5;

function collision_manager(_type) {
	grounded = false;
    if (_type == "no_bounce") {
        if (place_meeting(x + x_speed, y, obj_tile_object)) {
            var _pixel_check = global._sub_pixel * sign(x_speed);
            while (!place_meeting(x + _pixel_check, y, obj_tile_object)) {
                x += _pixel_check;
            }
            x_speed = 0;
        }
        x += x_speed;
        y_speed += grav;

        if (y_speed > term_velocity) {
            y_speed = term_velocity;
        }

        if (place_meeting(x, y + y_speed, obj_tile_object)) {
            var _pixel_check = global._sub_pixel * sign(y_speed);
            while (!place_meeting(x, y + _pixel_check, obj_tile_object)) {
                y += _pixel_check;
            }
            y_speed = 0;
			grounded = true;
        }
        y += y_speed;
		
		if grounded {
			if x_speed > 0.2 {
			x_speed -= 0.1
			} else if (x_speed < -0.2) {
				x_speed += 0.1
			} else {
				x_speed = 0;
			}
			
		}
    }
	return grounded
}

///@func    floor_edge_manager()
///@desc    Returns in_air, on_floor, left_edge or, right_edge as a string.
function floor_edge_manager() {
    // Bottom left and right corners based on bottom center origin
    var left_bottom_x = x - (sprite_width / 2);
    var right_bottom_x = x + (sprite_width / 2);
    var center_bottom_x = x;
    var bottom_y = y+1;

    var left_bottom_check = place_meeting(left_bottom_x, bottom_y, obj_tile_object);
    var right_bottom_check = place_meeting(right_bottom_x, bottom_y, obj_tile_object);
    var center_bottom_check = place_meeting(center_bottom_x, bottom_y, obj_tile_object);

    if (!left_bottom_check && !right_bottom_check && !center_bottom_check) {
        return "in_air";
    } else if (left_bottom_check && right_bottom_check && center_bottom_check) {
        return "on_floor";
    } else if (!left_bottom_check && (center_bottom_check || right_bottom_check)) {
        return "left_edge";
    } else if (!right_bottom_check && (center_bottom_check || left_bottom_check)) {
        return "right_edge";
    } else {
        return "in_air"; // Default to in_air if other checks are ambiguous
    }
}

/// @func    against_wall_manager()
/// @desc    Returns left_wall, right_wall, or no_wall as a string.
function against_wall_manager() {
    // Bottom left and right corners based on bottom center origin
    var left_bottom_x = x - (sprite_width / 2);
    var right_bottom_x = x + (sprite_width / 2);
    var check_y = y - 1;

    var left_wall_check = place_meeting(left_bottom_x + 4, check_y, obj_tile_object);
    var right_wall_check = place_meeting(right_bottom_x - 4, check_y, obj_tile_object);

    if (left_wall_check) {
        return "left_wall";
    } else if (right_wall_check) {
        return "right_wall";
    } else {
        return "no_wall";
    }
}

/// @func    jump_gap_manager(_direction)
/// @desc    Checks for gaps in the specified direction and the height of the wall. Returns gap distance and wall height if valid for a jump.
function jump_gap_manager(_direction) {
    var check_x, check_y;
    var max_iterations = 4;
    var max_wall_height = 3; // Number of cells to check above the tile_object
    var gap_distance = -1;
    var wall_height = -1;

    for (var i = 1; i <= max_iterations; i++) {
        if (_direction == "left") {
            check_x = x - (sprite_width / 2) - (i * CELL_WIDTH);
        } else if (_direction == "right") {
            check_x = x + (sprite_width / 2) + (i * CELL_WIDTH);
        } 
        check_y = y + 1;

        if (place_meeting(check_x, check_y, obj_tile_object)) {
            gap_distance = i;

            wall_height = 0;
            for (var j = 1; j <= max_wall_height; j++) {
                if (place_meeting(check_x, check_y - (j * CELL_HEIGHT), obj_tile_object)) {
                    wall_height = j;
                    break;
                }
            }

            if (wall_height <= 2) {
                return {gap_distance: gap_distance, wall_height: wall_height};
            } 
        }
    }
    return {gap_distance: -1, wall_height: -1}; // No valid jump found
}
	
/// @func    player_detection_manager()
/// @desc    Returns true/false if the entity can see the player and the player's x and y position.
function player_detection_manager() {
    var player_x = obj_player.x;
    var player_y = obj_player.y;
    var sightline_value = 64; // Adjust this value as needed

    var x_diff = abs(x - player_x);
    var y_diff = abs(y - player_y);

    if (x_diff < sightline_value && y_diff < sightline_value) {
		//show_debug_message("checking sightline")
        // Check if there's a direct line of sight to the player
        if (!collision_line(x, y-2, player_x, player_y-2, obj_tile_object, true, true)) {
			//show_debug_message("sightline is true")
            return {seen: true, player_x: player_x, player_y: player_y};
        }
    }
    return {seen: false, player_x: -1, player_y: -1};
}
	
/// @func    attack_player_manager(player_position)
/// @desc    Determines if the player is to the left or right of the entity and returns 'attack_left' or 'attack_right'.
/// @param   player_position   The player's position as a struct with x and y properties.
function attack_player_manager(player_position) {
    var player_x = player_position.player_x;
    
    if (player_x < x) {
        return "attack_left";
    } else if (player_x > x) {
        return "attack_right";
    } else {
        return "attack_none"; // Player is directly above or below
    }
}

/// @func    combined_player_manager()
/// @desc    Uses player_detection_manager and attack_player_manager to return player_seen and attack_direction.
/// @return  A struct with player_seen (true/false) and attack_direction (-1, "attack_left", "attack_right").
function combined_player_manager() {
    var detection = player_detection_manager();
    var player_seen = detection.seen;
    var attack_direction = 0; // Default value

    if (player_seen) {
        attack_direction = attack_player_manager({player_x: detection.player_x, player_y: detection.player_y});
    }

    return {player_seen: player_seen, attack_direction: attack_direction};
}

