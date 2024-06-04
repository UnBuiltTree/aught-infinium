current_x = x;
current_y = y;

var rounded_x = round_by_units(current_x, 1, "floor");
var rounded_y = round_by_units(current_y, 1, "floor");
update_cam_pos(global._cam, rounded_x, rounded_y, 0.1);

aim_direction = point_direction(x, y + ycenter_offset, mouse_x, mouse_y);


if (damage_cooldown > 0) { damage_cooldown--; }
health_manager();

/*
if (true_refresh_size < refresh_size) {
    true_refresh_size += 8;
} else {
    true_refresh_size = sim_start_size;
}
*/

// collision_manager(true, false);

// Keyboard movement controls
// Initial checks for each direction
var _up = keyboard_check(ord("W")) || keyboard_check(vk_up) || keyboard_check(vk_space);
var _left = keyboard_check(ord("A")) || keyboard_check(vk_left);
var _right = keyboard_check(ord("D")) || keyboard_check(vk_right);
var _mouse_right = mouse_check_button(mb_right);
var _mouse_left = mouse_check_button(mb_left);
var _picker =  keyboard_check(ord("Q"));
var mouse_x_tile = floor(mouse_x/TILE_WIDTH)*TILE_WIDTH

mouse_over_tile = position_meeting(mouse_x, mouse_y, obj_tile_object);

move_direction = _right - _left;
walking = _right + _left;

// Side movement using acceleration
var acceleration = 0.25; // Adjust this value to control acceleration rate
var deceleration = 0.25; // Adjust this value to control deceleration rate

if (move_direction != 0) {
    if (abs(x_speed) < move_speed) {
        x_speed += move_direction * acceleration;
        if (abs(x_speed) > move_speed) {
            x_speed = move_direction * move_speed;
        }
    }
} else {
    if (x_speed > 0) {
        x_speed -= deceleration;
        if (x_speed < 0) {
            x_speed = 0;
        }
    } else if (x_speed < 0) {
        x_speed += deceleration;
        if (x_speed > 0) {
            x_speed = 0;
        }
    }
}

if (_up) {
    if (y_speed > -fly_speed_max) {
        y_speed += fly_acceleration;
    }
}

grounded = collision_manager("no_bounce");

if (mouse_over_tile && _mouse_right) {
    var tile_ = instance_position(mouse_x, mouse_y, obj_tile_object);
    if (get_tile_index(mouse_x, mouse_y) != VOID) {
        change_boxel_state(-1, VOID, -1, mouse_x, mouse_y);
    }
}

if (!mouse_over_tile && _mouse_left) {
    // Perform actions when the mouse is outside the boundary
    var tile_ = instance_position(mouse_x, mouse_y, obj_tile_object);
    if (get_tile_index(mouse_x, mouse_y) == VOID) {
        change_boxel_state(VOID, placing_tile_id, placing_ore_id, mouse_x, mouse_y);
    }
}

if (mouse_over_tile && _picker) {
    // Perform actions when the mouse is over the tile
    var tile_ = instance_position(mouse_x, mouse_y, obj_tile_object);
    var tile_state = get_tile_state(mouse_x, mouse_y);
    var tile_id = tile_state[0];
    var ore_id = tile_state[1];
    //show_debug_message(tile_id)
    if (tile_id != VOID) {
        placing_tile_id = tile_id;
        placing_ore_id = ore_id; // Store the ore ID
        //show_debug_message("Placing tile ID: " + string(placing_tile_id) + " with ore ID: " + string(placing_ore_id));
    }
}



