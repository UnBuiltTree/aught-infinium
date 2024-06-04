/// @description Insert description here
if (_grounded)&&((_state_duration == 0)) {
    _state = choose("move_left", "move_right", "wait");
    switch (_state) {
        case "move_left":
            _state_time = 30 * 2;
            break;
        case "move_right":
            _state_time = 30 * 2;
            break;
        case "wait":
            _state_time = 30 * 4;
            break;
        default:
            //do nothing
            break;
    }
    alarm[0] = _state_time;
}