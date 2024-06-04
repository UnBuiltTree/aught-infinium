x_tile_pos = floor(x / CELL_WIDTH);
y_tile_pos = floor(y / CELL_HEIGHT);

floor_state = floor_edge_manager();
wall_state = against_wall_manager();

// Decrement the state duration counter
if (_state_duration > 0) {
    _state_duration--;
}

// Decrement the jump attack cooldown counter
if (_jump_attack_cooldown > 0) {
    _jump_attack_cooldown--;
}

// Only allow state changes if _state_duration is 0
if (_state_duration == 0) {
    switch (floor_state) {
        case "left_edge":
            if (_state != "move_right" && _state != "jump_left") {
                _state = choose("move_right", "jump_left");
            }
            break;
        case "right_edge":
            if (_state != "move_left" && _state != "jump_right") {
                _state = choose("move_left", "jump_right");
            }
            break;
    }

    switch (wall_state) {
        case "left_wall":
            _state = "move_right";
            break;
        case "right_wall":
            _state = "move_left";
            break;
    }
}

// Check for player detection and attack direction if not in cooldown
if (_jump_attack_cooldown == 0) {
    var player_info = combined_player_manager();

    if (player_info.player_seen) {
        _sight_countdown--;

        if (_sight_countdown <= 0) {
            switch (player_info.attack_direction) {
                case "attack_left":
                    if (looking_count > attack_look_trigger) {
                        _state = "jump_attack_left";
                        looking_count = 0;
                    } else {
                        _state = "looking_left";
                        looking_count++;
                    }
                    break;
                case "attack_right":
                    if (looking_count > attack_look_trigger) {
                        _state = "jump_attack_right";
                        looking_count = 0;
                    } else {
                        _state = "looking_right";
                        looking_count++;
                    }
                    break;
            }
        }
    } else {
        _sight_countdown = 60; // Reset sight countdown (adjust as needed)
    }
}

// Check if the enemy is inside the simulation box
var inside_sim_box = inside_sim_box_manager(id, global.simulation_box_x, global.simulation_box_y, global.true_sim_size);

if (inside_sim_box) {
    _grounded = collision_manager("no_bounce");

    switch (_state) {
        case "move_left":
            if (x_speed > -0.5 && _grounded) {
                _xscale = 1;
                x_speed += -0.5;
            }
            break;
        case "move_right":
            if (x_speed < 0.5 && _grounded) {
                _xscale = -1;
                x_speed += 0.5;
            }
            break;
        case "jump_left":
            var jump_check = jump_gap_manager("left");
            //show_debug_message("jump_gap_manager(left)");
            if (jump_check.gap_distance != -1 && jump_check.wall_height <= 2) {
                y_speed = -3 - jump_check.wall_height; // Assuming jump_force is defined elsewhere
                x_speed = -0.75 * jump_check.gap_distance; // Adjust horizontal speed for the jump
                //show_debug_message(string(jump_check.gap_distance));
                _xscale = 1;
                _state = "move_left";
                _state_duration = 60; // Set the duration to 60 steps (or any desired value)
                alarm[0] = 65;
            } else {
                _state = "move_right"; // If no valid jump, move right
            }
            break;
        case "jump_right":
            var jump_check = jump_gap_manager("right");
            //show_debug_message("jump_gap_manager(right)");
            if (jump_check.gap_distance != -1 && jump_check.wall_height <= 2) {
                y_speed = -3 - jump_check.wall_height; // Assuming jump_force is defined elsewhere
                x_speed = 0.75 * jump_check.gap_distance; // Adjust horizontal speed for the jump
                //show_debug_message(string(jump_check.gap_distance));
                _xscale = -1;
                _state = "move_right";
                _state_duration = 60; // Set the duration to 60 steps (or any desired value)
                alarm[0] = 65;
            } else {
                _state = "move_left"; // If no valid jump, move right
            }
            break;
        case "looking_left":
            _xscale = 1;
            break;
        case "looking_right":
            _xscale = -1;
            break;
        case "jump_attack_left":
            if (_grounded) {
                y_speed = -2; // Adjust vertical speed for the jump attack
                x_speed = -3.0; // Adjust horizontal speed for the jump attack
                _xscale = 1;
                _state = "move_left";
                _state_duration = 30; // Duration of the move state after the jump attack
                alarm[0] = 35;
                _jump_attack_cooldown = 100; // Set cooldown duration (adjust as needed)
            }
            break;
        case "jump_attack_right":
            if (_grounded) {
                y_speed = -2; // Adjust vertical speed for the jump attack
                x_speed = 3.0; // Adjust horizontal speed for the jump attack
                _xscale = -1;
                _state = "move_right";
                _state_duration = 30; // Duration of the move state after the jump attack
                alarm[0] = 35;
                _jump_attack_cooldown = 100; // Set cooldown duration (adjust as needed)
            }
            break;
        default:
            // Do nothing
            break;
    }
}
