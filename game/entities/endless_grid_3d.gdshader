shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, fog_disabled;

uniform float grid_size = 2000.0;
uniform float cell_size = 1.0;
uniform float min_pixels_between_cells = 2.0;
uniform float line_width_pixels = 2.0;
uniform vec4 thin_line_color : source_color = vec4(0.25, 0.25, 0.25, 0.45);
uniform vec4 thick_line_color : source_color = vec4(0.38, 0.38, 0.38, 0.75);

varying vec3 world_position;


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


float grid_line_alpha(vec2 uv, float current_cell_size, vec2 dudv) {
	vec2 cell = uv / current_cell_size;
	vec2 cell_dudv = max(dudv / current_cell_size, vec2(0.00001));
	vec2 dist_to_line = abs(fract(cell - 0.5) - 0.5);
	vec2 line_width = max(cell_dudv * line_width_pixels, vec2(0.00001));
	vec2 coverage = 1.0 - clamp(dist_to_line / line_width, vec2(0.0), vec2(1.0));
	return max(coverage.x, coverage.y);
}


void fragment() {
	vec2 uv = world_position.xz;
	vec2 dudv = vec2(
		length(vec2(dFdx(uv.x), dFdy(uv.x))),
		length(vec2(dFdx(uv.y), dFdy(uv.y)))
	);

	float safe_cell_size = max(cell_size, 0.00001);
	float derivative_length = max(length(dudv), 0.00001);
	float lod_level = max(0.0, log((derivative_length * min_pixels_between_cells) / safe_cell_size) / log(10.0) + 1.0);
	float lod_power = floor(lod_level);
	float lod_fade = fract(lod_level);

	float lod0_cell_size = safe_cell_size * pow(10.0, lod_power);
	float lod1_cell_size = lod0_cell_size * 10.0;
	float lod2_cell_size = lod1_cell_size * 10.0;

	float lod0_alpha = grid_line_alpha(uv, lod0_cell_size, dudv);
	float lod1_alpha = grid_line_alpha(uv, lod1_cell_size, dudv);
	float lod2_alpha = grid_line_alpha(uv, lod2_cell_size, dudv);

	vec4 line_color = thin_line_color;
	float line_alpha = lod0_alpha * (1.0 - lod_fade);

	if (lod2_alpha > 0.0) {
		line_color = thick_line_color;
		line_alpha = lod2_alpha;
	} else if (lod1_alpha > 0.0) {
		line_color = mix(thick_line_color, thin_line_color, lod_fade);
		line_alpha = lod1_alpha;
	}

	float half_grid_size = max(grid_size * 0.5, 0.00001);
	float distance_opacity = 1.0 - clamp(length(world_position.xz - CAMERA_POSITION_WORLD.xz) / half_grid_size, 0.0, 1.0);
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_position);
	float grazing_opacity = 1.0 - pow(1.0 - abs(dot(view_dir, vec3(0.0, 1.0, 0.0))), 16.0);

	ALBEDO = line_color.rgb;
	ALPHA = line_color.a * line_alpha * distance_opacity * grazing_opacity;

	if (ALPHA <= 0.001) {
		discard;
	}
}
