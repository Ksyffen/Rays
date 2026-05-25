package rays

import rl "vendor:raylib"
import m "core:math"

Wall :: struct #all_or_none {
	start_point: rl.Vector2,
	end_point:   rl.Vector2,
}

Circle :: struct #all_or_none {
	center: rl.Vector2,
	radius: f32,
}

get_points_on_circle :: proc(circle: Circle, rad_step: f32 = 0.15) -> (points: [dynamic]rl.Vector2) {
	for i := f32(0); i <= 2 * rl.PI; i += rad_step {
		circle_point_1 := circle.center + circle.radius * rl.Vector2{m.cos_f32(i), m.sin_f32(i)}
		append(&points, circle_point_1)
	}
	return
}


Lens :: struct #all_or_none {
	circle:  Circle,
	// TODO:
	ref_coeff: f32,
}

Ray :: struct #all_or_none {
	start_point: rl.Vector2,
	direction:   rl.Vector2,
	length:      f32,
}

get_ray_end_point :: proc(ray: Ray) -> (end_point: rl.Vector2) {
	end_point = ray.start_point + ray.direction * ray.length
	return
}
