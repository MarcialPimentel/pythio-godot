// Noir backdrop: dark vertical gradient, a low red haze behind the party,
// a vignette and a little film grain. Tweak the uniforms in the Inspector.
shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.07, 0.06, 0.08, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.11, 0.08, 0.08, 1.0);
uniform vec4 haze_color : source_color = vec4(0.45, 0.06, 0.06, 1.0);
uniform vec2 haze_center = vec2(0.5, 0.42);
uniform float haze_strength : hint_range(0.0, 1.0) = 0.35;
uniform float vignette : hint_range(0.0, 2.0) = 0.9;
uniform float grain : hint_range(0.0, 0.2) = 0.04;
uniform float floor_y : hint_range(0.0, 1.0) = 0.66;

float rand(vec2 co) { return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec2 uv = UV;
	vec3 col = mix(top_color.rgb, bottom_color.rgb, uv.y);
	vec2 d = (uv - haze_center) * vec2(1.0, 1.7);
	col += haze_color.rgb * haze_strength * exp(-dot(d, d) * 5.0);
	// soft dark floor band the party stands on
	float fy = (uv.y - floor_y) * 9.0;
	col *= 1.0 - 0.45 * exp(-fy * fy) * smoothstep(0.9, 0.2, abs(uv.x - 0.5) * 2.0);
	vec2 v = uv - 0.5;
	col *= 1.0 - vignette * dot(v, v);
	col += (rand(uv * 731.0 + fract(TIME)) - 0.5) * grain;
	COLOR = vec4(col, 1.0);
}
