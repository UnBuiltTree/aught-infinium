/// @function draw_bold_rectangle(x1, y1, x2, y2, thickness)
/// @param {real} x1 The x coordinate of the first corner
/// @param {real} y1 The y coordinate of the first corner
/// @param {real} x2 The x coordinate of the opposite corner
/// @param {real} y2 The y coordinate of the opposite corner
/// @param {real} thickness The thickness of the border

function draw_bold_rectangle(x1, y1, x2, y2, thickness) {
    var half_thickness = floor(thickness / 2);
    for (var i = 0; i < thickness; i++) {
        draw_rectangle(x1 + i, y1 + i, x2 - i, y2 - i, true);
    }
}


/// @func round_by_units(_value, _units, _type)
/// @desc Rounds a value by the specified units using the specified rounding type.
/// @arg {real} _value
/// @arg {real} _units
/// @arg {string} _type

function round_by_units(_value, _units, _type) {
    switch (_type) {
        case "floor":
            _value = floor(_value / _units) * _units;
            break;
        case "ceil":
            _value = ceil(_value / _units) * _units;
            break;
        default:
            _value = round(_value / _units) * _units;
            break;
    }
    return _value;
}

function fade(t) {
    return t * t * t * (t * (t * 6 - 15) + 10);
}

function lerp(a, b, t) {
    return a + t * (b - a);
}

function grad(hash, _x, _y) {
    var h = hash & 15;
    var u = (h < 8) ? _x : _y;
    var v = (h < 4) ? _y : ((h == 12 || h == 14) ? _x : 0);
    return (((h & 1) == 0) ? u : -u) + (((h & 2) == 0) ? v : -v);
}

// Generate Permutation Table
function generate_permutation_table(seed) {
    random_set_seed(seed);  // Set the seed for the random number generator
    var perm = [];
    for (var i = 0; i < 256; i++) {
        perm[i] = irandom(255);
    }
    for (var i = 0; i < 256; i++) {
        perm[256 + i] = perm[i];
    }
    return perm;
}

function perlin_noise(_perm, _x, _y) {
    var X = floor(_x) & 255;
    var Y = floor(_y) & 255;
    var xf = _x - floor(_x);
    var yf = _y - floor(_y);

    var u = fade(xf);
    var v = fade(yf);

    var a = _perm[X] + Y;
    var b = _perm[X + 1] + Y;

    var aa = _perm[a] & 255;
    var ab = _perm[a + 1] & 255;
    var ba = _perm[b] & 255;
    var bb = _perm[b + 1] & 255;

    var x1 = lerp(grad(_perm[aa], xf, yf), grad(_perm[ba], xf - 1, yf), u);
    var x2 = lerp(grad(_perm[ab], xf, yf - 1), grad(_perm[bb], xf - 1, yf - 1), u);

    return lerp(x1, x2, v);
}


function perlin_noise_1d(_perm, _x) {
    var X = floor(_x) & 255;
    var xf = _x - floor(_x);

    var u = fade(xf);

    var a = _perm[X];
    var b = _perm[X + 1];

    var x1 = lerp(grad_1d(_perm[a], xf), grad_1d(_perm[b], xf - 1), u);

    return x1;
}

function grad_1d(hash, _x) {
    var h = hash & 15;
    var u = (h < 8) ? _x : 0;
    return ((h & 1) == 0) ? u : -u;
}


function upscale_and_blur_grid(source_grid, src_width, src_height, dst_width, dst_height) {
    var upscale_factor_x = dst_width / src_width;
    var upscale_factor_y = dst_height / src_height;
    var dest_grid = ds_grid_create(dst_width, dst_height);

    // Upscale
    for (var _x = 0; _x < dst_width; _x++) {
        for (var _y = 0; _y < dst_height; _y++) {
            var src_x = _x / upscale_factor_x;
            var src_y = _y / upscale_factor_y;
            var x0 = floor(src_x);
            var y0 = floor(src_y);
            var x1 = min(x0 + 1, src_width - 1);
            var y1 = min(y0 + 1, src_height - 1);
            var dx = src_x - x0;
            var dy = src_y - y0;

            var v00 = ds_grid_get(source_grid, x0, y0);
            var v10 = ds_grid_get(source_grid, x1, y0);
            var v01 = ds_grid_get(source_grid, x0, y1);
            var v11 = ds_grid_get(source_grid, x1, y1);

            var v0 = lerp(v00, v10, dx);
            var v1 = lerp(v01, v11, dx);
            var value = lerp(v0, v1, dy);

            ds_grid_set(dest_grid, _x, _y, value);
        }
    }

    // Apply blur
    var blurred_grid = ds_grid_create(dst_width, dst_height);
    for (var _x = 1; _x < dst_width - 1; _x++) {
        for (var _y = 1; _y < dst_height - 1; _y++) {
            var sum = 0;
            for (var dx = -1; dx <= 1; dx++) {
                for (var dy = -1; dy <= 1; dy++) {
                    sum += ds_grid_get(dest_grid, _x + dx, _y + dy);
                }
            }
            ds_grid_set(blurred_grid, _x, _y, sum / 9);
        }
    }

    ds_grid_destroy(dest_grid);
    return blurred_grid;
}
	
function generate_1d_perlin_noise(_perm, length, scale, base_height, height_range, octaves, persistence) {
    var noise_array = array_create(length, 0);
    for (var _x = 0; _x < length; _x++) {
        var noise_value = perlin_noise_1d_multi_octave(_perm, _x / scale, octaves, persistence);
        noise_value = (noise_value + 1) / 2; // Normalize to 0-1
        noise_value = base_height + (noise_value - 0.5) * height_range;
        noise_array[_x] = noise_value;
    }
    return noise_array;
}

function perlin_noise_1d_multi_octave(_perm, _x, octaves, persistence) {
    var total = 0;
    var frequency = 1;
    var amplitude = 1;
    var max_value = 0;  // Used for normalization

    for (var i = 0; i < octaves; i++) {
        total += perlin_noise_1d(_perm, _x * frequency) * amplitude;
        
        max_value += amplitude;

        amplitude *= persistence;
        frequency *= 2;
    }

    return total / max_value;  // Normalize the result
}

function chaos_noise(_perm, _x, _y) {
    var X = floor(_x) & 255;
    var Y = floor(_y) & 255;
    
    var hash = _perm[(X + _perm[Y & 255]) & 255];

    return (hash / 255.0) * 2 - 1; // Normalize to the range [-1, 1]
}

function chaos_noise_irange(_perm, _x, _y, _min, _max) {
    var X = floor(_x) & 255;
    var Y = floor(_y) & 255;

    var hash = _perm[(X + _perm[Y & 255]) & 255];

    // Normalize the hash value to the range [0, 1]
    var normalized_value = hash / 255.0;

    // Scale and shift the normalized value to the desired integer range
    var range = _max - _min + 1;
    var random_integer = floor(normalized_value * range) + _min;

    return random_integer;
}
	