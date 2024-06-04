
global.seed = irandom(99999999999);
show_debug_message("seed: " + string(global.seed));

gpu_set_texfilter(false); 

//List of tile types with auto-tile texture abilities
global.auto_tile_textures = ds_list_create();

global.short_auto_tile_textures = ds_list_create();
ds_list_add(global.short_auto_tile_textures, METAL);

// --- Macros for Boxels
#macro TILE_WIDTH 8
#macro TILE_HEIGHT 8

#macro CHUNK_SIZE_X 32
#macro CHUNK_SIZE_Y 32

#macro CHUNKS_NUM_X 128
#macro CHUNKS_NUM_Y 128

#macro BIOME_AIR 0
#macro BIOME_SURFACE 1
#macro BIOME_UNDERGROUND  2

#macro BIOME_BORDER 256

// --- The one and only void Boxel
#macro VOID 0


// --- Dev Boxels
#macro NULL 17
#macro WALL 18
#macro ROOM_SPACE 19
#macro DOOR 20
#macro ROOM 21
#macro AREA 22
#macro BORDER 40

// --- Spawning Boxels
#macro POTENTIAL_ENEMY_SPAWN 57
#macro ENEMY_SPAWN 58

// --- Real Boxels
#macro STONE 1024
#macro DIRT 1064
#macro STONE2 1104
#macro GRASS 1144
#macro METAL 1280

global.tile_types = [DIRT, STONE, STONE2, GRASS, METAL];
global.tile_count = array_length(global.tile_types);

// --- Map of tile variant amounts
global.tile_variants = ds_map_create();

ds_map_add(global.tile_variants, DIRT, 26); // DIRT has 26 variants
ds_map_add(global.tile_variants, METAL, 2); // METAL has 2 variants
ds_map_add(global.tile_variants, STONE, 26); // STONE has 26 variants
ds_map_add(global.tile_variants, STONE2, 26); // STONE2 has 26 variants
ds_map_add(global.tile_variants, GRASS, 26); // STONE2 has 26 variants
ds_map_add(global.tile_variants, BORDER, 8); // STONE2 has 26 variants

// --- Map of entity spawning tile and what object that spawn
global.entity_tiles = ds_map_create();
ds_map_add(global.entity_tiles, ENEMY_SPAWN, obj_enemy);

// Map to store entity sizes
global.entity_sizes = ds_map_create();
ds_map_add(global.entity_sizes, obj_enemy, 3); // obj_enemy is size 3

function create_ore(name, _id, color, _image_index, _variants, spawn_rate, generation_type) {
    var _ore = ds_map_create();
    _ore[? "name"] = name;
    _ore[? "ID"] = _id;
    _ore[? "color"] = color;
    _ore[? "tile_index"] = _image_index; // Assuming this is the index in the ore tileset
    _ore[? "tile_variants"] = _variants;
    _ore[? "spawn_rate"] = spawn_rate;
    _ore[? "generation_type"] = generation_type;
    _ore[? "perm_table"] = generate_permutation_table(global.seed+_id); // Create a new permutation table for each ore
    ds_map_add(global.ore_properties, name, _ore);
}



function initialize_global_variables(){
    
    global.perm_0 = undefined;
    global.perm_1 = undefined;
    global.perm_2 = undefined;
    global.perm_3 = undefined;
    global.perm_4 = undefined;
    global.perm_5 = undefined;
    global.perm_6 = undefined;
    global.perm_7 = undefined;
    global.perm_8 = undefined;
    global.perm_9 = undefined;
    global.perm_A = undefined;
    global.perm_B = undefined;
    global.perm_C = undefined;
    global.perm_D = undefined;
    global.perm_E = undefined;
    global.perm_F = undefined;
	
	global.perm_tex = undefined;
    
    global.perm_1d_0 = undefined;
    global.perm_1d_1 = undefined;
    global.perm_1d_2 = undefined;
    global.perm_1d_3 = undefined;
	
	global.perm_tex = generate_permutation_table(32);
    
    global.sim_start_size = 32;
    global.sim_size = 400;
    global.refresh_size = global.sim_size - 32;
    global.true_sim_size = global.sim_start_size;
    global.true_refresh_size = 0;
    global.refresh_counter = 0;
    global.refresh_rate = 1;
    global.curr_refresh_x = 0;
    global.simulation_box_x = room_width / 2;
    global.simulation_box_y = room_height / 2;
    global.player_spawn_x = room_width / 2;
    global.player_spawn_y = room_height / 2;
    
    global.last_sim_x = -1;
    global.last_sim_y = -1;
    
    global.x_scan_pos = 0;
    global.last_scan_x = -1;
    global.rate_count = 0;
    
    // Ensure global variables are initialized
    global.changed_chunks = ds_map_create();
    global.chunks = ds_map_create();
    global.chunk_tilemaps = ds_map_create();
	global.structure_flags = ds_map_create();
	global.structure_grids = ds_map_create();
	global.chunk_textures = ds_map_create();
	global.chunk_vertex_buffers = ds_map_create();
	global.ore_lists = ds_map_create();
	global.ore_properties = ds_map_create();
	

	vertex_format_begin();
	vertex_format_add_position_3d();
	vertex_format_add_color();
	vertex_format_add_texcoord();
	global.ore_vb_format = vertex_format_end();
	
	
	
	create_ore("iron", 1, #FFEEEE, 35, 4, 50, "veins");
	create_ore("coal", 2, #111122, 0, 4, 60, "splotchy");
	create_ore("copper", 3, #EE8844, 20, 4, 40, "veins");
	create_ore("gold", 4, #BB9911, 40, 4, 35, "veins");
	create_ore("ruby", 5, #cf6565, 10, 4, 30, "veins");
	create_ore("amethyst", 6, #ad65cf, 10, 4, 30, "veins");
	create_ore("emerald", 7, #6ecf65, 25, 4, 30, "veins");
	
}