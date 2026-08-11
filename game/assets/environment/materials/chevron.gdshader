shader_type spatial;
// Chevron — diagonal warning stripes for the collapsed conduit. Kept close to
// the blockout ink language (flat albedo + modest emissive on the bright band)
// so the hazard tape reads as painted-on rather than plastic.
// Environment layer (assets/environment/) — decorative only.

render_mode cull_disabled;

uniform vec3 dark_color : source_color = vec3(0.09, 0.055, 0.04);
uniform vec3 warn_color : source_color = vec3(0.96, 0.58, 0.18);
uniform float stripe_width = 0.22;
uniform float band_energy = 1.3;

void fragment() {
	float stripe = step(0.5, fract((UV.x + UV.y) / stripe_width));
	vec3 base = mix(dark_color, warn_color, stripe);
	ALBEDO = base;
	METALLIC = 0.2;
	ROUGHNESS = 0.55;
	EMISSION = warn_color * band_energy * stripe * 0.9;
}
