/// @description Insert description here
// You can write your code in this editor

if (global.debug_mode) {
    // Draw event for obj_level

    // Set the color and width for drawing
    draw_set_color(c_purple);
    var _alpha = 0.75;
    draw_set_alpha(_alpha);

    // Get player's current chunk coordinates
    var player_chunk_x = floor(obj_player.x / (CHUNK_SIZE_X * TILE_WIDTH));
    var player_chunk_y = floor(obj_player.y / (CHUNK_SIZE_Y * TILE_HEIGHT));

    // Draw chunk borders and coordinates

    for (var dx = -load_distance - 1; dx <= load_distance + 1; dx++) {
        for (var dy = -load_distance - 1; dy <= load_distance + 1; dy++) {
            var chunk_x = player_chunk_x + dx;
            var chunk_y = player_chunk_y + dy;

            var x1 = chunk_x * CHUNK_SIZE_X * TILE_WIDTH;
            var y1 = chunk_y * CHUNK_SIZE_Y * TILE_HEIGHT;
            var x2 = x1 + CHUNK_SIZE_X * TILE_WIDTH;
            var y2 = y1 + CHUNK_SIZE_Y * TILE_HEIGHT;
			
			if round(chunk_x/2) != chunk_x/2 {
				if round(chunk_y/2) != chunk_y/2 {
					draw_set_color(#00ff00);
				} else {
					draw_set_color(#00ffff);
				}
			} else {
				if round(chunk_y/2) != chunk_y/2 {
					draw_set_color(#ff00ff);
				} else {
					draw_set_color(#ffff00);
				}
			}

			
            draw_rectangle(x1+2, y1+2, x2-3, y2-3, true);
			
			if (global.cam_mode == 0){
				var biome = determine_biome(chunk_x, chunk_y);
			
				draw_set_font(fnt_debug_massive); // Set the font to fnt_debug
	            // Draw chunk info text at the center of the chunk
	            var text = string(chunk_x) + ", " + string(chunk_y);
				var text_width = string_width(text);
				var text_height = string_height(text);
				var text_x = (x1 + x2) / 2 - text_width / 2;
				var text_y = (y1 + y2) / 2 - text_height;
			
				draw_set_font(fnt_debug_large); 
			
				var text_biome = return_biome_name(biome);
				var text_biome_width = string_width(text_biome);
				var text_biome_height = string_height(text_biome);
				var text_biome_x = (x1 + x2) / 2 - text_biome_width / 2;
				var text_biome_y = text_y + text_height; // Position below the main text
				draw_set_color(c_white);
				draw_set_font(fnt_debug_massive);
				draw_text(text_x, text_y, text);
				draw_set_font(fnt_debug_large); 
				draw_text(text_biome_x, text_biome_y, text_biome);
				draw_set_alpha(_alpha);
				draw_set_color(c_white); // Set color for text
			}
        }
    }

    // Calculate and draw the load zone as a single large rectangle
    draw_set_color(#880000);
    var load_x1 = (player_chunk_x - load_distance) * CHUNK_SIZE_X * TILE_WIDTH;
    var load_y1 = (player_chunk_y - load_distance) * CHUNK_SIZE_Y * TILE_HEIGHT;
    var load_x2 = (player_chunk_x + load_distance + 1) * CHUNK_SIZE_X * TILE_WIDTH;
    var load_y2 = (player_chunk_y + load_distance + 1) * CHUNK_SIZE_Y * TILE_HEIGHT;
    draw_bold_rectangle(load_x1, load_y1, load_x2, load_y2, 8);

    // Calculate and draw the reload zone as a single large rectangle
    draw_set_color(#ff8800);
    var reload_x1 = (player_chunk_x - reload_distance) * CHUNK_SIZE_X * TILE_WIDTH;
    var reload_y1 = (player_chunk_y - reload_distance) * CHUNK_SIZE_Y * TILE_HEIGHT;
    var reload_x2 = (player_chunk_x + reload_distance + 1) * CHUNK_SIZE_X * TILE_WIDTH;
    var reload_y2 = (player_chunk_y + reload_distance + 1) * CHUNK_SIZE_Y * TILE_HEIGHT;
    draw_bold_rectangle(reload_x1, reload_y1, reload_x2, reload_y2, 16);

    // Reset drawing settings
    draw_set_alpha(1);
}
