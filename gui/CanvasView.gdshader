// Based on 2D Grid by hapenia
// https://godotshaders.com/shader/2d-grids/
shader_type canvas_item;
render_mode blend_mix;

// Transform.
uniform vec2 grid_offset = vec2(0.0);
uniform float grid_scale = 1.0;
// Ad-hoc fix to make the grid appear in line with the pixel grid.
uniform vec2 render_offset = vec2(0.0);
// Periods.
group_uniforms minor;
uniform float minor_period = 16.0;
uniform float minor_line_width : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform vec4 minor_color : source_color = vec4(1.0);
group_uniforms major;
uniform float major_period = 64.0;
uniform float major_line_width : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform vec4 major_color : source_color = vec4(1.0);


vec4 make_grid(vec2 size, vec2 uv, float period, float line_width, vec4 color) {
	vec2 period_base = vec2(period * grid_scale);
	
	vec2 r1 = mod(size * uv, period_base);
	vec2 x1 = step(period_base * (1.0 - line_width / grid_scale), r1);
	vec4 c1 = color;
	c1.a = dot(x1, vec2(1.0, 1.0));
	
	return c1;
}

void fragment() {
	vec2 area_size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 uv = ((grid_offset + render_offset) / area_size) + UV;
	
	vec4 c1 = make_grid(area_size, uv, minor_period, minor_line_width, minor_color);
	vec4 c2 = make_grid(area_size, uv, major_period, major_line_width, major_color);
	
	// Output.
	COLOR = mix(c1, c2, c2.a);
}
