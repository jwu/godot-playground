shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, fog_disabled;

uniform float grid_size = 2000.0;
uniform float cell_size = 1.0;
uniform float min_pixels_between_cells = 2.0;
uniform float line_width_pixels = 1.0;
uniform float min_lod_power = -3.0;
uniform float max_lod_power = 4.0;
uniform float camera_lod_distance = 1.0;
uniform float camera_far_clip = 2000.0;
uniform bool camera_is_orthogonal = false;
uniform bool debug_lod_colors = false;
uniform bool enable_grazing_opacity = true;
uniform vec4 thin_line_color : source_color = vec4(0.42, 0.42, 0.42, 0.45);
uniform vec4 thick_line_color : source_color = vec4(0.62, 0.62, 0.62, 0.65);

varying vec3 world_position;


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


float grid_line_alpha(vec2 uv, float current_cell_size) {
	// 贴近 Blender 的屏幕空间线宽/AA 思路：线条以 cell 边界为中心，
	// 用坐标导数估算一像素在 grid-space 中的宽度，避免 mod 单侧覆盖导致旋转时忽明忽暗。
	vec2 coord = uv / current_cell_size;
	vec2 pixel_size = max(abs(dFdx(coord)) + abs(dFdy(coord)), vec2(0.00001));
	vec2 distance_to_line = min(fract(coord), 1.0 - fract(coord));
	vec2 distance_pixels = distance_to_line / pixel_size;

	// 以像素为单位做 1px 宽的 AA 过渡，避免线条变细后出现硬边/闪烁。
	float half_line_width_pixels = max(line_width_pixels, 0.25) * 0.5;
	vec2 coverage = 1.0 - smoothstep(
		vec2(max(half_line_width_pixels - 0.5, 0.0)),
		vec2(half_line_width_pixels + 0.5),
		distance_pixels
	);
	return max(coverage.x, coverage.y);
}


void fragment() {
	vec2 uv = world_position.xz;

	float safe_cell_size = max(cell_size, 0.00001);
	float min_power = min(min_lod_power, max_lod_power - 2.0);
	float max_power = max(max_lod_power, min_power + 2.0);
	float min_lod_cell_size = safe_cell_size * pow(10.0, min_power);
	float lod_distance = max(camera_lod_distance, min_lod_cell_size);
	float current_lod_power = clamp(
		floor(log(lod_distance / safe_cell_size) / log(10.0)),
		min_power,
		max_power
	);

	// 贴近 Blender：level 的小数部分基于相邻 step 间的线性距离，而不是 log 空间。
	// 到达上限后仍使用虚拟 next step 计算 fade，等价于 Blender 最后一档的 curr * 10。
	float current_lod_cell_size = safe_cell_size * pow(10.0, current_lod_power);
	float next_lod_cell_size = current_lod_cell_size * 10.0;
	float lod_fade = clamp(
		(lod_distance - current_lod_cell_size) / max(next_lod_cell_size - current_lod_cell_size, 0.00001),
		0.0,
		1.0
	);

	// 贴近 Blender 的 use_level_offset：围绕当前 LOD 绘制 lower/current/upper 三层。
	// 每层单独 clamp 到数学生成的 8 档范围，行为类似 Blender 对查表 level 的 clamp。
	float lod0_power = clamp(current_lod_power - 1.0, min_power, max_power);
	float lod1_power = clamp(current_lod_power, min_power, max_power);
	float lod2_power = clamp(current_lod_power + 1.0, min_power, max_power);
	float lod0_cell_size = safe_cell_size * pow(10.0, lod0_power);
	float lod1_cell_size = safe_cell_size * pow(10.0, lod1_power);
	float lod2_cell_size = safe_cell_size * pow(10.0, lod2_power);

	float lod0_alpha = grid_line_alpha(uv, lod0_cell_size) * (1.0 - lod_fade);
	float lod1_alpha = grid_line_alpha(uv, lod1_cell_size);
	float lod2_alpha = grid_line_alpha(uv, lod2_cell_size);

	// 贴近 Blender：更高层级线条遮住低层级重合线，避免多层线叠加造成亮度跳变。
	float lod2_visible_alpha = lod2_alpha;
	float lod1_visible_alpha = lod1_alpha * (1.0 - lod2_visible_alpha);
	float lod0_visible_alpha = lod0_alpha * (1.0 - lod1_alpha) * (1.0 - lod2_visible_alpha);

	// 贴近 Blender：current 层从强调色平滑过渡到普通色，lower 层按 level 小数淡出。
	vec4 lod0_color = thin_line_color;
	vec4 lod1_color = mix(thick_line_color, thin_line_color, lod_fade);
	vec4 lod2_color = thick_line_color;
	if (debug_lod_colors) {
		// 调试三层 LOD：蓝色=lower/更细层，绿色=current/当前层，红色=upper/更粗层。
		// 只替换 RGB，不提高 alpha，确保 debug 开关前后的可见性可直接对比。
		lod0_color = vec4(0.1, 0.35, 1.0, lod0_color.a);
		lod1_color = vec4(0.1, 1.0, 0.25, lod1_color.a);
		lod2_color = vec4(1.0, 0.15, 0.1, lod2_color.a);
	}

	float lod0_layer_alpha = lod0_visible_alpha * lod0_color.a;
	float lod1_layer_alpha = lod1_visible_alpha * lod1_color.a;
	float lod2_layer_alpha = lod2_visible_alpha * lod2_color.a;
	float line_alpha = clamp(lod0_layer_alpha + lod1_layer_alpha + lod2_layer_alpha, 0.0, 1.0);
	vec3 line_color = (
		lod0_color.rgb * lod0_layer_alpha +
		lod1_color.rgb * lod1_layer_alpha +
		lod2_color.rgb * lod2_layer_alpha
	) / max(line_alpha, 0.00001);

	// 贴近 Blender：网格范围边缘淡出。透视用半径线性淡出，正交用平方淡出。
	float half_grid_size = max(grid_size * 0.5, 0.00001);
	vec2 grid_center = MODEL_MATRIX[3].xz;
	vec2 normalized_grid_coord = (world_position.xz - grid_center) / half_grid_size;
	float edge_opacity = 1.0 - min(1.0, length(normalized_grid_coord));
	if (camera_is_orthogonal) {
		edge_opacity = pow(1.0 - min(1.0, dot(normalized_grid_coord, normalized_grid_coord)), 2.0);
	}

	// 贴近 Blender：低视角看地面时淡出，指数使用 pow3 而不是更激进的高次幂。
	float grazing_opacity = 1.0;
	if (enable_grazing_opacity) {
		vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_position);
		float view_floor_factor = abs(dot(view_dir, vec3(0.0, 1.0, 0.0)));
		grazing_opacity = 1.0 - pow(1.0 - view_floor_factor, 3.0);
	}

	// 贴近 Blender：靠近 far clip 的距离淡出，从 far/2 开始逐渐消失。
	float far_clip = max(camera_far_clip, 0.00001);
	float camera_distance = length(CAMERA_POSITION_WORLD - world_position);
	float distance_opacity = 1.0 - smoothstep(0.0, 0.5 * far_clip, camera_distance - 0.5 * far_clip);

	ALBEDO = line_color;
	ALPHA = line_alpha * edge_opacity * distance_opacity * grazing_opacity;

	// 贴近 Blender：低 alpha 时使用 stipple 虚线/抖动丢弃，避免透明深度混合带来的糊状残影。
	const float dash_width = 4.0;
	const float fade_start = 0.1;
	vec2 dash_coord = uv / lod1_cell_size;
	vec2 dash_distance_to_line = min(fract(dash_coord), 1.0 - fract(dash_coord));
	float dash_axis = dash_distance_to_line.x < dash_distance_to_line.y ? FRAGCOORD.y : FRAGCOORD.x;
	if (ALPHA < fade_start && ALPHA / fade_start < fract(dash_axis / dash_width)) {
		discard;
	}

	if (ALPHA <= 0.001) {
		discard;
	}
}
