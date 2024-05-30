/// @description Frame Rate

switch (frame) {
    case 0:
        frame++
        break;
	case 1:
        frame++
        break;
	case 2:
        frame++
        break;
	case 3:
        frame = 0;
        break;
    default:
        frame = 0;
        break;
}

alarm[0] = 60*0.2;
