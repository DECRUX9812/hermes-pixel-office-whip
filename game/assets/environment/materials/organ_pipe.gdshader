shader_type spatial;
// OrganPipe — copper resonator pipe with a vertical tonal gradient (mouth dark,
// crown bright) and faint glowing bands, so the Warden's organ reads as a warm
// living instrument rather than plain cylinders. The bands stay under the glow
// budget: low energy, no shadow casting. Uses CylinderMesh UV.y along the pipe
// height (pipes are laid horizontal in the arena, so the gradient runs lengthwise).
// Environment layer (assets/environment/) — decorative only.

uniform vec3 bottom_color : source_color = vec3(0.42, 0.22, 0.11);
uniform vec3 top_color : source_color = vec3(0.88, 0.58, 0.38);
uniform float metallic = 1.0;
uniform float roughness = 0.35;
uniform vec3 band_color : source_color = vec3(1.0, 0.62, 0.28);
uniform float band_energy = 1.15;
uniform float rim_width = 0.16;
uniform float rim_intensity = 0.3;
uniform vec3 rim_color : source_color = vec3(0.05, 0.028, 0.012);

void fragment() {
	float h = clamp(UV.y, 0.0, 1.0);
	vec3 base = mix(bottom_color, top_color, h);
	float band = smoothstep(0.14, 0.0, abs(fract(h * 5.0) - 0.5) - 0.36);
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float edge = pow(1.0 - ndv, 1.6) * rim_width;
	base = mix(base, rim_color, clamp(edge, 0.0, 1.0) * rim_intensity);
	ALBEDO = base;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	EMISSION = band_color * band * band_energy;
}
