// Helper function to create an active boxel
function create_active_boxel(_x, _y) {
    var key = string(_x) + "_" + string(_y);
    if (!ds_map_exists(global.active_tiles, key)) {
        var tile_object = instance_create_layer(_x, _y, "Instances", obj_tile_object);
        ds_map_add(global.active_tiles, key, tile_object);
    }
}

// Helper function to deactivate a boxel
function deactivate_boxel(_x, _y) {
    var key = string(_x) + "_" + string(_y);
    if (ds_map_exists(global.active_tiles, key)) {
        var tile_object = ds_map_find_value(global.active_tiles, key);
        if (tile_object != noone) {
            with (tile_object) {
                instance_destroy();
            }
        }
        ds_map_delete(global.active_tiles, key);
    }
}

function change_boxel(current_boxel, change_to_boxel, x_pos, y_pos) {
    // Default change_to_boxel to VOID if not provided
    if (change_to_boxel == -1) {
        change_to_boxel = VOID;
    }

    // Get the current tile state at the specified position
    var tile_state = get_tile_state(x_pos, y_pos);
    var current_tile = tile_state[0];
    var ore = tile_state[1];

    // If the current tile matches current_boxel or if current_boxel is -1, proceed with the change
    if (current_boxel == -1 || current_tile == current_boxel) {
        // Convert real-world coordinates to tile coordinates
        var tile_x = floor(x_pos / TILE_WIDTH);
        var tile_y = floor(y_pos / TILE_HEIGHT);

        // Calculate chunk coordinates
        var chunk_x = floor(tile_x / CHUNK_SIZE_X);
        var chunk_y = floor(tile_y / CHUNK_SIZE_Y);
        var chunk_key = string(chunk_x) + "_" + string(chunk_y);

        // Ensure the chunk exists
        if (!ds_map_exists(global.chunks, chunk_key)) {
            show_debug_message("Chunk does not exist: " + chunk_key);
            return;
        }

        var grid = ds_map_find_value(global.chunks, chunk_key);
        var local_tile_x = tile_x % CHUNK_SIZE_X;
        var local_tile_y = tile_y % CHUNK_SIZE_Y;

        // Ensure local indices are positive
        if (local_tile_x < 0) local_tile_x += CHUNK_SIZE_X;
        if (local_tile_y < 0) local_tile_y += CHUNK_SIZE_Y;

        var tilemap_id = ds_map_find_value(global.chunk_tilemaps, chunk_key);

        // Function to check if an entity exists at a given position
        function entity_exists_at_position(_x, _y) {
            return instance_position(_x, _y, obj_enemy) != noone || instance_position(_x, _y, obj_player) != noone;
        }

        // Check the four corners of the voxel for entities
        var entity_in_voxel = entity_exists_at_position(x_pos, y_pos) ||
                              entity_exists_at_position(x_pos + TILE_WIDTH, y_pos) ||
                              entity_exists_at_position(x_pos, y_pos + TILE_HEIGHT) ||
                              entity_exists_at_position(x_pos + TILE_WIDTH, y_pos + TILE_HEIGHT);

        // If no entities are found in the voxel, proceed with the changes
        if (!entity_in_voxel) {
            // Update the grid with the new tile type
            ds_grid_set(grid, local_tile_x, local_tile_y, change_to_boxel);
            tilemap_set(tilemap_id, texturize_tile(change_to_boxel, tile_x, tile_y), local_tile_x, local_tile_y);

            // Remove ore if present
            if (ore != undefined) {
                var ore_list = ds_map_find_value(global.ore_lists, chunk_key);
                for (var i = 0; i < ds_list_size(ore_list); i++) {
                    var ore_entry = ds_list_find_value(ore_list, i);
                    if (ore_entry[0] == local_tile_x && ore_entry[1] == local_tile_y) {
                        ds_list_delete(ore_list, i);
                        break;
                    }
                }
            }

            // If setting the tile to VOID, handle accordingly
            if (change_to_boxel == VOID) {
                // Deactivate the boxel
                deactivate_boxel(x_pos, y_pos);
            }
            
            // Flag the chunk as changed
            ds_map_add(global.changed_chunks, chunk_key, grid);

            // Process the area where the tile was set
            solid_sim_space(x_pos, y_pos, TILE_WIDTH * 1);

            // Update auto tile textures (implement this function if needed)
            // update_auto_tile_textures(grid, local_tile_x, local_tile_y, tilemap_id);
        }
    }
}
	
function change_boxel_state(current_boxel, change_to_boxel, change_to_ore, x_pos, y_pos) {
    // Default change_to_boxel to VOID if not provided
    if (change_to_boxel == -1) {
        change_to_boxel = VOID;
    }

    // Get the current tile state at the specified position
    var tile_state = get_tile_state(x_pos, y_pos);
    var current_tile = tile_state[0];
    var current_ore = tile_state[1];

    // If the current tile matches current_boxel or if current_boxel is -1, proceed with the change
    if (current_boxel == -1 || current_tile == current_boxel) {
        // Convert real-world coordinates to tile coordinates
        var tile_x = floor(x_pos / TILE_WIDTH);
        var tile_y = floor(y_pos / TILE_HEIGHT);

        // Calculate chunk coordinates
        var chunk_x = floor(tile_x / CHUNK_SIZE_X);
        var chunk_y = floor(tile_y / CHUNK_SIZE_Y);
        var chunk_key = string(chunk_x) + "_" + string(chunk_y);

        // Ensure the chunk exists
        if (!ds_map_exists(global.chunks, chunk_key)) {
            show_debug_message("Chunk does not exist: " + chunk_key);
            return;
        }

        var grid = ds_map_find_value(global.chunks, chunk_key);
        var local_tile_x = tile_x % CHUNK_SIZE_X;
        var local_tile_y = tile_y % CHUNK_SIZE_Y;

        // Ensure local indices are positive
        if (local_tile_x < 0) local_tile_x += CHUNK_SIZE_X;
        if (local_tile_y < 0) local_tile_y += CHUNK_SIZE_Y;

        var tilemap_id = ds_map_find_value(global.chunk_tilemaps, chunk_key);

        // Function to check if an entity exists at a given position
        function entity_exists_at_position(_x, _y) {
            return instance_position(_x, _y, obj_enemy) != noone || instance_position(_x, _y, obj_player) != noone;
        }

        // Check the four corners of the voxel for entities
        var entity_in_voxel = entity_exists_at_position(x_pos, y_pos) ||
                              entity_exists_at_position(x_pos + TILE_WIDTH, y_pos) ||
                              entity_exists_at_position(x_pos, y_pos + TILE_HEIGHT) ||
                              entity_exists_at_position(x_pos + TILE_WIDTH, y_pos + TILE_HEIGHT);

        // If no entities are found in the voxel, proceed with the changes
        if (!entity_in_voxel) {
            // Update the grid with the new tile type
            ds_grid_set(grid, local_tile_x, local_tile_y, change_to_boxel);
            tilemap_set(tilemap_id, texturize_tile(change_to_boxel, tile_x, tile_y), local_tile_x, local_tile_y);

            // Handle ore changes
            var ore_list = ds_map_find_value(global.ore_lists, chunk_key);
            var ore_changed = false;

            if (change_to_ore != -1) { // If ore change is specified
                // Check if ore already exists and update it
                for (var i = 0; i < ds_list_size(ore_list); i++) {
                    var ore_entry = ds_list_find_value(ore_list, i);
                    if (ore_entry[0] == local_tile_x && ore_entry[1] == local_tile_y) {
                        ds_list_replace(ore_list, i, [local_tile_x, local_tile_y, change_to_ore]);
                        ore_changed = true;
                        break;
                    }
                }

                // If ore does not exist, add it
                if (!ore_changed) {
                    ds_list_add(ore_list, [local_tile_x, local_tile_y, change_to_ore]);
                }
            } else { // If ore change is not specified, remove ore
                for (var i = 0; i < ds_list_size(ore_list); i++) {
                    var ore_entry = ds_list_find_value(ore_list, i);
                    if (ore_entry[0] == local_tile_x && ore_entry[1] == local_tile_y) {
                        ds_list_delete(ore_list, i);
                        break;
                    }
                }
            }

            // If setting the tile to VOID, handle accordingly
            if (change_to_boxel == VOID) {
                // Deactivate the boxel
                deactivate_boxel(x_pos, y_pos);
            }
            
            // Flag the chunk as changed
            ds_map_add(global.changed_chunks, chunk_key, grid);
			
			var chunk_x = floor(tile_x / CHUNK_SIZE_X);
		    var chunk_y = floor(tile_y / CHUNK_SIZE_Y);
		    obj_level.update_chunk_vertex_buffer(chunk_x, chunk_y);

            // Process the area where the tile was set
            solid_sim_space(x_pos, y_pos, TILE_WIDTH * 1);

            // Update auto tile textures (implement this function if needed)
            // update_auto_tile_textures(grid, local_tile_x, local_tile_y, tilemap_id);
        }
    }
}
	
function get_tile_index(x_pos, y_pos) {
    // Convert real-world coordinates to tile coordinates
    var tile_x = floor(x_pos / TILE_WIDTH);
    var tile_y = floor(y_pos / TILE_HEIGHT);

    // Calculate chunk coordinates
    var chunk_x = floor(tile_x / CHUNK_SIZE_X);
    var chunk_y = floor(tile_y / CHUNK_SIZE_Y);
    var chunk_key = string(chunk_x) + "_" + string(chunk_y);

    // Ensure the chunk exists
    if (!ds_map_exists(global.chunks, chunk_key)) {
        show_debug_message("Chunk does not exist: " + chunk_key);
        return undefined;
    }

    var grid = ds_map_find_value(global.chunks, chunk_key);
    var local_tile_x = tile_x % CHUNK_SIZE_X;
    var local_tile_y = tile_y % CHUNK_SIZE_Y;

    // Ensure local indices are positive
    if (local_tile_x < 0) local_tile_x += CHUNK_SIZE_X;
    if (local_tile_y < 0) local_tile_y += CHUNK_SIZE_Y;

    // Retrieve and return the tile value from the grid
    return ds_grid_get(grid, local_tile_x, local_tile_y);
}	
	
function get_tile_state(x_pos, y_pos) {
    // Convert real-world coordinates to tile coordinates
    var tile_x = floor(x_pos / TILE_WIDTH);
    var tile_y = floor(y_pos / TILE_HEIGHT);

    // Calculate chunk coordinates
    var chunk_x = floor(tile_x / CHUNK_SIZE_X);
    var chunk_y = floor(tile_y / CHUNK_SIZE_Y);
    var chunk_key = string(chunk_x) + "_" + string(chunk_y);

    // Ensure the chunk exists
    if (!ds_map_exists(global.chunks, chunk_key)) {
        show_debug_message("Chunk does not exist: " + chunk_key);
        return undefined;
    }

    var grid = ds_map_find_value(global.chunks, chunk_key);
    var local_tile_x = tile_x % CHUNK_SIZE_X;
    var local_tile_y = tile_y % CHUNK_SIZE_Y;

    // Ensure local indices are positive
    if (local_tile_x < 0) local_tile_x += CHUNK_SIZE_X;
    if (local_tile_y < 0) local_tile_y += CHUNK_SIZE_Y;

    // Retrieve the base tile value from the grid
    var base_tile = ds_grid_get(grid, local_tile_x, local_tile_y);

    // Check for ore in the ore list
    var ore_list = ds_map_find_value(global.ore_lists, chunk_key);
    var ore = -1;
    for (var i = 0; i < ds_list_size(ore_list); i++) {
        var ore_entry = ds_list_find_value(ore_list, i);
        if (ore_entry[0] == local_tile_x && ore_entry[1] == local_tile_y) {
            ore = ore_entry[2];
            break;
        }
    }

    return [base_tile, ore];
}

function texturize_tile(tile, _x, _y){
    var variant_count;
    var noise_value;

    switch (tile) {
        case DIRT:
            variant_count = ds_map_find_value(global.tile_variants, DIRT);
            noise_value = chaos_noise(global.perm_tex, _x, _y);
            tile = DIRT + 1 + floor((noise_value + 1) * 0.5 * variant_count);
            break;
        case STONE:
            variant_count = ds_map_find_value(global.tile_variants, STONE);
            noise_value = chaos_noise(global.perm_tex, _x, _y);
            tile = STONE +1+ floor((noise_value + 1) * 0.5 * variant_count);
            break;
        case STONE2:
            variant_count = ds_map_find_value(global.tile_variants, STONE2);
            noise_value = chaos_noise(global.perm_tex, _x, _y);
            tile = STONE2 +1+ floor((noise_value + 1) * 0.5 * variant_count);
            break;
        case METAL:
            variant_count = ds_map_find_value(global.tile_variants, METAL);
            noise_value = chaos_noise(global.perm_tex, _x, _y);
            tile = METAL +1+ floor((noise_value + 1) * 0.5 * variant_count);
            break;
        case GRASS:
            variant_count = ds_map_find_value(global.tile_variants, GRASS);
            noise_value = chaos_noise(global.perm_tex, _x, _y);
            tile = GRASS +1+ floor((noise_value + 1) * 0.5 * variant_count);
            break;
        case BORDER:
            variant_count = ds_map_find_value(global.tile_variants, BORDER);
            noise_value = chaos_noise(global.perm_tex, _x, _y);
            tile = BORDER +1+ floor((noise_value + 1) * 0.5 * variant_count);
            break;
        case VOID:
            tile = VOID;
            break;
    }
    return tile;
}
	
/// @function draw_ore_sprite(ore_type, tile_x, tile_y)
/// @param {string} ore_type The type of ore (e.g., "iron")
/// @param {real} tile_x The x coordinate of the tile
/// @param {real} tile_y The y coordinate of the tile

function draw_ore_sprite(ore_type, tile_x, tile_y) {
    // Retrieve ore properties
    var ore = global.ore_properties[? ore_type];
    var ore_color = ore[? "color"];
    var ore_tile_index = ore[? "tile_index"];
	var ore_tile_variants = ore[? "tile_variants"];

    // Calculate the position to draw the ore sprite
    var _x = tile_x * TILE_WIDTH;
    var _y = tile_y * TILE_HEIGHT;
	
    var noise_value = chaos_noise(global.perm_tex, tile_x, tile_y);
    ore_tile_index = ore_tile_index + 1 + floor((noise_value + 1) * 0.499 * ore_tile_variants);

    // Draw the ore sprite
    //draw_sprite(spr_ore_overlay, ore_tile_index, _x, _y);
	draw_sprite_ext(spr_ore_overlay, ore_tile_index, _x, _y, 1, 1, 0, ore_color, 1)
}

