package rays


drag_mode := DragMode.RAYSOURCE

rays: [dynamic]Ray
new_rays_front: [dynamic]Ray
walls: []Wall = {
	{start_point = {500.0, 200.0}, end_point = {500.0, 400}},
	{start_point = {500.0, 400.0}, end_point = {800.0, 400}},
	{start_point = {100.0, 100.0}, end_point = {300.0, 400}},
	{start_point = {1000.0, 110.0}, end_point = {1000.0, 330}},
	{start_point = {1000.0, 330.0}, end_point = {800.0, 330}},
}
lenses: []Lens = {{{{500, 500}, 100}, {{440, 500}, 103}, 2.33}}
rays_drawing_type := RaysDrawingType.LINES
