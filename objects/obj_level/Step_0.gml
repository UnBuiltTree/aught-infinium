// Step event for obj_level

if (global.game_start == true) {
    var player_chunk_x = floor(obj_player.x / (CHUNK_SIZE_X * TILE_WIDTH));
    var player_chunk_y = floor(obj_player.y / (CHUNK_SIZE_Y * TILE_HEIGHT));

    // Load chunks within the load distance
    for (var dx = -load_distance; dx <= load_distance; dx++) {
        for (var dy = -load_distance; dy <= load_distance; dy++) {
            create_chunk(player_chunk_x + dx, player_chunk_y + dy);
        }
    }

    // Unload chunks outside the unload distance
    var key = ds_map_find_first(global.chunks);
    while (key != undefined) {
        var chunk_coords = string_split(key, "_");
        var chunk_x = real(chunk_coords[0]);
        var chunk_y = real(chunk_coords[1]);

        if (abs(chunk_x - player_chunk_x) > unload_distance || abs(chunk_y - player_chunk_y) > unload_distance) {
            destroy_chunk(chunk_x, chunk_y);
        }

        key = ds_map_find_next(global.chunks, key);
    }

    // Ensure that changed chunks are saved and reloaded correctly
    key = ds_map_find_first(global.changed_chunks);
    while (key != undefined) {
        var chunk_coords = string_split(key, "_");
        var chunk_x = real(chunk_coords[0]);
        var chunk_y = real(chunk_coords[1]);

        if (abs(chunk_x - player_chunk_x) <= reload_distance && abs(chunk_y - player_chunk_y) <= reload_distance && !ds_map_exists(global.chunks, key)) {
            create_chunk(chunk_x, chunk_y);
        }

        key = ds_map_find_next(global.changed_chunks, key);
    }
}
