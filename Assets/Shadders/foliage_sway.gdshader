shader_type spatial;
render_mode cull_disabled;

uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float sway_speed : hint_range(0.1, 6.0) = 1.6;
uniform float sway_strength : hint_range(0.0, 0.35) = 0.06;
uniform float base_sway : hint_range(0.0, 1.0) = 0.0;
uniform float phase_offset : hint_range(0.0, 6.28318) = 0.0;
uniform float alpha_scissor : hint_range(0.0, 1.0) = 0.5;

void vertex() {
	// Y-Billboard: mantém o sprite alinhado à câmera no eixo horizontal
	vec3 cam_forward = normalize(vec3(INV_VIEW_MATRIX[2].x, 0.0, INV_VIEW_MATRIX[2].z));
	vec3 cam_right = normalize(cross(vec3(0.0, 1.0, 0.0), cam_forward));
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	float sz = length(MODEL_MATRIX[2].xyz);

	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(cam_right * sx, 0.0),
		vec4(0.0, sy, 0.0, 0.0),
		vec4(cam_forward * sz, 0.0),
		MODEL_MATRIX[3]
	);

	// Movimento leve de vento com fase única por posição no mundo
	float world_phase = MODEL_MATRIX[3].x * 1.7 + MODEL_MATRIX[3].z * 1.3 + phase_offset;
	float height_factor = mix(base_sway, 1.0, clamp(1.0 - UV.y, 0.0, 1.0));
	float gust = sin(TIME * sway_speed + world_phase) * 0.72
		+ sin(TIME * sway_speed * 2.15 + world_phase * 1.37) * 0.28;

	VERTEX.x += gust * sway_strength * height_factor;
	VERTEX.y += cos(TIME * sway_speed * 1.3 + world_phase) * sway_strength * 0.12 * height_factor;
}

void fragment() {
	vec4 tex = texture(albedo_texture, UV) * tint_color;
	ALBEDO = tex.rgb;
	ALPHA = tex.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor;
}
