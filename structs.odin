package rays

import rl "vendor:raylib"


Wall :: struct #all_or_none {
	start_point: rl.Vector2,
	end_point:   rl.Vector2,
}

Circle :: struct #all_or_none {
	center: rl.Vector2,
	radius: f32,
}

Lens :: struct #all_or_none {
	positive:  Circle,
	negative:  Circle,
	ref_coeff: f32,
}

Ray :: struct #all_or_none {
	start_point: rl.Vector2,
	direction:   rl.Vector2,
	length:      f32,
}