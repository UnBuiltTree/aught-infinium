function generate_world(_step){
	function spawn_player(_x, _y){
				//creates a player within the room and sets their ID
				var _player = instance_create_layer(_x, _y,"Instances", obj_player);
				_player.player_initialize();
				_player.player_local_id = 0;
				show_debug_message("Player Spawned: " + string(_player.player_local_id));
				global.player_alive = true;
				global.player_grounded = false;
			}

	switch(_step) {
		case 0:
			global.cam_mode = 0;
			
			global.chunks = ds_map_create();
			// Data structure to store chunks and their tilemaps
			global.chunk_tilemaps = ds_map_create();
			
			global.active_tiles = ds_map_create();
			
			initialize_global_variables();
			
			global._cam = instance_create_layer(room_width/2, room_height/2,"instances", obj_cam_pos);
			
			break;
	    case 1:
		//create level object
		
			global._level = instance_create_layer(room_width/2, room_height/2,"Level", obj_level);
	        break;
		case 2:
	        break;
		case 3:
			//creating world base
	        break;
		case 4:
			//cretaing structures
	        break;
		case 5:
			//pass 1
	        break;
		case 6:
			//pass 2
	        break;
	    case 7:
	        // spawn_player
			spawn_player(global.player_spawn_x, global.player_spawn_y );
	        break;
	    case 8:
	        window_set_cursor(cr_none);
	        break;
	    // Add more steps as needed
	    default:
	        // Finish generation
	        global.world_generated = true;
	        break;
	}
}

