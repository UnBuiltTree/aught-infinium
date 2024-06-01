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
    if (change_to_boxel = -1) {
        change_to_boxel = VOID;
    }

    // Get the current tile index at the specified position
    var current_tile = get_tile_index(x_pos, y_pos);

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
            tilemap_set(tilemap_id, texturize_tile(change_to_boxel), local_tile_x, local_tile_y);
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
            //update_auto_tile_textures(grid, local_tile_x, local_tile_y, tilemap_id);
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

function texturize_tile(tile){
	switch (tile) {
		case DIRT:
			tile = DIRT + irandom_range(1, ds_map_find_value(global.tile_variants, DIRT));
			break;
		case STONE:
			tile = STONE + irandom_range(1, ds_map_find_value(global.tile_variants, STONE));
			 break;
		case STONE2:
			tile = STONE2 + irandom_range(1, ds_map_find_value(global.tile_variants, STONE2));
			break;
		case METAL:
			tile = METAL + irandom_range(1, ds_map_find_value(global.tile_variants, METAL));
			 break;
		case GRASS:
			tile = GRASS+ irandom_range(1, ds_map_find_value(global.tile_variants, GRASS));
			break;
		case BORDER:
			tile = BORDER+ irandom_range(1, ds_map_find_value(global.tile_variants, BORDER));
			break;
		case VOID:
			tile = VOID;
			break;
		}
	return tile
}
