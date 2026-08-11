shader_type spatial;
// FogPuff — soft drifting ground-haze billboard for the lived-in street and the
// Warden's choir-house. Transparent, unlit, depth-never so it reads as thick air
// instead of a wall; the radial UV falloff keeps every puff a soft ball.
// Environment layer (assets/environment/) — decorative only, no shadows.

render_mode blend_mix, unshaded, cull_disabled, depth_draw_never;

uniform vec4 fog_color : source_color = vec4(0.42, 0.5, 0.54, 1.0);
uniform float softness : hint_range(0.1, 1.0) = 0.55;
uniform float intensity : hint_range(0.1, 1.0) = 0.5;

void fragment() {
	vec2 c = UV - vec2(0.5);
	float r = length(c) * 2.0;
	float a = 1.0 - smoothstep(softness, 1.0, r);
	ALBEDO = fog_color.rgb;
	ALPHA = a * intensity;
	EMISSION = fog_color.rgb * a * intensity * 0.7;
}
