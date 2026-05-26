package rays

// import "core:math/linalg"
// import "core:fmt"
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
	for !rl.WindowShouldClose() {
		input()
		loop_iteration()
		draw_all()
	}
	rl.CloseWindow()
}


loop_iteration :: proc() {
	if is_mouse_move() || rl.GetKeyPressed() != rl.KeyboardKey.KEY_NULL {
		// delete all rays
		clear(&rays)

		drag: {
			switch drag_mode {
			case .POINT_SOURCE:
				start_point := rl.GetMousePosition()
				for elem in 1 ..= rays_number {
					angle := 2.0 * (rl.PI / f32(rays_number)) * f32(elem)
					direction := rl.Vector2Normalize((rl.Vector2{m.cos_f32(angle), m.sin_f32(angle)}))
					new_ray := Ray {
						start_point = start_point,
						direction   = direction,
						length      = RAY_LENGTH,
					}
					append(&rays, new_ray)
				}
			case .DIRECTIONAL_SOURCE:
				direction := rl.Vector2Normalize(rl.GetMousePosition() - SCREEN_SIZE / 2)
				for a: f32 = 0.0; a <= 2 * rl.PI; a += 0.033 {
					new_ray := Ray {
						start_point = SCREEN_SIZE /
							2.0 + RAY_LENGTH * 1.5 * rl.Vector2{m.cos_f32(a), m.sin_f32(a)},
						direction   = direction,
						length      = RAY_LENGTH * 10.0,
					}
					append(&rays, new_ray)
				}
			case .CIRCLE:
				start_point := rl.GetMousePosition()
				lenses[0].circle.center = start_point
				for &r in rays {
					r.length = RAY_LENGTH
				}
			}
		}


		lens: {
			for l in lenses {
				for &r in rays {
					// points of circle
					points := get_points_on_circle(l.circle)

					nearest_intesection: rl.Vector2
					is_nearest_intesection: bool

					// TODO: case when i == len(points)
					// finds nearest_intesection
					for i in 0 ..< len(points) - 1 {

						ray_intesection: rl.Vector2
						is_intesection := rl.CheckCollisionLines(
							r.start_point,
							get_ray_end_point(r),
							points[i],
							points[i + 1],
							&ray_intesection,
						)


						if is_intesection {
							// if ray start on lens surface
							if rl.CheckCollisionPointLine(r.start_point, points[i], points[i + 1], threshold=2,) do continue


							// length between ray.start_point and intesection
							current_intesection_length := rl.Vector2Distance(r.start_point, ray_intesection)
							nearest_intesection_length := rl.Vector2Distance(r.start_point, nearest_intesection)

							if current_intesection_length < nearest_intesection_length || nearest_intesection == {}{
								nearest_intesection = ray_intesection
								is_nearest_intesection = true
							}
						}
					}

					// if there is an intesection
					if is_nearest_intesection {
						// setting length of ray
						r.length = rl.Vector2Distance(
							nearest_intesection,
							r.start_point,
						)

						normal: rl.Vector2
						n1: f32
						n2: f32

						// setting normal n1, n2
						if rl.CheckCollisionPointCircle(
							r.start_point,
							l.circle.center,
							l.circle.radius,
						) {
							// ray.start_point is inside circle
							n1, n2 = l.ref_coeff, AIR_REFF_COEFF
							normal = rl.Vector2Normalize(l.circle.center - nearest_intesection)
						} else {
							// ray.start_point is outside of circle
							n1, n2 = AIR_REFF_COEFF, l.ref_coeff
							normal = rl.Vector2Normalize(nearest_intesection - l.circle.center)
						}

						coeff := n1 / n2

						norm_dir_dot := -rl.Vector2DotProduct(normal, r.direction)
						k :f32 = 1.0 - m.pow(coeff, 2) * (1.0 - m.pow(norm_dir_dot, 2))
						if k >= 0 {
							//====//
						    new_direction := coeff * r.direction + (coeff * norm_dir_dot - m.sqrt_f32(k)) * normal
							//====//
							new_ray := Ray {
								start_point = nearest_intesection,
								direction   = rl.Vector2Normalize(new_direction),
								length      = RAY_LENGTH * 2,
								}
							append(&rays, new_ray)
						}

						// else{
						// 	new_ray := Ray {
						// 		start_point = nearest_intesection,
						// 		direction   =linalg.reflect(r.direction, normal),
						// 		length      = RAY_LENGTH * 2,
						// 		}
						// 	append(&rays, new_ray)

						// }

						}


					}
				}
		}


		collision_with_walls: {
			for &ray in rays {
				nearest_intersection: rl.Vector2
				is_intesection: bool
				for wall in walls {
					intersection_point: rl.Vector2
					ray_end_point := get_ray_end_point(ray)
					is_intesection = rl.CheckCollisionLines(
						ray.start_point,
						ray_end_point,
						wall.start_point,
						wall.end_point,
						&intersection_point,
					)
					if is_intesection {
						if rl.Vector2Distance(nearest_intersection, ray.start_point) >
						   rl.Vector2Distance(intersection_point, ray.start_point) {
							nearest_intersection = intersection_point
						}
					}
				}
				if nearest_intersection != {} {
					ray.length = rl.Vector2Distance(nearest_intersection, ray.start_point)
				}
			}
		}
	}
}


input :: proc() {
	if rl.IsKeyDown(.ONE) do rays_drawing_type = RaysDrawingType.LINES
	else if rl.IsKeyDown(.TWO) do rays_drawing_type = RaysDrawingType.TRIANGLES
	else if rl.IsKeyDown(.THREE) do drag_mode = .POINT_SOURCE
	else if rl.IsKeyDown(.FOUR) do drag_mode = .CIRCLE
	else if rl.IsKeyDown(.FIVE) do drag_mode = .DIRECTIONAL_SOURCE
	else if rl.IsKeyReleased(.D){
		if is_debug_mode do is_debug_mode = false
		else do is_debug_mode = true
	}
	else if drag_mode == .POINT_SOURCE{
		if rl.IsKeyReleased(.EQUAL) do rays_number += 10.0
		else if rl.IsKeyReleased(.MINUS){
			rays_number -= 10.0
			if rays_number <= 0 do rays_number = 10
		}	
	}
	else if drag_mode == .CIRCLE{
		if rl.IsKeyReleased(.EQUAL) do lenses[0].circle.radius += 10.0
		else if rl.IsKeyReleased(.MINUS){
			lenses[0].circle.radius -= 10.0
			if lenses[0].circle.radius <= 0 do lenses[0].circle.radius = 10
		}	
	}
}


draw_all :: proc() {

	rl.BeginDrawing()

	// bg
	rl.ClearBackground(BG_COLOR)


	// walls
	for w in walls do rl.DrawLineV(w.start_point, w.end_point, WALL_COLOR)

	// lenses
	for l in lenses do rl.DrawCircleV(l.circle.center, l.circle.radius, l.color)

	// points on circle for debug
	for_debug:{
		if is_debug_mode{
			for l in lenses{
				points := get_points_on_circle(l.circle)

				for p, i in points {
					rl.DrawCircleLinesV(p, 3.0, rl.MAGENTA)

					if i == len(points) - 1 {
						rl.DrawLineV(p, points[0], rl.YELLOW)
						break
					}
					rl.DrawLineV(p, points[i + 1], rl.YELLOW)
				}

			}

		}
	}


	all_rays:{
	switch rays_drawing_type {
	case RaysDrawingType.LINES:
		for r in rays {
			line_start_pos := r.start_point
			line_end_pos := get_ray_end_point(r)
			rl.DrawLineV(line_start_pos, line_end_pos, RAY_COLOR)
		}
	// TODO: CORECT TRIANGLE DRAWWING!!
	case RaysDrawingType.TRIANGLES:
		for i in 0 ..< len(rays) {
			// j is index of second ray
			j := i + 1
			if j == len(rays) {
				j = 0
			}

			ray_1_start_pos := rays[i].start_point
			ray_1_end_pos := get_ray_end_point(rays[i])
			ray_2_end_pos := get_ray_end_point(rays[j])
			rl.DrawTriangle(ray_1_start_pos, ray_2_end_pos, ray_1_end_pos, RAY_COLOR)
		}
	}
	}

			rl.EndDrawing()
}



is_mouse_move :: proc() -> bool {
	return rl.GetMouseDelta() != {0, 0}
}
