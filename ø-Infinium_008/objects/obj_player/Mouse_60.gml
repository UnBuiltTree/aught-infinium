/// @description Insert description here
// You can write your code in this editor
switch (placing_tile_id) {
    case DIRT:
        placing_tile_id = METAL;
        break;
	case METAL:
        placing_tile_id = STONE;
        break;
	case STONE:
        placing_tile_id = STONE2;
        break;
	case STONE2:
        placing_tile_id = DIRT;
        break;
    default:
        placing_tile_id = DIRT;
        break;
}