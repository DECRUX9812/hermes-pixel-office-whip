shader_type spatial;
// InkEdge — selective graphic-novel ink outline + grounded PBR surface.
// PART OF THE BLOCKOUT / PROTOTYPE MATERIAL LAYER. Replace with authored
// production materials; the uniforms are kept intentionally close to the
// StandardMaterial3D settings used elsewhere so the language stays one knob.
//
// The ink term is a gentle fresnel darkening tuned so that on primitive/box
// geometry (whose faces have constant normals) it reads as a *thin* silhouette
// edge rather than painting whole faces black. Readability rule from the brief:
// never hide composition under darkness — the ink term is deliberately weak.
//
// It also carries a shallow "sheen" falloff so flat faces keep their albedo.

uniform vec3 albedo : source_color = vec3(0.075, 0.082, 0.095);
uniform float metallic = 0.0;
uniform float roughness = 0.9;
uniform float rim_width = 0.18;
uniform float rim_intensity = 0.5;
uniform vec3 rim_color : source_color = vec3(0.012, 0.014, 0.018);
uniform vec3 emission : source_color = vec3(0.0);
uniform float emission_energy = 1.0;

void fragment() {
	vec3 base = albedo;
	// Fresnel-like edge term. N·V is 1 when facing the camera. The exponent
	// stays low (1.6) so only near-grazing faces darken, not broad ones.
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float edge = pow(1.0 - ndv, 1.6) * rim_width;
	base = mix(base, rim_color, clamp(edge, 0.0, 1.0) * rim_intensity);
	ALBEDO = base;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	if (emission_energy > 0.0) {
		EMISSION = emission * emission_energy;
	}
}
