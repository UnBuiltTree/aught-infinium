function sim_space(_x, _y, _size, _scarce_mode, _border_size, _rate = 2) {
    var half_tile_width = TILE_WIDTH / 2;
    var half_tile_height = TILE_HEIGHT / 2;
	
    

    // Calculate the half-tile size positions
    var half_tile_x = floor(_x / half_tile_width) * half_tile_width;
    var half_tile_y = floor(_y / half_tile_height) * half_tile_height;
    
   

    // Calculate the boundaries of the simulation box
    var _box_left = half_tile_x - _size;
    var _box_right = half_tile_x + _size;
    var _box_top = half_tile_y - _size;
    var _box_bottom = half_tile_y + _size;

    // Convert box boundaries to tile indices
    var tile_left = floor(_box_left / TILE_WIDTH);
    var tile_right = floor(_box_right / TILE_WIDTH);
    var tile_top = floor(_box_top / TILE_HEIGHT);
    var tile_bottom = floor(_box_bottom / TILE_HEIGHT);

    // Ensure global.x_scan_pos is within bounds
    if (global.x_scan_pos < tile_left || global.x_scan_pos > tile_right) {
        global.x_scan_pos = tile_left;
    }

    // Call the refresh_scan function to sweep from left to right and update boxels
    refresh_scan(_x, _y, _size, _rate);

    if (_scarce_mode) {
        // Check if the position has changed
        if (half_tile_x == global.last_sim_x && half_tile_y == global.last_sim_y) {
            return; // Exit if the position hasn't changed
        }
    }

    // Update the last checked position
    global.last_sim_x = half_tile_x;
    global.last_sim_y = half_tile_y;

    // Calculate the boundaries of the inner box (one tile smaller)
    var _inner_box_left = _box_left + TILE_WIDTH;
    var _inner_box_right = _box_right - TILE_WIDTH;
    var _inner_box_top = _box_top + TILE_HEIGHT;
    var _inner_box_bottom = _box_bottom - TILE_HEIGHT;

    // Calculate the boundaries of the outer box (one tile larger)
    var _outer_box_left = _box_left - TILE_WIDTH*_border_size;
    var _outer_box_right = _box_right + TILE_WIDTH*_border_size;
    var _outer_box_top = _box_top - TILE_HEIGHT*_border_size;
    var _outer_box_bottom = _box_bottom + TILE_HEIGHT*_border_size;

    // Convert inner box boundaries to tile indices
    var inner_tile_left = floor(_inner_box_left / TILE_WIDTH);
    var inner_tile_right = floor(_inner_box_right / TILE_WIDTH);
    var inner_tile_top = floor(_inner_box_top / TILE_HEIGHT);
    var inner_tile_bottom = floor(_inner_box_bottom / TILE_HEIGHT);

    // Convert outer box boundaries to tile indices
    var outer_tile_left = floor(_outer_box_left / TILE_WIDTH);
    var outer_tile_right = floor(_outer_box_right / TILE_WIDTH);
    var outer_tile_top = floor(_outer_box_top / TILE_HEIGHT);
    var outer_tile_bottom = floor(_outer_box_bottom / TILE_HEIGHT);

    // First, delete any obj_tile_object instances in the outer box but outside the main box
    for (var tile_x = outer_tile_left; tile_x <= outer_tile_right; tile_x++) {
        for (var tile_y = outer_tile_top; tile_y <= outer_tile_bottom; tile_y++) {
            // Only consider tiles that are in the outer box border
            if (tile_x < tile_left || tile_x > tile_right || tile_y < tile_top || tile_y > tile_bottom) {
                var obj_x = tile_x * TILE_WIDTH;
                var obj_y = tile_y * TILE_HEIGHT;

                // Check if there is an obj_tile_object at this position
                if (ds_map_exists(global.active_tiles, string(obj_x) + "_" + string(obj_y))) {
                    deactivate_boxel(obj_x, obj_y);
                }
            }
        }
    }

    // Iterate over all tiles in the main box but outside the inner box
    for (var tile_x = tile_left; tile_x <= tile_right; tile_x++) {
        for (var tile_y = tile_top; tile_y <= tile_bottom; tile_y++) {
            // Ignore tiles inside the inner box
            if (tile_x > inner_tile_left && tile_x < inner_tile_right && tile_y > inner_tile_top && tile_y < inner_tile_bottom) {
                continue;
            }

            var chunk_x = floor(tile_x / CHUNK_SIZE_X);
            var chunk_y = floor(tile_y / CHUNK_SIZE_Y);
            var chunk_key = string(chunk_x) + "_" + string(chunk_y);

            if (ds_map_exists(global.chunks, chunk_key)) {
                var grid = ds_map_find_value(global.chunks, chunk_key);
                var local_tile_x = tile_x % CHUNK_SIZE_X;
                var local_tile_y = tile_y % CHUNK_SIZE_Y;

                // Ensure local indices are positive
                if (local_tile_x < 0) local_tile_x += CHUNK_SIZE_X;
                if (local_tile_y < 0) local_tile_y += CHUNK_SIZE_Y;

                // Check if the local indices are within bounds
                if (local_tile_x >= 0 && local_tile_x < CHUNK_SIZE_X && local_tile_y >= 0 && local_tile_y < CHUNK_SIZE_Y) {
                    var tile = ds_grid_get(grid, local_tile_x, local_tile_y);

                    // Process only non-VOID tiles
                    if (tile != VOID) {
                        // Check if the tile has a VOID neighbor
                        var is_surface = false;
                        for (var offset_x = -1; offset_x <= 1; offset_x++) {
                            for (var offset_y = -1; offset_y <= 1; offset_y++) {
                                if (offset_x == 0 && offset_y == 0) continue;

                                var neighbor_x = local_tile_x + offset_x;
                                var neighbor_y = local_tile_y + offset_y;
                                var neighbor_chunk_x = chunk_x;
                                var neighbor_chunk_y = chunk_y;

                                // Check if neighbor is outside the current chunk
                                if (neighbor_x < 0) {
                                    neighbor_x += CHUNK_SIZE_X;
                                    neighbor_chunk_x -= 1;
                                } else if (neighbor_x >= CHUNK_SIZE_X) {
                                    neighbor_x -= CHUNK_SIZE_X;
                                    neighbor_chunk_x += 1;
                                }
                                if (neighbor_y < 0) {
                                    neighbor_y += CHUNK_SIZE_Y;
                                    neighbor_chunk_y -= 1;
                                } else if (neighbor_y >= CHUNK_SIZE_Y) {
                                    neighbor_y -= CHUNK_SIZE_Y;
                                    neighbor_chunk_y += 1;
                                }

                                var neighbor_chunk_key = string(neighbor_chunk_x) + "_" + string(neighbor_chunk_y);
                                if (ds_map_exists(global.chunks, neighbor_chunk_key)) {
                                    var neighbor_grid = ds_map_find_value(global.chunks, neighbor_chunk_key);
                                    if (ds_grid_get(neighbor_grid, neighbor_x, neighbor_y) == VOID) {
                                        is_surface = true;
                                        break;
                                    }
                                } else {
                                    is_surface = true;
                                    break;
                                }
                            }
                            if (is_surface) break;
                        }

                        if (is_surface) {
                            var obj_x = tile_x * TILE_WIDTH;
                            var obj_y = tile_y * TILE_HEIGHT;

                            // Use the helper function to create an active boxel
                            create_active_boxel(obj_x, obj_y);
                        }
                    }
                }
            }
        }
    }
}

function refresh_scan(_x, _y, _size, _rate) {
    var half_tile_width = TILE_WIDTH / 2;
    var half_tile_height = TILE_HEIGHT / 2;

    // Calculate the half-tile size positions
    var half_tile_x = floor(_x / half_tile_width) * half_tile_width;
    var half_tile_y = floor(_y / half_tile_height) * half_tile_height;

    // Calculate the boundaries of the simulation box
    var _box_left = half_tile_x - _size;
    var _box_right = half_tile_x + _size;
    var _box_top = half_tile_y - _size;
    var _box_bottom = half_tile_y + _size;

    // Convert box boundaries to tile indices
    var tile_left = floor(_box_left / TILE_WIDTH);
    var tile_right = floor(_box_right / TILE_WIDTH);
    var tile_top = floor(_box_top / TILE_HEIGHT);
    var tile_bottom = floor(_box_bottom / TILE_HEIGHT);

    // Ensure global.x_scan_pos is within bounds
    if (global.x_scan_pos < tile_left || global.x_scan_pos > tile_right) {
        global.x_scan_pos = tile_left;
    }

    // Only refresh on new x values
    if (global.x_scan_pos != global.last_scan_x) {
        // Scan one column of y tiles at the current scan position
        var tile_x = global.x_scan_pos;
        for (var tile_y = tile_top; tile_y <= tile_bottom; tile_y++) {
            var chunk_x = floor(tile_x / CHUNK_SIZE_X);
            var chunk_y = floor(tile_y / CHUNK_SIZE_Y);
            var chunk_key = string(chunk_x) + "_" + string(chunk_y);

            if (ds_map_exists(global.chunks, chunk_key)) {
                var grid = ds_map_find_value(global.chunks, chunk_key);
                var local_tile_x = tile_x % CHUNK_SIZE_X;
                var local_tile_y = tile_y % CHUNK_SIZE_X;

                // Ensure local indices are positive
                if (local_tile_x < 0) local_tile_x += CHUNK_SIZE_X;
                if (local_tile_y < 0) local_tile_y += CHUNK_SIZE_Y;

                // Check if the local indices are within bounds
                if (local_tile_x >= 0 && local_tile_x < CHUNK_SIZE_X && local_tile_y >= 0 && local_tile_y < CHUNK_SIZE_Y) {
                    var tile = ds_grid_get(grid, local_tile_x, local_tile_y);

                    if (tile != VOID) {
                        var has_void_neighbor = false;

                        // Check 4 primary neighbors for VOID tiles
                        var offsets = [
                            [0, -1], // up
                            [0, 1],  // down
                            [-1, 0], // left
                            [1, 0]   // right
                        ];

                        for (var i = 0; i < array_length(offsets); i++) {
                            var offset_x = offsets[i][0];
                            var offset_y = offsets[i][1];

                            var neighbor_x = local_tile_x + offset_x;
                            var neighbor_y = local_tile_y + offset_y;
                            var neighbor_chunk_x = chunk_x;
                            var neighbor_chunk_y = chunk_y;

                            // Check if neighbor is outside the current chunk
                            if (neighbor_x < 0) {
                                neighbor_x += CHUNK_SIZE_X;
                                neighbor_chunk_x -= 1;
                            } else if (neighbor_x >= CHUNK_SIZE_X) {
                                neighbor_x -= CHUNK_SIZE_X;
                                neighbor_chunk_x += 1;
                            }
                            if (neighbor_y < 0) {
                                neighbor_y += CHUNK_SIZE_Y;
                                neighbor_chunk_y -= 1;
                            } else if (neighbor_y >= CHUNK_SIZE_Y) {
                                neighbor_y -= CHUNK_SIZE_Y;
                                neighbor_chunk_y += 1;
                            }

                            var neighbor_chunk_key = string(neighbor_chunk_x) + "_" + string(neighbor_chunk_y);
                            if (ds_map_exists(global.chunks, neighbor_chunk_key)) {
                                var neighbor_grid = ds_map_find_value(global.chunks, neighbor_chunk_key);
                                if (ds_grid_get(neighbor_grid, neighbor_x, neighbor_y) == VOID) {
                                    has_void_neighbor = true;
                                    break;
                                }
                            } else {
                                has_void_neighbor = true;
                                break;
                            }
                        }

                        var obj_x = tile_x * TILE_WIDTH;
                        var obj_y = tile_y * TILE_HEIGHT;

                        if (!has_void_neighbor) {
                            deactivate_boxel(obj_x, obj_y);
                        } else {
                            create_active_boxel(obj_x, obj_y);
                        }
                    }
                }
            }
        }

        // Update last scan position
        global.last_scan_x = global.x_scan_pos;
    }

    // Increment the rate count
    global.rate_count += 1;

    // Increment the scan position by 1 tile every _rate steps
    if (global.rate_count >= _rate) {
        global.x_scan_pos += 1;
        global.rate_count = 0;

        if (global.x_scan_pos > tile_right) {
            global.x_scan_pos = tile_left;
        }
    }
}



function solid_sim_space(_x, _y, _size) {
    var half_tile_width = TILE_WIDTH / 2;
    var half_tile_height = TILE_HEIGHT / 2;

    // Calculate the half-tile size positions
    var half_tile_x = floor(_x / half_tile_width) * half_tile_width;
    var half_tile_y = floor(_y / half_tile_height) * half_tile_height;

    // Calculate the boundaries of the solid sim space
    var _box_left = half_tile_x - _size;
    var _box_right = half_tile_x + _size;
    var _box_top = half_tile_y - _size;
    var _box_bottom = half_tile_y + _size;

    // Convert box boundaries to tile indices
    var tile_left = floor(_box_left / TILE_WIDTH);
    var tile_right = floor(_box_right / TILE_WIDTH);
    var tile_top = floor(_box_top / TILE_HEIGHT);
    var tile_bottom = floor(_box_bottom / TILE_HEIGHT);

    // Iterate over all tiles in the solid sim space
    for (var tile_x = tile_left; tile_x <= tile_right; tile_x++) {
        for (var tile_y = tile_top; tile_y <= tile_bottom; tile_y++) {
            var chunk_x = floor(tile_x / CHUNK_SIZE_X);
            var chunk_y = floor(tile_y / CHUNK_SIZE_Y);
            var chunk_key = string(chunk_x) + "_" + string(chunk_y);

            if (ds_map_exists(global.chunks, chunk_key)) {
                var grid = ds_map_find_value(global.chunks, chunk_key);
                var local_tile_x = tile_x % CHUNK_SIZE_X;
                var local_tile_y = tile_y % CHUNK_SIZE_Y;

                // Ensure local indices are positive
                if (local_tile_x < 0) local_tile_x += CHUNK_SIZE_X;
                if (local_tile_y < 0) local_tile_y += CHUNK_SIZE_Y;

                // Check if the local indices are within bounds
                if (local_tile_x >= 0 && local_tile_x < CHUNK_SIZE_X && local_tile_y >= 0 && local_tile_y < CHUNK_SIZE_Y) {
                    var tile = ds_grid_get(grid, local_tile_x, local_tile_y);

                    var obj_x = tile_x * TILE_WIDTH;
                    var obj_y = tile_y * TILE_HEIGHT;

                    // Process non-VOID tiles to create active boxels
                    if (tile != VOID) {
                        create_active_boxel(obj_x, obj_y);
                    } else {
                        // Deactivate boxel if it is a VOID tile
                        deactivate_boxel(obj_x, obj_y);
                    }
                }
            }
        }
    }
}

function draw_sim_space(_x, _y, _size, _scarce_mode, border_size) {
    var half_tile_width = TILE_WIDTH / 2;
    var half_tile_height = TILE_HEIGHT / 2;
    var half_tile_x = floor(_x / half_tile_width) * half_tile_width;
    var half_tile_y = floor(_y / half_tile_height) * half_tile_height;

    // Calculate the boundaries of the simulation box
    var _box_left = half_tile_x - _size;
    var _box_right = half_tile_x + _size;
    var _box_top = half_tile_y - _size;
    var _box_bottom = half_tile_y + _size;

    // Calculate the boundaries of the inner box (one tile smaller)
    var _inner_box_left = _box_left + TILE_WIDTH;
    var _inner_box_right = _box_right - TILE_WIDTH;
    var _inner_box_top = _box_top + TILE_HEIGHT;
    var _inner_box_bottom = _box_bottom - TILE_HEIGHT;

    // Calculate the boundaries of the outer box (one tile larger)
    var _outer_box_left = _box_left - TILE_WIDTH*border_size;
    var _outer_box_right = _box_right + TILE_WIDTH*border_size;
    var _outer_box_top = _box_top - TILE_HEIGHT*border_size;
    var _outer_box_bottom = _box_bottom + TILE_HEIGHT*border_size;

    // Set colors for different boxes
    var color_outer_box = c_red;
    var color_main_box = c_blue;
    var color_inner_box = c_green;

    // Draw the outer box
    draw_set_color(color_outer_box);
    draw_rectangle(_outer_box_left, _outer_box_top, _outer_box_right, _outer_box_bottom, true);

    // Draw the main box
    draw_set_color(color_main_box);
    draw_rectangle(_box_left, _box_top, _box_right, _box_bottom, true);

    // Draw the inner box
    draw_set_color(color_inner_box);
    draw_rectangle(_inner_box_left, _inner_box_top, _inner_box_right, _inner_box_bottom, true);

    if (!_scarce_mode) {
        draw_set_alpha(0.25);
        draw_set_color(color_outer_box);
        draw_rectangle(_outer_box_left, _outer_box_top, _outer_box_right, _outer_box_bottom, false);
        draw_set_alpha(1);
    }

    // Draw the scan line
    draw_set_color(c_fuchsia);
	draw_set_alpha(0.25);
    var scan_line_x = global.x_scan_pos * TILE_WIDTH;
    //draw_line(scan_line_x, _box_top, scan_line_x, _box_bottom);
	draw_rectangle(scan_line_x+2, _box_top, scan_line_x+5, _box_bottom, false);
	draw_set_alpha(1);
    draw_set_color(c_white);
}
