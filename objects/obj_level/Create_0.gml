// Initialize chunk management variables
load_x = 0;
load_y = 0;

load_distance = 2;
unload_distance = 3;
reload_distance = 3;

surface_y = 0; // Adjust this value as needed
randomize()
global.seed = irandom(99999999999)
show_debug_message("seed: " + string(global.seed))

function initialize_world(seed) {
    if (is_undefined(global.perm_0)) {
        global.perm_0 = generate_permutation_table(seed);
    }
    if (is_undefined(global.perm_1)) {
        global.perm_1 = generate_permutation_table(seed+1);
    }
    if (is_undefined(global.perm_2)) {
        global.perm_2 = generate_permutation_table(seed+2);
    }
    if (is_undefined(global.perm_3)) {
        global.perm_3 = generate_permutation_table(seed+3);
    }
    if (is_undefined(global.perm_4)) {
        global.perm_4 = generate_permutation_table(seed+4);
    }
    if (is_undefined(global.perm_5)) {
        global.perm_5 = generate_permutation_table(seed+5);
    }
	
    if (is_undefined(global.perm_1d_0)) {
        global.perm_1d_0 = generate_permutation_table(seed);
    }

    // Generate the surface line for the entire world or for initial chunks
    var initial_chunk_x = 0; // Example starting chunk x
    var initial_chunk_width = 16; // Example chunk width
    var noise_scale = 5;
    var base_height = 24; // Adjust this value as needed
    var height_range = 10; // Adjust this value as needed

    global.surface_line = generate_surface_line(initial_chunk_x, initial_chunk_width, noise_scale, base_height, height_range, seed);
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

function get_surface_level_at_x(_x, _noise_scale, _base_height, _height_range, _seed) {
    // Ensure the permutation table is generated
    if (is_undefined(global.perm_1d_0)) {
        global.perm_1d_0 = generate_permutation_table(_seed);
    }

    var noise_value = perlin_noise_1d_multi_octave(global.perm_1d_0, _x / _noise_scale, 4, 0.5);
    noise_value = (noise_value + 1) / 2; // Normalize to 0-1
    var surface_level = _base_height + noise_value * _height_range;
    return surface_level;
}

initialize_world(global.seed);

// Save the game state
function save_game() {
    var buffer = buffer_create(1024, buffer_grow, 1);
    buffer_write(buffer, buffer_string, json_stringify(global.changed_chunks));
    buffer_save(buffer, "savegame.dat");
    buffer_delete(buffer);
}

// Load the game state
function load_game() {
    if (file_exists("savegame.dat")) {
        var buffer = buffer_load("savegame.dat");
        var json_data = buffer_read(buffer, buffer_string);
        buffer_delete(buffer);
        global.changed_chunks = json_parse(json_data);
    } else {
        global.changed_chunks = ds_map_create();
    }
}
	
function create_chunk(_x, _y) {
    var chunk_key = string(_x) + "_" + string(_y);
    if (!ds_map_exists(global.chunks, chunk_key)) {
        var grid;

        // Load the chunk if it has been changed and saved
        if (ds_map_exists(global.changed_chunks, chunk_key)) {
            grid = ds_map_find_value(global.changed_chunks, chunk_key);
            show_debug_message("Loading changed chunk: " + chunk_key);
        } else {
            grid = ds_grid_create(CHUNK_SIZE_X, CHUNK_SIZE_Y);
            var biome = determine_biome(_x, _y);
            
            // Create the grid based on the biome
            switch (biome) {
				case BIOME_BORDER:
					ds_grid_clear(grid, BORDER);
					break;
                case BIOME_AIR:
                    // Air biome: set the entire grid to VOID
                    ds_grid_clear(grid, VOID);
                    break;

                case BIOME_UNDERGROUND:
                    // Underground biome: set the entire grid to STONE
                    for (var i = 0; i < CHUNK_SIZE_X; i++) {
                        for (var j = 0; j < CHUNK_SIZE_Y; j++) {
                            ds_grid_set(grid, i, j, STONE);
                        }
                    }
                    break;

                case BIOME_SURFACE:
                    // Surface biome: use the current generation method
                    //var noise_scale_surface = 192;
					var noise_scale_surface = 128;
                    var base_height = 0;
                    var height_range = 128; // Adjust as needed
                    var surface_line = generate_surface_line(_x, CHUNK_SIZE_X, noise_scale_surface, base_height, height_range, 42); // Example seed

                    // Initialize the grid based on the surface line
                    for (var i = 0; i < CHUNK_SIZE_X; i++) {
                        for (var j = 0; j < CHUNK_SIZE_Y; j++) {
                            var world_y = _y * CHUNK_SIZE_Y + j;
                            var distance_to_surface = world_y - surface_line[i];

                            if (world_y < surface_line[i]) {
                                ds_grid_set(grid, i, j, VOID);
                            } else {
                                // Dynamically adjust noise scales based on distance to surface
                                var noise_scale_horz = 3 + (distance_to_surface / 3);
                                var noise_scale_vert = 12;
                                
                                var depth_stone_fade = 128;

                                // Calculate noise value for stone/dirt placement
                                var noise_value_0 = perlin_noise(global.perm_0, (_x * CHUNK_SIZE_X + i) / noise_scale_vert, world_y / noise_scale_horz);
                                noise_value_0 = (noise_value_0 + 1) / 2; // Normalize to 0-1

                                // Adjust noise value based on distance to surface
                                var adjusted_noise_value = lerp(noise_value_0, 0.55, 1 - min(distance_to_surface / CHUNK_SIZE_Y, 1));

                                // Further adjust noise value to make stone more common as depth increases
                                var depth_factor = max((world_y - surface_line[i]) / depth_stone_fade, 0); // Adjust as needed
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

                //add more biomes here

                default:
                    // Default case to handle any undefined biomes
                    for (var i = 0; i < CHUNK_SIZE_X; i++) {
                        for (var j = 0; j < CHUNK_SIZE_Y; j++) {
                            ds_grid_set(grid, i, j, VOID);
                        }
                    }
                    break;
            }
        }

        ds_map_add(global.chunks, chunk_key, grid);
        create_tilemap(_x, _y);
        draw_tiles_to_tilemap(_x, _y); 
    }
}



function destroy_chunk(_x, _y) {
    var chunk_key = string(_x) + "_" + string(_y);
    if (ds_map_exists(global.chunks, chunk_key)) {
        var grid = ds_map_find_value(global.chunks, chunk_key);

		if (ds_map_exists(global.changed_chunks, chunk_key)){
	        // Save the grid if it has been changed
	        ds_map_add(global.changed_chunks, chunk_key, grid);
		}

        // Destroy the grid only if it is not in changed_chunks
        if (!ds_map_exists(global.changed_chunks, chunk_key)) {
            ds_grid_destroy(grid);
        }

        ds_map_delete(global.chunks, chunk_key);
        destroy_tilemap(_x, _y);
    }
}

// Determine biome based on chunk coordinates
function determine_biome(chunk_x, chunk_y) {
    var biome;

    // Check if the chunk is beyond the border limit
    if (abs(chunk_x) > 9600 || abs(chunk_y) > 9600) {
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
					tilemap_set(tilemap, texturize_tile(tile), i, j);
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



	



