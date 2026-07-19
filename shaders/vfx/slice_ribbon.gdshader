shader_type canvas_item;
render_mode unshaded;

uniform sampler2D broad_noise : repeat_enable, filter_linear;
uniform sampler2D fine_noise : repeat_enable, filter_linear;

uniform vec4 core_color : source_color = vec4(1.0, 0.98, 0.90, 1.0);
uniform vec4 hot_color : source_color = vec4(1.0, 0.48, 0.04, 1.0);
uniform vec4 energy_color : source_color = vec4(1.0, 0.09, 0.015, 1.0);
uniform vec4 void_color : source_color = vec4(0.45, 0.08, 1.0, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.025, 0.008, 0.06, 0.88);

uniform float core_width : hint_range(0.02, 0.5) = 0.12;
uniform float body_width : hint_range(0.1, 0.9) = 0.52;
uniform float edge_softness : hint_range(0.005, 0.25) = 0.065;
uniform float noise_scale : hint_range(0.5, 20.0) = 5.0;
uniform float noise_strength : hint_range(0.0, 0.5) = 0.12;
uniform vec2 noise_speed = vec2(-0.65, 0.17);
uniform float streak_scale : hint_range(1.0, 40.0) = 15.0;
uniform float streak_speed : hint_range(-10.0, 10.0) = 3.4;
uniform float distortion_strength : hint_range(0.0, 0.2) = 0.035;
uniform float glow_intensity : hint_range(0.0, 4.0) = 1.15;
uniform float overall_intensity : hint_range(0.0, 3.0) = 1.0;
uniform float lifetime_alpha : hint_range(0.0, 1.0) = 1.0;
uniform float release_pulse : hint_range(0.0, 1.0) = 0.0;
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform float combo_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float chromatic_amount : hint_range(0.0, 0.2) = 0.0;
uniform float time_offset = 0.0;

void fragment() {
	float t = TIME + time_offset;
	float across = abs(UV.y * 2.0 - 1.0);
	vec2 broad_uv = vec2(UV.x * noise_scale, UV.y * 1.7) + noise_speed * t;
	vec2 fine_uv = vec2(UV.x * noise_scale * 2.7, UV.y * 4.2) - noise_speed.yx * t * 1.8;
	float broad = texture(broad_noise, broad_uv).r;
	float fine = texture(fine_noise, fine_uv).r;
	float distortion = (broad - 0.5) * distortion_strength;
	float warped_across = across + distortion;

	float tail_fade = smoothstep(0.0, 0.10, UV.x);
	float head_fade = 1.0 - smoothstep(0.965, 1.0, UV.x);
	float age_fade = COLOR.a;
	float silhouette_limit = 0.94 - (broad - 0.5) * noise_strength;
	float silhouette = 1.0 - smoothstep(silhouette_limit - edge_softness, silhouette_limit, warped_across);

	float core = 1.0 - smoothstep(core_width, core_width + edge_softness, warped_across);
	float body = 1.0 - smoothstep(body_width, body_width + edge_softness * 1.5, warped_across);
	float void_edge = smoothstep(body_width * 0.72, body_width, warped_across) * silhouette;
	float shadow_edge = smoothstep(body_width, silhouette_limit, warped_across) * silhouette;

	float streak_wave = sin((UV.x * streak_scale - t * streak_speed + fine * 2.5) * 6.28318);
	float streak = smoothstep(0.62, 0.98, streak_wave) * body * (1.0 - core);
	float pulse_position = smoothstep(0.0, 1.0, release_pulse);
	float pulse = exp(-pow((UV.x - pulse_position) * 11.0, 2.0)) * release_pulse;

	float dissolve_noise = broad * 0.68 + fine * 0.32;
	float dissolve = smoothstep(dissolve_amount - 0.16, dissolve_amount + 0.10, dissolve_noise);
	float alpha = silhouette * tail_fade * head_fade * age_fade * lifetime_alpha * dissolve;

	vec3 color = shadow_color.rgb * shadow_edge;
	color = mix(color, void_color.rgb * glow_intensity, void_edge);
	color = mix(color, energy_color.rgb, body);
	color += hot_color.rgb * streak * 0.65;
	color = mix(color, core_color.rgb * (1.25 + pulse), core);
	color += void_color.rgb * void_edge * 0.32 * glow_intensity;
	float chromatic_edge = void_edge * chromatic_amount * (0.55 + fine * 0.45);
	color += vec3(chromatic_edge * 0.35, 0.0, chromatic_edge);
	color += core_color.rgb * hit_flash * core * 0.8;
	color *= overall_intensity * (1.0 + pulse * 0.75 + combo_intensity * 0.22);

	COLOR = vec4(color, alpha * max(max(core, body), shadow_edge * shadow_color.a));
}
