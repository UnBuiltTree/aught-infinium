// List of tile types with auto-tile texture abilities
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
#macro SURFACE 21
#macro GROUND 22
#macro BORDER 40

// --- Spawning Boxels
#macro POTENTIAL_ENEMY_SPAWN 57
#macro ENEMY_SPAWN 58

// --- Real Boxels
#macro DIRT 1064
#macro METAL 1280
#macro STONE 1024
#macro STONE2 1104
#macro GRASS 1144

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
			
			global.perm_1d_0 = undefined;
			global.perm_1d_1 = undefined;
			global.perm_1d_2 = undefined;
			global.perm_1d_3 = undefined;
			
			global.sim_start_size = 32;
			global.sim_size = 320
			//512, 576, 640, 704, 768, 832, 896, 960, 1024, 1088
			global.refresh_size = global.sim_size-32
			global.true_sim_size = global.sim_start_size;
			global.true_refresh_size = 0;
			global.refresh_counter = 0;
			global.refresh_rate = 1;
			global.curr_refresh_x = 0;
			global.simulation_box_x = room_width/2;
			global.simulation_box_y = room_height/2;
			global.player_spawn_x = room_width/2;
			global.player_spawn_y = room_height/2;
			
			
		    global.last_sim_x = -1;
		    global.last_sim_y = -1;
		 
		    global.x_scan_pos = 0;
		    global.last_scan_x = -1;
			global.rate_count = 0;
			
			// Ensure global variables are initialized
			global.changed_chunks = ds_map_create();
			global.chunks = ds_map_create();
			global.chunk_tilemaps = ds_map_create();
}