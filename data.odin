package rays

rays_number : =i32(100.0)


drag_mode := DragMode.POINT_SOURCE

rays: [dynamic]Ray

walls: []Wall = {
	{start_point = {100.0, 100.0}, end_point = {300.0, 400}},
	{start_point = {1000.0, 110.0}, end_point = {1000.0, 330}},
	{start_point = {1000.0, 330.0}, end_point = {800.0, 330}},
}

lenses: []Lens = {{circle={center= {400,500}, radius = 100.0}, ref_coeff=1.33, color={10, 210, 241, 120}},
				 {circle={center= {440,500}, radius = 110.0}, ref_coeff=0.88, color={200, 210, 241, 120}}}
rays_drawing_type := RaysDrawingType.LINES

is_debug_mode: bool = true