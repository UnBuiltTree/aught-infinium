/// @description Insert description here
// You can write your code in this editor
if (damage_cooldown <= 0) {
	_health -= 5;
	show_debug_message(string(_health))
	damage_cooldown = 60;
	
	var _x_diffrence = x - other.x
	var hit_direction = abs(_x_diffrence)/_x_diffrence
	x_speed += hit_direction*2;
}
