package rays

import "core:testing"


@(test)
test_get_ray_end_point :: proc(t: ^testing.T) {
	ray := Ray{{10,10}, {1,0}, 3.0}
	end_point := get_ray_end_point(ray)
	testing.expect(t, end_point == {13, 10}, "something is wrong with value of end_point")
}


@(test)
test_get_points_on_circle :: proc(t: ^testing.T) {
	// TODO
}