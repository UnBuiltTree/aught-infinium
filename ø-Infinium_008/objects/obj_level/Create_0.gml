// Initialize chunk management variables
load_x = 0;
load_y = 0;

load_distance = 2;
unload_distance = 3;
reload_distance = 3;

surface_y = 0;
show_debug_message("seed: " + string(global.seed));
global.random_counter = 0;

gpu_set_alphatestenable(true);

function initialize_world(seed) {
	
	
	

    if (is_undefined(global.perm_0)) {
        global.perm_0 = generate_permutation_table(seed + 640);
    }
    if (is_undefined(global.perm_1)) {
        global.perm_1 = generate_permutation_table(seed + 320);
    }
    if (is_undefined(global.perm_2)) {
        global.perm_2 = generate_permutation_table(seed + 160);
    }
    if (is_undefined(global.perm_3)) {
        global.perm_3 = generate_permutation_table(seed + 080);
    }
    if (is_undefined(global.perm_4)) {
        global.perm_4 = generate_permutation_table(seed + 040);
    }
    if (is_undefined(global.perm_5)) {
        global.perm_5 = generate_permutation_table(seed + 020);
    }
	
    if (is_undefined(global.perm_1d_0)) {
        global.perm_1d_0 = generate_permutation_table(seed);
    }
	

    // Generate the surface line for the world 
    var initial_chunk_x = 0; 
    var initial_chunk_width = 16; 
    var noise_scale = 5;
    var base_height = 24; 
    var height_range = 10; 

    global.surface_line = generate_surface_line(initial_chunk_x, initial_chunk_width, noise_scale, base_height, height_range, seed);
	
}

function generate_multiple_dungeons(num_dungeons) {
    var is_positive = true; // Start with positive positions

    for (var i = 0; i < num_dungeons; i++) {
        var dungeon_x_start = i * 256;
        var dungeon_x_end = (i + 1) * 256;

        var dungeon_x_pos = chaos_noise_irange(global.perm_0, 0, 0, dungeon_x_start, dungeon_x_end); 
        var dungeon_x_neg = chaos_noise_irange(global.perm_0, 0, 0, -dungeon_x_end, -dungeon_x_start); 

        if (is_positive) {
            generate_dungeon(dungeon_x_pos, get_surface_y(dungeon_x_pos), 128, 256, -1, 6, 12);
        } else {
            generate_dungeon(dungeon_x_neg, get_surface_y(dungeon_x_neg), 128, 256, -1, 6, 12);
        }

        is_positive = !is_positive; // Alternate between positive and negative
    }
}

function generate_surface_line(_chunk_x, _chunk_width, _noise_scale, _base_height, _height_range, _seed) {
    if (is_undefined(global.perm_1d_0)) {
        global.perm_1d_0 = generate_permutation_table(_seed);
    }

    var surface_line = array_create(_chunk_width, 0);
    for (var i = 0; i < _chunk_width; i++) {
        var world_x = _chunk_x * _chunk_width + i;
        var noise_value = perlin_noise_1d_multi_octave(global.perm_1d_0, world_x / _noise_scale, 4, 0.5);
        noise_value = (noise_value + 1) / 2; // Normalize to 0-1
        surface_line[i] = _base_height + noise_value * _height_range;
    }
    return surface_line;
}

function get_surface_y(_x_tile) {
    // Define constants that match those used in surface generation
    var _noise_scale = 128;
    var _base_height = 0;
    var _height_range = 128;
    var _seed = 42;

    // Ensure the permutation table is generated
    if (is_undefined(global.perm_1d_0)) {
        global.perm_1d_0 = generate_permutation_table(_seed);
    }

    // Calculate the surface y position for the given x tile
    var noise_value = perlin_noise_1d_multi_octave(global.perm_1d_0, _x_tile / _noise_scale, 4, 0.5);
    noise_value = (noise_value + 1) / 2; // Normalize to 0-1
    var surface_y = _base_height + noise_value * _height_range;

    return surface_y;
}

function save_game() {
    var buffer = buffer_create(1024, buffer_grow, 1);
    buffer_write(buffer, buffer_string, json_stringify(global.changed_chunks));
    buffer_write(buffer, buffer_string, json_stringify(global.structure_grids)); // Save structure grids
    buffer_save(buffer, "savegame.dat");
    buffer_delete(buffer);
}

function load_game() {
    if (file_exists("savegame.dat")) {
        var buffer = buffer_load("savegame.dat");
        var json_data = buffer_read(buffer, buffer_string);
        buffer_delete(buffer);
        global.changed_chunks = json_parse(json_data);

        var json_structure_data = buffer_read(buffer, buffer_string); // Load structure grids
        global.structure_grids = json_parse(json_structure_data);
        
        var json_structure_flags = buffer_read(buffer, buffer_string); // Load structure flags
        global.structure_flags = json_parse(json_structure_flags);
    } else {
        global.changed_chunks = ds_map_create();
        global.structure_grids = ds_map_create(); // Initialize structure grids map
        global.structure_flags = ds_map_create(); // Initialize structure flags map
    }
}

function create_chunk(_x, _y) {
    var chunk_key = string(_x) + "_" + string(_y);
    if (!ds_map_exists(global.chunks, chunk_key)) {
        var grid;
        var structure_grid;
        var has_structure = false;

        // Load the chunk if it has been changed and saved
        if (ds_map_exists(global.changed_chunks, chunk_key)) {
            grid = ds_map_find_value(global.changed_chunks, chunk_key);
            show_debug_message("Loading changed chunk: " + chunk_key);
        } else {
            grid = ds_grid_create(CHUNK_SIZE_X, CHUNK_SIZE_Y);
            generate_biome(_x, _y, grid);
        }

        // Create and initialize the ore list
        var ore_list;
        if (!ds_map_exists(global.ore_lists, chunk_key)) {
            ore_list = ds_list_create(); // Initialize the ore list
            ds_map_add(global.ore_lists, chunk_key, ore_list); // Store the ore list
            generate_ores(_x, _y, grid, ore_list); // Generate ores after grid is created
        } else {
            ore_list = ds_map_find_value(global.ore_lists, chunk_key);
        }

        // Check for structure grid
        var structure_key = chunk_key + "_structure";
        if (ds_map_exists(global.structure_grids, structure_key)) {
            structure_grid = ds_map_find_value(global.structure_grids, structure_key);
            place_structure_tiles(grid, structure_grid, ore_list);
            has_structure = true;
        }

        ds_map_add(global.chunks, chunk_key, grid);

        if (has_structure) {
            ds_map_add(global.structure_flags, chunk_key, true); // Add structure flag
        }

        create_tilemap(_x, _y);
        draw_tiles_to_tilemap(_x, _y);

        create_chunk_vertex_buffer(_x, _y, ore_list); // Create the vertex buffer for the chunk
    }
}



function create_chunk_vertex_buffer(_x, _y, ore_list) {
    var chunk_key = string(_x) + "_" + string(_y);

    // Check if the vertex buffer exists before attempting to delete it
    if (ds_map_exists(global.chunk_vertex_buffers, chunk_key)) {
        var vb = ds_map_find_value(global.chunk_vertex_buffers, chunk_key);
        delete_chunk_vertex_buffer(_x, _y)
    }

    var vb = vertex_create_buffer();
    vertex_begin(vb, global.ore_vb_format); // Use the global vertex format

    var ore_textures = ds_list_create(); // Create a list to store ore textures

    // Iterate over the ore list and add vertices for each ore
    for (var i = 0; i < ds_list_size(ore_list); i++) {
        var ore_info = ds_list_find_value(ore_list, i);
        var local_x = ore_info[0];
        var local_y = ore_info[1];
        var ore_id = ore_info[2];

        // Calculate the world coordinates of the ore
        var world_x = _x * CHUNK_SIZE_X * TILE_WIDTH + local_x * TILE_WIDTH;
        var world_y = _y * CHUNK_SIZE_Y * TILE_HEIGHT + local_y * TILE_HEIGHT;
        // Get the ore type by its ID
        var ore_type;
        var ore_keys = ds_map_keys_to_array(global.ore_properties);
        for (var k = 0; k < array_length(ore_keys); k++) {
            var key = ore_keys[k];
            var ore = global.ore_properties[? key];
            if (ore[? "ID"] == ore_id) {
                ore_type = key;
                break;
            }
        }

        var ore = global.ore_properties[? ore_type];
        var ore_color = ore[? "color"];
        var ore_tile_index = ore[? "tile_index"];
        var ore_tile_variants = ore[? "tile_variants"];
        var ore_alpha = 1;

        // Calculate the noise value for the ore variant
        var noise_value = chaos_noise(global.perm_tex, local_x, local_y);
        var ore_variant_index = ore_tile_index + floor((noise_value + 1) * 0.5 * ore_tile_variants + 1);

        var ore_tex = sprite_get_texture(spr_ore_overlay, ore_variant_index);
        ds_list_add(ore_textures, ore_tex); // Store the ore texture in the list
		
		var uvs = texture_get_uvs(ore_tex);

		var _left = uvs[0];
		var _top = uvs[1];
		var _right = uvs[2];
		var _bottom = uvs[3];
		

        // First triangle
		vertex_position_3d(vb, world_x, world_y, 0);
		vertex_color(vb, ore_color, ore_alpha);
		vertex_texcoord(vb, _left, _top);

		vertex_position_3d(vb, world_x + TILE_WIDTH, world_y, 0);
		vertex_color(vb, ore_color, ore_alpha);
		vertex_texcoord(vb, _right, _top);

		vertex_position_3d(vb, world_x, world_y + TILE_HEIGHT, 0);
		vertex_color(vb, ore_color, ore_alpha);
		vertex_texcoord(vb, _left, _bottom);

		// Second triangle
		vertex_position_3d(vb, world_x + TILE_WIDTH, world_y, 0);
		vertex_color(vb, ore_color, ore_alpha);
		vertex_texcoord(vb, _right, _top);

		vertex_position_3d(vb, world_x + TILE_WIDTH, world_y + TILE_HEIGHT, 0);
		vertex_color(vb, ore_color, ore_alpha);
		vertex_texcoord(vb, _right, _bottom);

		vertex_position_3d(vb, world_x, world_y + TILE_HEIGHT, 0);
		vertex_color(vb, ore_color, ore_alpha);
		vertex_texcoord(vb, _left, _bottom);
    }

    vertex_end(vb);

    ds_map_replace(global.chunk_vertex_buffers, chunk_key, vb); // Use replace to ensure correct assignment
    ds_map_replace(global.chunk_textures, chunk_key, ore_textures); // Store the list of textures in a global map
}



function draw_chunk_vertex_buffers() {
    var keys = ds_map_keys_to_array(global.chunk_vertex_buffers);
    var texture_batches = ds_map_create(); // Map to store vertex buffers by texture

    // Group vertex buffers by texture
    for (var i = 0; i < array_length(keys); i++) {
        var chunk_key = keys[i];
        if (ds_map_exists(global.chunk_vertex_buffers, chunk_key)) {
            var vb = ds_map_find_value(global.chunk_vertex_buffers, chunk_key);
            var ore_textures = ds_map_find_value(global.chunk_textures, chunk_key);

            // Group vertex buffers by texture
            for (var j = 0; j < ds_list_size(ore_textures); j++) {
                var ore_tex = ds_list_find_value(ore_textures, j);

                if (!ds_map_exists(texture_batches, ore_tex)) {
                    texture_batches[? ore_tex] = ds_list_create();
                }
                ds_list_add(texture_batches[? ore_tex], vb);
            }
        }
    }

    // Draw vertex buffers by texture
    var texture_keys = ds_map_keys_to_array(texture_batches);
    for (var i = 0; i < array_length(texture_keys); i++) {
        var ore_tex = texture_keys[i];
        texture_set_stage(0, ore_tex);
        var vb_list = ds_map_find_value(texture_batches, ore_tex);

        for (var j = 0; j < ds_list_size(vb_list); j++) {
            var vb = ds_list_find_value(vb_list, j);
            vertex_submit(vb, pr_trianglelist, ore_tex);
        }

        ds_list_destroy(vb_list); // Clean up the list
    }

    ds_map_destroy(texture_batches); // Clean up the map
}



function update_chunk_vertex_buffer(_x, _y) {
    var chunk_key = string(_x) + "_" + string(_y);
    if (ds_map_exists(global.chunk_vertex_buffers, chunk_key)) {
        var ore_list = ds_map_find_value(global.ore_lists, chunk_key);
        var vb = ds_map_find_value(global.chunk_vertex_buffers, chunk_key);
		delete_chunk_vertex_buffer(_x, _y)
        create_chunk_vertex_buffer(_x, _y, ore_list); // Create a new buffer
    }
}



function place_structure_tiles(grid, structure_grid, ore_list) {
    for (var i = 0; i < ds_grid_width(structure_grid); i++) {
        for (var j = 0; j < ds_grid_height(structure_grid); j++) {
            var tile = ds_grid_get(structure_grid, i, j);
            if (tile == WALL) {
                ds_grid_set(grid, i, j, STONE);
            } else if (tile == ROOM || tile == DOOR) {
                ds_grid_set(grid, i, j, VOID);
            }

            // Remove any ores that are on the same tiles
            for (var k = 0; k < ds_list_size(ore_list); k++) {
                var ore_entry = ds_list_find_value(ore_list, k);
                if (ore_entry[0] == i && ore_entry[1] == j) {
                    ds_list_delete(ore_list, k);
                    k--; // Adjust index after deletion
                }
            }
        }
    }
}

function delete_chunk_vertex_buffer(_x, _y) {
    var chunk_key = string(_x) + "_" + string(_y);
    if (ds_map_exists(global.chunk_vertex_buffers, chunk_key)) {
        var vb = ds_map_find_value(global.chunk_vertex_buffers, chunk_key);
        
        // Check if the vertex buffer is valid before deleting
        if (vertex_get_number(vb) > 0) {
            vertex_delete_buffer(vb);
        }

        ds_map_delete(global.chunk_vertex_buffers, chunk_key); // Remove entry from map
    }
}

function destroy_chunk(_x, _y) {
    var chunk_key = string(_x) + "_" + string(_y);
    if (ds_map_exists(global.chunks, chunk_key)) {
        var grid = ds_map_find_value(global.chunks, chunk_key);

        if (ds_map_exists(global.changed_chunks, chunk_key)) {
            ds_map_add(global.changed_chunks, chunk_key, grid);
            // Delete the structure grid if it exists
            var structure_key = chunk_key + "_structure";
            if (ds_map_exists(global.structure_grids, structure_key)) {
                var structure_grid = ds_map_find_value(global.structure_grids, structure_key);
                ds_grid_destroy(structure_grid);
                ds_map_delete(global.structure_grids, structure_key);
            }
            // Delete the structure flag
            if (ds_map_exists(global.structure_flags, chunk_key)) {
                ds_map_delete(global.structure_flags, chunk_key);
            }
        }

        if (!ds_map_exists(global.changed_chunks, chunk_key)) {
            ds_grid_destroy(grid);
        }

        ds_map_delete(global.chunks, chunk_key);
        destroy_tilemap(_x, _y);
        
        // Delete the vertex buffer for this chunk
        delete_chunk_vertex_buffer(_x, _y);
    }
}
	
function generate_biome(_x, _y, grid) {
    var biome = determine_biome(_x, _y);

    // Create the grid based on the biome
    switch (biome) {
        case BIOME_BORDER:
            ds_grid_clear(grid, BORDER);
            break;
        case BIOME_AIR:
            ds_grid_clear(grid, VOID);
            break;
        case BIOME_UNDERGROUND:
            for (var i = 0; i < CHUNK_SIZE_X; i++) {
                for (var j = 0; j < CHUNK_SIZE_Y; j++) {
                    ds_grid_set(grid, i, j, STONE);
                }
            }
            break;
        case BIOME_SURFACE:
            var noise_scale_surface = 128;
            var base_height = 0;
            var height_range = 128;
            var surface_line = generate_surface_line(_x, CHUNK_SIZE_X, noise_scale_surface, base_height, height_range, 42);

            for (var i = 0; i < CHUNK_SIZE_X; i++) {
                for (var j = 0; j < CHUNK_SIZE_Y; j++) {
                    var world_y = _y * CHUNK_SIZE_Y + j;
                    var distance_to_surface = world_y - surface_line[i];

                    if (world_y < surface_line[i]) {
                        ds_grid_set(grid, i, j, VOID);
                    } else {
                        var noise_scale_horz = 3 + (distance_to_surface / 3);
                        var noise_scale_vert = 12;

                        var depth_stone_fade = 128;

                        var noise_value_0 = perlin_noise(global.perm_0, (_x * CHUNK_SIZE_X + i) / noise_scale_vert, world_y / noise_scale_horz);
                        noise_value_0 = (noise_value_0 + 1) / 2;

                        var adjusted_noise_value = lerp(noise_value_0, 0.55, 1 - min(distance_to_surface / CHUNK_SIZE_Y, 1));

                        var depth_factor = max((world_y - surface_line[i]) / depth_stone_fade, 0);
                        adjusted_noise_value = lerp(adjusted_noise_value, 0.3, depth_factor);

                        if (adjusted_noise_value < 0.5) {
                            ds_grid_set(grid, i, j, STONE);
                        } else {
                            if (distance_to_surface < 1) {
                                ds_grid_set(grid, i, j, GRASS);
                            } else {
                                ds_grid_set(grid, i, j, DIRT);
                            }
                        }
                    }
                }
            }
            break;
        default:
            for (var i = 0; i < CHUNK_SIZE_X; i++) {
                for (var j = 0; j < CHUNK_SIZE_Y; j++) {
                    ds_grid_set(grid, i, j, VOID);
                }
            }
            break;
    }
}
	
function generate_ores(_x, _y, grid, ore_list) {
    var ore_keys = ds_map_keys_to_array(global.ore_properties); // Get all ore types

    // Iterate over all tiles in the chunk
    for (var i = 0; i < CHUNK_SIZE_X; i++) {
        for (var j = 0; j < CHUNK_SIZE_Y; j++) {
            if (ds_grid_get(grid, i, j) == STONE) { // Check if the tile is STONE

                // Iterate over all ores
                for (var k = 0; k < array_length(ore_keys); k++) {
                    var ore_key = ore_keys[k];
                    var ore = global.ore_properties[? ore_key];
                    var ore_id = ore[? "ID"];
                    var ore_spawn_rate = ore[? "spawn_rate"];
                    var ore_generation_type = ore[? "generation_type"];
					var perm = ore[? "perm_table"]

                    var noise_value;
                    if (ore_generation_type == "veins") {
                        noise_value = perlin_noise(perm, (_x * CHUNK_SIZE_X + i) / 8, (_y * CHUNK_SIZE_Y + j) / 8);
                    } else if (ore_generation_type == "splotchy") {
                        noise_value = perlin_noise(perm, (_x * CHUNK_SIZE_X + i) / 12, (_y * CHUNK_SIZE_Y + j) / 12);
                    }

                    // Check the noise value against the ore's spawn rate
                    if (noise_value > (1 - ore_spawn_rate / 100)) { // Adjust the threshold based on spawn rate

                        // Check if the coordinates already exist in the list
                        var coordinates_exist = false;
                        for (var l = 0; l < ds_list_size(ore_list); l++) {
                            var entry = ds_list_find_value(ore_list, l);
                            if (entry[0] == i && entry[1] == j) {
                                coordinates_exist = true;
                                break;
                            }
                        }

                        // If coordinates do not exist, add the new ore entry
                        if (!coordinates_exist) {
                            ds_list_add(ore_list, [i, j, ore_id]);
                        }
                    }
                }
            }
        }
    }
}

// Determine biome based on chunk coordinates
function determine_biome(chunk_x, chunk_y) {
    var biome;
	
	//world is 2,097,152 blocks tall and wide. 2M x 2M
    // Check if the chunk is beyond the border limit
    if (abs(chunk_x) > 32768 || abs(chunk_y) > 32768) {
        biome = BIOME_BORDER;
    //} else if (chunk_x == -1) {
        //biome = BIOME_AIR;
    }  else if (chunk_y < 0) {
        biome = BIOME_AIR;
    } else if (chunk_y > 8) {
        biome = BIOME_UNDERGROUND;
    } else {
        biome = BIOME_SURFACE;
    }

    return biome;
}

// Return the name of the biome
function return_biome_name(biome) {
    var biome_name = "Null";
    switch (biome) {
        case BIOME_AIR:
            biome_name = "Air";
            break;
        case BIOME_UNDERGROUND:
            biome_name = "UnderGround";
            break;
        case BIOME_SURFACE:
            biome_name = "Surface";
            break;
        case BIOME_BORDER:
            biome_name = "Border";
            break;
    }
    return biome_name;
}

function create_tilemap(_x, _y) {
    var chunk_key = string(_x) + "_" + string(_y);
    if (!ds_map_exists(global.chunk_tilemaps, chunk_key)) {
        // Create a new layer for the chunk
        var layer_id = layer_create(250); // You need to provide the depth or order for the layer
        
        // Specify the tile set you are using
        var tile_set = t_main; // Replace with your actual tile set
        
        // Create a tilemap on the newly created layer
        var tilemap = layer_tilemap_create(layer_id, _x * CHUNK_SIZE_X * TILE_WIDTH, _y * CHUNK_SIZE_Y * TILE_HEIGHT, tile_set, CHUNK_SIZE_X, CHUNK_SIZE_Y);
        
        ds_map_add(global.chunk_tilemaps, chunk_key, tilemap);
    }
}

function destroy_tilemap(_x, _y) {
    var chunk_key = string(_x) + "_" + string(_y);
    if (ds_map_exists(global.chunk_tilemaps, chunk_key)) {
        var tilemap = ds_map_find_value(global.chunk_tilemaps, chunk_key);
        layer_tilemap_destroy(tilemap);
        ds_map_delete(global.chunk_tilemaps, chunk_key);
    }
}

function draw_tiles_to_tilemap(_chunk_x, _chunk_y) {
    var chunk_key = string(_chunk_x) + "_" + string(_chunk_y);
    if (ds_map_exists(global.chunks, chunk_key) && ds_map_exists(global.chunk_tilemaps, chunk_key)) {
        var grid = ds_map_find_value(global.chunks, chunk_key);
        var tilemap = ds_map_find_value(global.chunk_tilemaps, chunk_key);

        for (var i = 0; i < CHUNK_SIZE_X; i++) {
            for (var j = 0; j < CHUNK_SIZE_Y; j++) {
                // Ensure the indices are within the bounds of the grid
                if (i >= 0 && i < ds_grid_width(grid) && j >= 0 && j < ds_grid_height(grid)) {
                    var tile = ds_grid_get(grid, i, j);
                    tilemap_set(tilemap, texturize_tile(tile, _chunk_x * CHUNK_SIZE_X + i, _chunk_y * CHUNK_SIZE_Y + j), i, j);
                }
            }
        }
    }
}

function update_chunk_neighbors(_x, _y) {
    var chunk_key = string(_x) + "_" + string(_y);
    if (ds_map_exists(global.chunks, chunk_key)) {
        var grid = ds_map_find_value(global.chunks, chunk_key);

        // Example of setting references (you need to adapt this to your specific needs)
        var neighbors = {
            left: ds_map_exists(global.chunks, string(_x - 1) + "_" + string(_y)) ? ds_map_find_value(global.chunks, string(_x - 1) + "_" + string(_y)) : null,
            right: ds_map_exists(global.chunks, string(_x + 1) + "_" + string(_y)) ? ds_map_find_value(global.chunks, string(_x + 1) + "_" + string(_y)) : null,
            top: ds_map_exists(global.chunks, string(_x) + "_" + string(_y - 1)) ? ds_map_find_value(global.chunks, string(_x) + "_" + string(_y - 1)) : null,
            bottom: ds_map_exists(global.chunks, string(_x) + "_" + string(_y + 1)) ? ds_map_find_value(global.chunks, string(_x) + "_" + string(_y + 1)) : null
        };

        // Store neighbors in your chunk data structure if needed
        // Example: grid.neighbors = neighbors;
    }
}
	
function manage_chunks(player_x, player_y) {
    var chunk_x = floor(player_x / (CHUNK_SIZE_X * TILE_WIDTH));
    var chunk_y = floor(player_y / (CHUNK_SIZE_Y * TILE_HEIGHT));

    // Load surrounding chunks
    for (var i = -load_distance; i <= load_distance; i++) {
        for (var j = -load_distance; j <= load_distance; j++) {
            create_chunk(chunk_x + i, chunk_y + j);
        }
    }

    // Unload distant chunks
    var keys = ds_map_keys(global.chunks);
    for (var k = 0; k < array_length(keys); k++) {
        var key = keys[k];
        var parts = string_split(key, "_");
        var _x = real(parts[0]);
        var _y = real(parts[1]);

        if (abs(_x - chunk_x) > unload_distance || abs(_y - chunk_y) > unload_distance) {
            destroy_chunk(_x, _y);
        }
    }
}
	
/// --- ore management

function draw_ores_from_grid(chunk_x, chunk_y) {
    var chunk_key = string(chunk_x) + "_" + string(chunk_y);
    if (ds_map_exists(global.ore_lists, chunk_key)) {
        var ore_list = ds_map_find_value(global.ore_lists, chunk_key);
        
        for (var i = 0; i < ds_list_size(ore_list); i++) {
            var ore_info = ds_list_find_value(ore_list, i);
            var local_x = ore_info[0];
            var local_y = ore_info[1];
            var ore_id = ore_info[2];
            
            // Get the ore type by its ID
            var ore_type;
            var ore_keys = ds_map_keys_to_array(global.ore_properties);
            for (var k = 0; k < array_length(ore_keys); k++) {
                var key = ore_keys[k];
                var ore = global.ore_properties[? key];
                if (ore[? "ID"] == ore_id) {
                    ore_type = key;
                    break;
                }
            }

            // Draw the ore sprite
            draw_ore_sprite(ore_type, chunk_x * CHUNK_SIZE_X + local_x, chunk_y * CHUNK_SIZE_Y + local_y);
        }
    }
}

	
function stress_test_ore_drawing() {
    var start_x = 0;
    var start_y = 0;
    var end_x = 32;
    var end_y = 32;
    var ore_type = "iron"; // Choose an ore type to test with

    for (var _x = start_x; _x < end_x; _x++) {
        for (var _y = start_y; _y < end_y; _y++) {
            var chunk_x = floor(_x / CHUNK_SIZE_X);
            var chunk_y = floor(_y / CHUNK_SIZE_Y);
            var local_x = _x % CHUNK_SIZE_X;
            var local_y = _y % CHUNK_SIZE_Y;
            var chunk_key = string(chunk_x) + "_" + string(chunk_y);

            if (!ds_map_exists(global.ore_lists, chunk_key)) {
                var ore_list = ds_list_create(); // Initialize the ore list
                ds_map_add(global.ore_lists, chunk_key, ore_list);
            } else {
                var ore_list = ds_map_find_value(global.ore_lists, chunk_key);
            }

            var ore_id = global.ore_properties[? ore_type][? "ID"];
            ds_list_add(ore_list, [local_x, local_y, ore_id]); // Add ore coordinates and ID to the list
        }
    }
}




/// --- Above this point is Chunk generation code
/// --- Below this point is structure generation code

function get_affected_chunks(x1, y1, x2, y2) {
    var affected_chunks = ds_list_create();

    var chunk_x1 = floor(x1 / (CHUNK_SIZE_X * TILE_WIDTH));
    var chunk_y1 = floor(y1 / (CHUNK_SIZE_Y * TILE_HEIGHT));
    var chunk_x2 = floor(x2 / (CHUNK_SIZE_X * TILE_WIDTH));
    var chunk_y2 = floor(y2 / (CHUNK_SIZE_Y * TILE_HEIGHT));

    for (var cx = chunk_x1; cx <= chunk_x2; cx++) {
        for (var cy = chunk_y1; cy <= chunk_y2; cy++) {
            ds_list_add(affected_chunks, [cx, cy]);
        }
    }

    return affected_chunks;
}

function get_affected_chunks_by_tiles(tile_x1, tile_y1, tile_x2, tile_y2) {
    var affected_chunks = ds_list_create();

    var chunk_x1 = floor(tile_x1 / CHUNK_SIZE_X);
    var chunk_y1 = floor(tile_y1 / CHUNK_SIZE_Y);
    var chunk_x2 = floor(tile_x2 / CHUNK_SIZE_X);
    var chunk_y2 = floor(tile_y2 / CHUNK_SIZE_Y);

    for (var cx = chunk_x1; cx <= chunk_x2; cx++) {
        for (var cy = chunk_y1; cy <= chunk_y2; cy++) {
            ds_list_add(affected_chunks, [cx, cy]);
        }
    }

    return affected_chunks;
}

function place_structure_box(tile_x1, tile_y1, tile_x2, tile_y2, tile_type) {
    var affected_chunks = get_affected_chunks_by_tiles(tile_x1, tile_y1, tile_x2, tile_y2);
    var num_chunks = ds_list_size(affected_chunks);

    for (var i = 0; i < num_chunks; i++) {
        var chunk_coords = ds_list_find_value(affected_chunks, i);
        var chunk_x = chunk_coords[0];
        var chunk_y = chunk_coords[1];

        var structure_key = string(chunk_x) + "_" + string(chunk_y) + "_structure";
        var structure_grid;

        // Create the structure grid if it doesn't exist
        if (!ds_map_exists(global.structure_grids, structure_key)) {
            structure_grid = ds_grid_create(CHUNK_SIZE_X, CHUNK_SIZE_Y);
            ds_map_add(global.structure_grids, structure_key, structure_grid);
        } else {
            structure_grid = ds_map_find_value(global.structure_grids, structure_key);
        }

        // Determine the coordinates within the chunk to place the tiles
        var start_x = max(0, tile_x1 - chunk_x * CHUNK_SIZE_X);
        var start_y = max(0, tile_y1 - chunk_y * CHUNK_SIZE_Y);
        var end_x = min(CHUNK_SIZE_X - 1, tile_x2 - chunk_x * CHUNK_SIZE_X);
        var end_y = min(CHUNK_SIZE_Y - 1, tile_y2 - chunk_y * CHUNK_SIZE_Y);

        for (var sx = start_x; sx <= end_x; sx++) {
            for (var sy = start_y; sy <= end_y; sy++) {
                ds_grid_set(structure_grid, sx, sy, tile_type);
            }
        }

        // Add a flag to indicate that this chunk has a structure grid
        var chunk_key = string(chunk_x) + "_" + string(chunk_y);
        ds_map_add(global.structure_flags, chunk_key, true);
    }

    ds_list_destroy(affected_chunks);
}

// --- dungeon generation code

function create_temp_dungeon_grid(_x_size, _y_size) {
    return ds_grid_create(_x_size, _y_size);
}

function create_temp_grid(_x_origin, _y_origin, _x_size, _y_size) {
    var border_threshold = 4; // Tiles within 4 units from the border will be VOID

    // Calculate the range of chunks that need to be loaded
    var chunk_x1 = floor((_x_origin - floor(_x_size / 2)) / CHUNK_SIZE_X);
    var chunk_y1 = floor((_y_origin - floor(_y_size / 2)) / CHUNK_SIZE_Y);
    var chunk_x2 = floor((_x_origin + floor(_x_size / 2)) / CHUNK_SIZE_X);
    var chunk_y2 = floor((_y_origin + floor(_y_size / 2)) / CHUNK_SIZE_Y);

    // Load the necessary chunks
    for (var cx = chunk_x1; cx <= chunk_x2; cx++) {
        for (var cy = chunk_y1; cy <= chunk_y2; cy++) {
            create_chunk(cx, cy);
        }
    }

    // Create the temporary grid
    var temp_grid = ds_grid_create(_x_size, _y_size);

    // Fill the temporary grid based on the loaded chunks
    for (var _x = 0; _x < _x_size; _x++) {
        for (var _y = 0; _y < _y_size; _y++) {
            // Check if the tile is close to the border and set to VOID if true
            if (_x < border_threshold || _x >= _x_size - border_threshold || _y < border_threshold || _y >= _y_size - border_threshold) {
                ds_grid_set(temp_grid, _x, _y, VOID);
                continue;
            }

            var world_x = _x_origin - floor(_x_size / 2) + _x;
            var world_y = _y_origin - floor(_y_size / 2) + _y;

            var chunk_x = floor(world_x / CHUNK_SIZE_X);
            var chunk_y = floor(world_y / CHUNK_SIZE_Y);
            var local_x = world_x % CHUNK_SIZE_X;
            var local_y = world_y % CHUNK_SIZE_Y;

            // Correct for negative coordinates
            if (local_x < 0) local_x += CHUNK_SIZE_X;
            if (local_y < 0) local_y += CHUNK_SIZE_Y;

            var chunk_key = string(chunk_x) + "_" + string(chunk_y);

            // Check if the chunk is loaded and get the grid
            if (ds_map_exists(global.chunks, chunk_key)) {
                var grid = ds_map_find_value(global.chunks, chunk_key);

                // Check if the local coordinates are within bounds
                if (local_x >= 0 && local_x < ds_grid_width(grid) && local_y >= 0 && local_y < ds_grid_height(grid)) {
                    var tile = ds_grid_get(grid, local_x, local_y);

                    if (tile != VOID) {
                        ds_grid_set(temp_grid, _x, _y, AREA);
                    } else {
                        ds_grid_set(temp_grid, _x, _y, VOID);
                    }
                } else {
                    ds_grid_set(temp_grid, _x, _y, VOID);
                }
            } else {
                ds_grid_set(temp_grid, _x, _y, VOID);
            }
        }
    }

    // Unload the chunks
    for (var cx = chunk_x1; cx <= chunk_x2; cx++) {
        for (var cy = chunk_y1; cy <= chunk_y2; cy++) {
            destroy_chunk(cx, cy);
        }
    }

    // Return the temporary grid
    return temp_grid;
}

/// @function is_grid_empty(grid)
/// @param {ds_grid} grid The grid to check
/// @returns {bool} True if the grid is empty, false otherwise

function is_grid_empty(grid) {
    var width = ds_grid_width(grid);
    var height = ds_grid_height(grid);

    for (var _x = 0; _x < width; _x++) {
        for (var _y = 0; _y < height; _y++) {
            if (ds_grid_get(grid, _x, _y) != VOID) {  // Assuming VOID is the default empty tile value
                return false;
            }
        }
    }
    return true;
}

function apply_dungeon_to_chunks(dungeon_grid, x_origin, y_origin) {
    var grid_width = ds_grid_width(dungeon_grid);
    var grid_height = ds_grid_height(dungeon_grid);

    var affected_chunks = get_affected_chunks_by_tiles(x_origin - floor(grid_width / 2), y_origin - floor(grid_height / 2),
                                                       x_origin + floor(grid_width / 2), y_origin + floor(grid_height / 2));
    var num_chunks = ds_list_size(affected_chunks);

    for (var i = 0; i < num_chunks; i++) {
        var chunk_coords = ds_list_find_value(affected_chunks, i);
        var chunk_x = chunk_coords[0];
        var chunk_y = chunk_coords[1];

        var structure_key = string(chunk_x) + "_" + string(chunk_y) + "_structure";
        var structure_grid;

        // Create the structure grid if it doesn't exist
        if (!ds_map_exists(global.structure_grids, structure_key)) {
            structure_grid = ds_grid_create(CHUNK_SIZE_X, CHUNK_SIZE_Y);
            ds_map_add(global.structure_grids, structure_key, structure_grid);
        } else {
            structure_grid = ds_map_find_value(global.structure_grids, structure_key);
        }

        // Determine the coordinates within the chunk to place the tiles
        var chunk_offset_x = chunk_x * CHUNK_SIZE_X;
        var chunk_offset_y = chunk_y * CHUNK_SIZE_Y;

        for (var _x = 0; _x < grid_width; _x++) {
            for (var _y = 0; _y < grid_height; _y++) {
                var world_x = x_origin - floor(grid_width / 2) + _x;
                var world_y = y_origin - floor(grid_height / 2) + _y;

                if (world_x >= chunk_offset_x && world_x < chunk_offset_x + CHUNK_SIZE_X &&
                    world_y >= chunk_offset_y && world_y < chunk_offset_y + CHUNK_SIZE_Y) {
                    var local_x = world_x - chunk_offset_x;
                    var local_y = world_y - chunk_offset_y;

                    // Check if local_x and local_y are within bounds of structure_grid
                    if (local_x >= 0 && local_x < CHUNK_SIZE_X && local_y >= 0 && local_y < CHUNK_SIZE_Y) {
                        var tile = ds_grid_get(dungeon_grid, _x, _y);
                        ds_grid_set(structure_grid, local_x, local_y, tile);
                    }
                }
            }
        }

        // Check if the structure grid is empty and handle accordingly
        if (is_grid_empty(structure_grid)) {
            ds_grid_destroy(structure_grid);
            ds_map_delete(global.structure_grids, structure_key);
            ds_map_delete(global.structure_flags, string(chunk_x) + "_" + string(chunk_y));
        } else {
            // Add a flag to indicate that this chunk has a structure grid
            var chunk_key = string(chunk_x) + "_" + string(chunk_y);
            ds_map_add(global.structure_flags, chunk_key, true);
        }
    }

    ds_list_destroy(affected_chunks);
}

function generate_dungeon(_x_origin, _y_origin, _x_size, _y_size, dungeon_type, min_rooms, max_rooms) {
    _x_origin = floor(_x_origin);
    _y_origin = floor(_y_origin);
    var dungeon_rooms = ds_list_create();
    var rendered_connections = ds_map_create(); // Initialize this at the start of your dungeon generation

    // Create the temporary dungeon grid
    var temp_grid = create_temp_grid(_x_origin, _y_origin, _x_size, _y_size);

    // Create the temporary dungeon grid
    var dungeon_grid = create_temp_dungeon_grid(_x_size, _y_size);

    // Calculate the spawn room position in the center of the temp grid
    var spawn_room_x = floor(_x_size / 2);
    var spawn_room_y = floor(_y_size / 2);
    var spawn_room_width = 3;
    spawn_room_width = (round(spawn_room_width / 2) * 2) + 1;
    var spawn_room_height = 24;
    spawn_room_height = (round(spawn_room_height / 2) * 2);
    var spawn_room = 0;
    create_room(dungeon_grid, dungeon_rooms, spawn_room, spawn_room_x, spawn_room_y, spawn_room_width, spawn_room_height);
    ds_map_add(ds_list_find_value(dungeon_rooms, spawn_room), "is_spawn_room", true); // Mark the spawn room
    show_debug_message("Spawn room center: " + string(_x_origin) + ", " + string(_y_origin));
	
	var room_count = chaos_noise_irange(global.perm_1, global.seed, global.random_counter, min_rooms, max_rooms)
	global.random_counter++;
    for (var i = 1; i < room_count; ++i) {
        place_room(dungeon_grid, dungeon_rooms, i, -1, -1, "medium", temp_grid);
    }
    render_dungeon(dungeon_grid, dungeon_rooms, rendered_connections);

    // Apply the dungeon grid to the affected structure grid chunks
    apply_dungeon_to_chunks(dungeon_grid, _x_origin, _y_origin);

    // Cleanup
    ds_grid_destroy(dungeon_grid);
    ds_grid_destroy(temp_grid);
    ds_list_destroy(dungeon_rooms);
    ds_map_destroy(rendered_connections);

    return dungeon_rooms;
}

function filter_invalid_centers(potential_centers, _rooms_list, _room_width, _room_height, temp_grid) {
    var valid_centers = ds_list_create();
    var grid_width = ds_grid_width(temp_grid);
    var grid_height = ds_grid_height(temp_grid);
    var edge_threshold = 8; // Minimum distance from the edge

    for (var i = 0; i < ds_list_size(potential_centers); i++) {
        var potential_center = ds_list_find_value(potential_centers, i);
        var _x_center = ds_list_find_value(potential_center, 0);
        var _y_center = ds_list_find_value(potential_center, 1);
        var is_valid = true;

        for (var j = 0; j < ds_list_size(_rooms_list); j++) {
            var room_ = ds_list_find_value(_rooms_list, j);
            var room_x = ds_map_find_value(room_, "_x");
            var room_y = ds_map_find_value(room_, "_y");
            var room_w = ds_map_find_value(room_, "width");
            var room_h = ds_map_find_value(room_, "height");

            var room_left = room_x - floor(room_w / 2);
            var room_right = room_x + floor(room_w / 2);
            var room_top = room_y - floor(room_h / 2);
            var room_bottom = room_y + floor(room_h / 2);

            var new_room_left = _x_center - floor(_room_width / 2);
            var new_room_right = _x_center + floor(_room_width / 2);
            var new_room_top = _y_center - floor(_room_height / 2);
            var new_room_bottom = _y_center + floor(_room_height / 2);

            if (!(new_room_right < room_left || new_room_left > room_right || new_room_bottom < room_top || new_room_top > room_bottom)) {
                is_valid = false;
                break;
            }
        }

        // Check if the room is too close to the edges of the grid
        var new_room_left = _x_center - floor(_room_width / 2);
        var new_room_right = _x_center + floor(_room_width / 2);
        var new_room_top = _y_center - floor(_room_height / 2);
        var new_room_bottom = _y_center + floor(_room_height / 2);

        if (new_room_left < edge_threshold || new_room_right >= grid_width - edge_threshold ||
            new_room_top < edge_threshold || new_room_bottom >= grid_height - edge_threshold) {
            is_valid = false;
        }

        // Check if the perimeter of the new room contains any void tiles
        if (is_valid) {
            // Expand the boundaries of the room by one tile
            var extended_room_top = new_room_top - 1;
            var extended_room_bottom = new_room_bottom + 1;
            var extended_room_left = new_room_left - 1;
            var extended_room_right = new_room_right + 1;

            for (var _y = extended_room_top; _y <= extended_room_bottom; _y++) {
                for (var _x = extended_room_left; _x <= extended_room_right; _x++) {
                    // Check if the current tile is on the perimeter of the extended room
                    if ((_x == extended_room_left || _x == extended_room_right || _y == extended_room_top || _y == extended_room_bottom) &&
                        (temp_grid[# _x, _y] == VOID)) {
                        is_valid = false;
                        break;
                    }
                }
                if (!is_valid) break;
            }
        }

        if (is_valid) {
            ds_list_add(valid_centers, potential_center);
        }
    }

    ds_list_destroy(potential_centers); // Clean up
    return valid_centers;
}

function generate_potential_centers(_rooms_list, _room_width, _room_height) {
    var potential_centers = ds_list_create();

    // Generate potential centers around existing rooms
    for (var i = 0; i < ds_list_size(_rooms_list); i++) {
        var room_ = ds_list_find_value(_rooms_list, i);
        var room_x = ds_map_find_value(room_, "_x");
        var room_y = ds_map_find_value(room_, "_y");
        var room_w = ds_map_find_value(room_, "width");
        var room_h = ds_map_find_value(room_, "height");

        var room_floor_y = room_y + floor(room_h / 2); // Calculate the floor level of the current room

        if (i == 0) { // If this is the spawn room
            // Only generate centers below the spawn room
            var bottom_x = irandom_range(-floor(room_w / 2) + 2, floor(room_w / 2) - 2);
            var bottom_center = ds_list_create();
            ds_list_add(bottom_center, room_x + bottom_x);
            ds_list_add(bottom_center, room_y + floor((room_h + _room_height) / 2) + 1);
            ds_list_add(bottom_center, room_); // New: add origin room data
            ds_list_add(potential_centers, bottom_center);
        } else {
            // Generate potential centers around existing rooms
            // Left and right walls, adjust y-coordinate for floor level alignment
            var left_center = ds_list_create();
            ds_list_add(left_center, room_x - floor((room_w + _room_width) / 2) - 1);
            ds_list_add(left_center, room_floor_y - floor(_room_height / 2));
            ds_list_add(left_center, room_); // New: add origin room data
            ds_list_add(potential_centers, left_center);

            var right_center = ds_list_create();
            ds_list_add(right_center, room_x + floor((room_w + _room_width) / 2) + 1);
            ds_list_add(right_center, room_floor_y - floor(_room_height / 2));
            ds_list_add(right_center, room_); // New: add origin room data
            ds_list_add(potential_centers, right_center);

            // Bottom wall
            var bottom_x = irandom_range(-floor(room_w / 2) + 2, floor(room_w / 2) - 2);
            var bottom_center = ds_list_create();
            ds_list_add(bottom_center, room_x + bottom_x);
            ds_list_add(bottom_center, room_y + floor((room_h + _room_height) / 2) + 1);
            ds_list_add(bottom_center, room_); // New: add origin room data
            ds_list_add(potential_centers, bottom_center);

            // Top wall
            var top_x = irandom_range(-floor(room_w / 2) + 2, floor(room_w / 2) - 2);
            var top_center = ds_list_create();
            ds_list_add(top_center, room_x + top_x);
            ds_list_add(top_center, room_y - floor((room_h + _room_height) / 2) - 1);
            ds_list_add(top_center, room_); // New: add origin room data
            ds_list_add(potential_centers, top_center);
        }
    }

    return potential_centers;
}

function place_room(grid_, _rooms_list, _room_name, _room_width, _room_height, _generation_type, temp_grid) {
    // Generate random dimensions if needed
    if (_room_width == -1 || _room_height == -1) {
        switch (_generation_type) {
            case "medium":
                _room_width = (_room_width == -1) ? (irandom_range(8, 24) * 2) - 1 : _room_width;
                _room_height = (_room_height == -1) ? (irandom_range(4, 8) * 2) : _room_height;
                break;
        }
    }

    // Generate potential centers without filtering
    var potential_centers = generate_potential_centers(_rooms_list, _room_width, _room_height);

    // Filter out invalid centers
    potential_centers = filter_invalid_centers(potential_centers, _rooms_list, _room_width, _room_height, temp_grid);

    // Print potential centers for debugging
    for (var i = 0; i < ds_list_size(potential_centers); i++) {
        var potential_center = ds_list_find_value(potential_centers, i);
        var x_center = ds_list_find_value(potential_center, 0);
        var y_center = ds_list_find_value(potential_center, 1);
        var origin_room = ds_list_find_value(potential_center, 2); // New: origin room data
        //show_debug_message("Valid potential center: (" + string(x_center) + ", " + string(y_center) + ")");
    }

    // Choose a random potential center from the list and create room
    if (ds_list_size(potential_centers) > 0) {
        var random_index = irandom(ds_list_size(potential_centers) - 1);
        var selected_center = ds_list_find_value(potential_centers, random_index);
        var x_center = ds_list_find_value(selected_center, 0);
        var y_center = ds_list_find_value(selected_center, 1);
        var origin_room = ds_list_find_value(selected_center, 2); // New: origin room data
        create_room(grid_, _rooms_list, _room_name, x_center, y_center, _room_width, _room_height);
        add_connection_directly(grid_, _rooms_list, _room_name, x_center, y_center, origin_room);
    }

    ds_list_destroy(potential_centers); // Clean up
}

function add_connection_directly(grid_, _rooms_list, _room_name, _x_center, _y_center, origin_room) {
    var new_room = ds_list_find_value(_rooms_list, _room_name);

    if (new_room == undefined) {
        show_debug_message("Error: new_room is undefined");
        return;
    }

    if (origin_room == undefined) {
        show_debug_message("Error: origin_room is undefined");
        return;
    }

    if (!ds_map_exists(new_room, "connected_rooms")) {
        ds_map_add(new_room, "connected_rooms", ds_list_create());
    }

    var origin_connected_rooms = ds_map_find_value(origin_room, "connected_rooms");
    ds_list_add(origin_connected_rooms, new_room);

    var new_room_connected_rooms = ds_map_find_value(new_room, "connected_rooms");
    ds_list_add(new_room_connected_rooms, origin_room);

    // Create connections
    if (_x_center == ds_map_find_value(origin_room, "_x")) {
        // Vertical connection (hatch)
        create_vertical_connection(grid_, _x_center, _y_center, origin_room);
    } else if (_y_center == ds_map_find_value(origin_room, "_y")) {
        // Horizontal connection (door)
        create_horizontal_connection(grid_, _x_center, _y_center, origin_room);
    }
}

function create_vertical_connection(grid_, _x_center, _y_center, closest_room) {
    var room_y = ds_map_find_value(closest_room, "_y");
    var min_y = min(_y_center, room_y);
    var max_y = max(_y_center, room_y);
}

function create_horizontal_connection(grid_, _x_center, _y_center, closest_room) {
    var room_x = ds_map_find_value(closest_room, "_x");
    var min_x = min(_x_center, room_x);
    var max_x = max(_x_center, room_x);
}

function create_room(grid_, _rooms_list, _room_name, _x_center, _y_center, _room_width, _room_height) {
    var room_ = ds_map_create();
    var unique_id = ds_list_size(_rooms_list); // Simple method to generate a unique ID
    ds_map_add(room_, "id", unique_id); // Add unique ID
    ds_map_add(room_, "_x", _x_center);
    ds_map_add(room_, "_y", _y_center);
    ds_map_add(room_, "width", _room_width);
    ds_map_add(room_, "height", _room_height);
    ds_map_add(room_, "connected_rooms", ds_list_create()); // Ensure connected_rooms is a list
    ds_list_add(_rooms_list, room_);
}

function render_dungeon(grid_, _rooms_list, rendered_connections) {
    // First, render connections between rooms
    for (var i = 0; i < ds_list_size(_rooms_list); i++) {
        var room_ = ds_list_find_value(_rooms_list, i);
        var connected_rooms = ds_map_find_value(room_, "connected_rooms");

        for (var j = 0; j < ds_list_size(connected_rooms); j++) {
            var connected_room = ds_list_find_value(connected_rooms, j);

            // Generate a unique key for the connection
            var key1 = string(ds_map_find_value(room_, "id")) + "-" + string(ds_map_find_value(connected_room, "id"));
            var key2 = string(ds_map_find_value(connected_room, "id")) + "-" + string(ds_map_find_value(room_, "id"));

            // Check if the connection is already rendered
            if (!ds_map_exists(rendered_connections, key1) && !ds_map_exists(rendered_connections, key2)) {
                // Render the connection
                render_connection(grid_, room_, connected_room);

                // Mark the connection as rendered in both directions
                ds_map_add(rendered_connections, key1, true);
                ds_map_add(rendered_connections, key2, true);
            }
        }
    }

    // Then, render the rooms
    for (var i = 0; i < ds_list_size(_rooms_list); i++) {
        var room_ = ds_list_find_value(_rooms_list, i);
        render_room(grid_, room_);
    }
}

function render_connection(grid_, room1, room2) {
    var _x1 = ds_map_find_value(room1, "_x");
    var _y1 = ds_map_find_value(room1, "_y");
    var _x2 = ds_map_find_value(room2, "_x");
    var _y2 = ds_map_find_value(room2, "_y");
    var room_height1 = ds_map_find_value(room1, "height");
    var room_floor1 = _y1 + room_height1 / 2 - 2;
    var room_height2 = ds_map_find_value(room2, "height");
    var room_floor2 = _y2 + room_height2 / 2 - 2;

    var grid_width = ds_grid_width(grid_);
    var grid_height = ds_grid_height(grid_);

    // Determine vertical and horizontal directions
    var x_direction = _x1 < _x2 ? 1 : -1;
    var y_direction = _y1 < _y2 ? 1 : -1;

    // List to keep track of DOOR tile positions
    var door_positions = ds_list_create();

    // First move vertically to match y-coordinates
    if (_y2 > _y1) {
        // room_floor2 is above room_floor1
        for (var _y = room_floor1; _y != room_floor2 + 1; _y += y_direction) {
            if (_x1 - 1 >= 0 && _x1 - 1 < grid_width && _y >= 0 && _y < grid_height) grid_[# _x1 - 1, _y] = DOOR;
            if (_x1 >= 0 && _x1 < grid_width && _y >= 0 && _y < grid_height) grid_[# _x1, _y] = DOOR;
            if (_x1 + 1 >= 0 && _x1 + 1 < grid_width && _y >= 0 && _y < grid_height) grid_[# _x1 + 1, _y] = DOOR;
            ds_list_add(door_positions, [_x1 - 1, _y]);
            ds_list_add(door_positions, [_x1, _y]);
            ds_list_add(door_positions, [_x1 + 1, _y]);
        }
    } else if (_y2 < _y1) {
        // room_floor2 is below room_floor1
        for (var _y = room_floor1; _y != room_floor2 - 3; _y += y_direction) {
            if (_x1 - 1 >= 0 && _x1 - 1 < grid_width && _y >= 0 && _y < grid_height) grid_[# _x1 - 1, _y] = DOOR;
            if (_x1 >= 0 && _x1 < grid_width && _y >= 0 && _y < grid_height) grid_[# _x1, _y] = DOOR;
            if (_x1 + 1 >= 0 && _x1 + 1 < grid_width && _y >= 0 && _y < grid_height) grid_[# _x1 + 1, _y] = DOOR;
            ds_list_add(door_positions, [_x1 - 1, _y]);
            ds_list_add(door_positions, [_x1, _y]);
            ds_list_add(door_positions, [_x1 + 1, _y]);
        }
    }

    // Then move horizontally to match x-coordinates
    for (var _x = _x1; _x != _x2; _x += x_direction) {
        if (_x >= 0 && _x < grid_width && room_floor2 >= 0 && room_floor2 < grid_height) grid_[# _x, room_floor2] = DOOR;
        if (_x >= 0 && _x < grid_width && room_floor2 - 1 >= 0 && room_floor2 - 1 < grid_height) grid_[# _x, room_floor2 - 1] = DOOR;
        if (_x >= 0 && _x < grid_width && room_floor2 - 2 >= 0 && room_floor2 - 2 < grid_height) grid_[# _x, room_floor2 - 2] = DOOR;
        ds_list_add(door_positions, [_x, room_floor2]);
        ds_list_add(door_positions, [_x, room_floor2 - 1]);
        ds_list_add(door_positions, [_x, room_floor2 - 2]);
    }

    // Place WALL tiles around the DOOR tiles
    for (var i = 0; i < ds_list_size(door_positions); i++) {
        var door_position = ds_list_find_value(door_positions, i);
        var door_x = door_position[0];
        var door_y = door_position[1];

        // Check the 8 surrounding tiles and place WALL tiles if they are not DOOR tiles
        if (door_x - 1 >= 0 && door_x - 1 < grid_width && door_y - 1 >= 0 && door_y - 1 < grid_height && grid_[# door_x - 1, door_y - 1] != DOOR) grid_[# door_x - 1, door_y - 1] = WALL;
        if (door_x >= 0 && door_x < grid_width && door_y - 1 >= 0 && door_y - 1 < grid_height && grid_[# door_x, door_y - 1] != DOOR) grid_[# door_x, door_y - 1] = WALL;
        if (door_x + 1 >= 0 && door_x + 1 < grid_width && door_y - 1 >= 0 && door_y - 1 < grid_height && grid_[# door_x + 1, door_y - 1] != DOOR) grid_[# door_x + 1, door_y - 1] = WALL;
        if (door_x - 1 >= 0 && door_x - 1 < grid_width && door_y >= 0 && door_y < grid_height && grid_[# door_x - 1, door_y] != DOOR) grid_[# door_x - 1, door_y] = WALL;
        if (door_x + 1 >= 0 && door_x + 1 < grid_width && door_y >= 0 && door_y < grid_height && grid_[# door_x + 1, door_y] != DOOR) grid_[# door_x + 1, door_y] = WALL;
        if (door_x - 1 >= 0 && door_x - 1 < grid_width && door_y + 1 >= 0 && door_y + 1 < grid_height && grid_[# door_x - 1, door_y + 1] != DOOR) grid_[# door_x - 1, door_y + 1] = WALL;
        if (door_x >= 0 && door_x < grid_width && door_y + 1 >= 0 && door_y + 1 < grid_height && grid_[# door_x, door_y + 1] != DOOR) grid_[# door_x, door_y + 1] = WALL;
        if (door_x + 1 >= 0 && door_x + 1 < grid_width && door_y + 1 >= 0 && door_y + 1 < grid_height && grid_[# door_x + 1, door_y + 1] != DOOR) grid_[# door_x + 1, door_y + 1] = WALL;
    }

    ds_list_destroy(door_positions); // Clean up
}

function render_room(grid_, _room_name) {
    var _x_center = ds_map_find_value(_room_name, "_x");
    var _y_center = ds_map_find_value(_room_name, "_y");
    var width = ds_map_find_value(_room_name, "width");
    var height = ds_map_find_value(_room_name, "height");

    // Calculate the top-left corner of the room
    var _x_start = _x_center - floor(width / 2);
    var _y_start = _y_center - floor(height / 2);
    
    var grid_width = ds_grid_width(grid_);
    var grid_height = ds_grid_height(grid_);

    // Render the room
    for (var _y = 0; _y < height; _y++) {
        for (var _x = 0; _x < width; _x++) {
            var current_x = _x_start + _x;
            var current_y = _y_start + _y;

            // Check if the indices are within bounds
            if (current_x >= 0 && current_x < grid_width && current_y >= 0 && current_y < grid_height) {
                // Check if the room is the spawn room and set the top wall to ROOM tiles
                if (_x == 0 || _x == width - 1 || _y == 0 || _y == height - 1) {
                    // Only set to WALL if it is not a DOOR tile
                    if (grid_[# current_x, current_y] != DOOR) {
                        grid_[# current_x, current_y] = WALL;
                    }
                } else {
                    grid_[# current_x, current_y] = ROOM;
                }
            }
        }
    }
}

initialize_world(global.seed);