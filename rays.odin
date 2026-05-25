package rays

import m "core:math"
import rl "vendor:raylib"



main :: proc() {
	init_screen()
	loop()
}

init_screen :: proc() {
	rl.InitWindow(i32(SCREEN_SIZE.x), i32(SCREEN_SIZE.y), SCREEN_NAME)
	rl.SetTargetFPS(60)
}

loop :: proc() {
	defer rl.CloseWindow()
	for !rl.WindowShouldClose() {
		input()
		loop_iteration()

		rl.BeginDrawing()
		rl.ClearBackground(BG_COLOR)

		draw()
		rl.EndDrawing()
	}
}

loop_iteration :: proc() {

	update_rays_pos: {
		if drag_mode == .RAYSOURCE {
			clear(&rays)
			start_point := rl.GetMousePosition()
			for elem in 1 ..= RAYS_NUMBER {
				angle := 2.0 * (rl.PI / RAYS_NUMBER) * f32(elem)
				direction := rl.Vector2Normalize(
					(rl.Vector2{m.cos_f32(angle), m.sin_f32(angle)}),
				)
				new_ray := Ray {
					start_point = start_point,
					direction   = direction,
					length      = RAY_LENGTH,
				}
				append(&rays, new_ray)
			}
		}
	}

	update_negative_circle: {
		if drag_mode == .NEGATIVE_CIRCLE {
			start_point := rl.GetMousePosition()
			lenses[0].negative.center = start_point
			for &r in rays {
				r.length = RAY_LENGTH
			}
		}
	}

	collision_with_walls: {
		for &ray in rays {
			nearest_intersection: rl.Vector2
			is_intesection: bool
			for wall in walls {
				intersection_point: rl.Vector2
				ray_end_point := get_end_point(
					ray.start_point,
					ray.direction,
					ray.length,
				)
				is_intesection = rl.CheckCollisionLines(
					ray.start_point,
					ray_end_point,
					wall.start_point,
					wall.end_point,
					&intersection_point,
				)
				if is_intesection {
					if rl.Vector2Distance(
						   nearest_intersection,
						   ray.start_point,
					   ) >
					   rl.Vector2Distance(
						   intersection_point,
						   ray.start_point,
					   ) {
						nearest_intersection = intersection_point
					}
				}
			}
			if nearest_intersection != {} {
				ray.length = rl.Vector2Distance(
					nearest_intersection,
					ray.start_point,
				)
			}

		}
	}

	lens: {
		clear(&new_rays_front)
		for l in lenses {
			for &r in rays {
				intesection_points := get_circle_intersection_points(
					l.positive,
					l.negative,
				)

				ray_with_lens_intesection: rl.Vector2
				is_intesection: bool
				for i in 0 ..< len(intesection_points) {
					if i == len(intesection_points) - 1 {
						// is_intesection = rl.CheckCollisionLines(r.start_point, get_end_point(r.start_point, r.direction, r.length), intesection_points[i], intesection_points[0], &ray_with_lens_intesection)
						break
					}

					is_intesection = rl.CheckCollisionLines(
						r.start_point,
						get_end_point(r.start_point, r.direction, r.length),
						intesection_points[i],
						intesection_points[i + 1],
						&ray_with_lens_intesection,
					)
					if is_intesection {
						break
					}
				}
				if is_intesection {
					r.length = rl.Vector2Distance(
						ray_with_lens_intesection,
						r.start_point,
					)

					old_angle := rl.Vector2Angle(
						r.direction,
						ray_with_lens_intesection - l.negative.center,
					)

					rot_angle :=
						m.asin_f32(
							AIR_REFF_COEFF /
							l.ref_coeff *
							m.sin_f32(old_angle),
						) -
						old_angle

					new_ray := Ray {
						ray_with_lens_intesection,
						rl.Vector2Rotate(r.direction, -rot_angle),
						RAY_LENGTH,
					}
					append(&new_rays_front, new_ray)
				}
			}
		}
	}
}

input :: proc() {
	if rl.IsKeyDown(.ONE) {
		rays_drawing_type = RaysDrawingType.LINES
	}
	if rl.IsKeyDown(.TWO) {
		rays_drawing_type = RaysDrawingType.TRIANGLES
	}
	if rl.IsKeyDown(.THREE) {
		drag_mode = .RAYSOURCE
	}
	if rl.IsKeyDown(.FOUR) {
		drag_mode = .NEGATIVE_CIRCLE
	}
}

draw :: proc() {

	// walls
	for w in walls do rl.DrawLineV(w.start_point, w.end_point, WALL_COLOR)

	// lenses
	for l in lenses {
		// additive
		rl.DrawCircleV(l.positive.center, l.positive.radius, LENS_COLOR)
		rl.DrawCircleV(l.negative.center, l.negative.radius, BG_COLOR)
	}

	// temp
	intesection_points := get_circle_intersection_points(
		lenses[0].positive,
		lenses[0].negative,
	)
	for p, i in intesection_points {
		rl.DrawCircleLinesV(p, 3.0, rl.MAGENTA)

		if i == len(intesection_points) - 1 {
			continue
		}
		rl.DrawLineV(p, intesection_points[i + 1], rl.YELLOW)
	}

	// rays
	switch rays_drawing_type {
	case RaysDrawingType.LINES:
		for r in rays {
			line_start_pos := r.start_point
			line_end_pos := get_end_point(r.start_point, r.direction, r.length)
			rl.DrawLineV(line_start_pos, line_end_pos, RAY_COLOR)
		}
		for r in new_rays_front {
			line_start_pos := r.start_point
			line_end_pos := get_end_point(r.start_point, r.direction, r.length)
			rl.DrawLineV(line_start_pos, line_end_pos, RAY_COLOR)
		}
	case RaysDrawingType.TRIANGLES:
		for i in 0 ..< len(rays) {
			// j is index of second ray
			j := i + 1
			if j == len(rays) {
				j = 0
			}

			ray_1_start_pos := rays[i].start_point
			ray_1_end_pos := get_end_point(
				rays[i].start_point,
				rays[i].direction,
				rays[i].length,
			)
			ray_2_end_pos := get_end_point(
				rays[j].start_point,
				rays[j].direction,
				rays[j].length,
			)
			rl.DrawTriangle(
				ray_1_start_pos,
				ray_2_end_pos,
				ray_1_end_pos,
				RAY_COLOR,
			)
		}
	}

}

// ---

get_end_point :: proc(
	start_point, direction: rl.Vector2,
	length: f32,
) -> (
	end_point: rl.Vector2,
) {
	end_point = start_point + direction * length
	return
}

get_circle_intersection_points :: proc(
	additive_circle: Circle,
	negative_circle: Circle,
) -> [dynamic]rl.Vector2 {
	rad_step: f32 = 0.09

	intesection_points: [dynamic]rl.Vector2

	additive_circle_points: [dynamic]rl.Vector2
	negative_circle_points: [dynamic]rl.Vector2
	for i := f32(-m.PI / 2.0); i <= 3 / 2 * rl.PI; i += rad_step {
		circle_point_1 :=
			additive_circle.center +
			additive_circle.radius * rl.Vector2{m.cos_f32(i), m.sin_f32(i)}
		circle_point_2 :=
			negative_circle.center +
			negative_circle.radius * rl.Vector2{m.cos_f32(i), m.sin_f32(i)}

		append(&additive_circle_points, circle_point_1)
		append(&negative_circle_points, circle_point_2)
	}
	for n in negative_circle_points {
		if rl.CheckCollisionPointCircle(
			n,
			additive_circle.center,
			additive_circle.radius,
		) {
			append(&intesection_points, n)
		}
	}
	return intesection_points
}
