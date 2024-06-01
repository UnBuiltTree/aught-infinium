/// @description Insert description here
// You can write your code in this editor
//draw_self()

var text_ = "Press any key to start"
var text_width = string_width(text_);
var text_height = string_height(text_);
var text_x = (room_width)/2 - text_width/2;
var text_y = room_height/2 - text_height/2; // Position below the main text

draw_set_font(fnt_debug_large); 
draw_text(text_x, text_y, "Press any key to start");
draw_set_color(c_white); // Set color for text