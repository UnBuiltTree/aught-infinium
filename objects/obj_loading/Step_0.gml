// obj_loader Step Event

if (!global.world_generated) {
    // Call the generation script with the current step
    generate_world(global.generation_step);
    
    // Move to the next step
    global.generation_step += 1;
    
    // Check if the generation is complete
    if (global.generation_step > global.total_steps) {
        global.world_generated = true;
    }
}
else {
    // World generation is complete, proceed to the game
    // Hide the loading screen and start the game
	global.game_start = true;
    instance_destroy(obj_loading);
}