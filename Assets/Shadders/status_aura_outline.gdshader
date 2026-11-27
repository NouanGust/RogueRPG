shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform sampler2D sprite_texture : source_color, filter_nearest;
uniform vec4 region_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform bool aura_active = false;
uniform vec4 aura_color : source_color = vec4(1.0, 0.85, 0.25, 1.0);
uniform float outline_pixels : hint_range(1.0, 6.0) = 1.8;
uniform float halo_pixels : hint_range(1.0, 10.0) = 4.0;
uniform float pulse_speed : hint_range(0.5, 10.0) = 3.2;
uniform float aura_intensity : hint_range(0.5, 4.0) = 1.85;
uniform float halo_opacity : hint_range(0.0, 1.0) = 0.38;
uniform float rim_opacity : hint_range(0.0, 0.6) = 0.2;
uniform bool hit_flash = false;

void vertex() {
	// Y-Billboard idêntico ao billboard = 2 do AnimatedSprite3D
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

	// Pequeno avanço em Z para evitar z-fighting com o sprite base
	VERTEX.z += 0.002;
}

float sample_alpha(vec2 uv) {
	if (uv.x < region_rect.x || uv.x > region_rect.z || uv.y < region_rect.y || uv.y > region_rect.w) {
		return 0.0;
	}
	return texture(sprite_texture, uv).a;
}

void fragment() {
	if (!aura_active && !hit_flash) {
		discard;
	}

	float center_a = sample_alpha(UV);

	if (hit_flash && center_a > 0.5) {
		ALBEDO = vec3(1.0, 1.0, 1.0);
		ALPHA = 0.85;
	} else if (aura_active) {
		vec2 tex_size = vec2(textureSize(sprite_texture, 0));
		vec2 px = 1.0 / max(tex_size, vec2(1.0));
		vec2 step_in = px * outline_pixels;
		vec2 step_out = px * halo_pixels;

		// Anel interno (outline nítido) e verificação de borda interna
		float max_in = 0.0;
		float min_in = 1.0;
		vec2 dirs[8] = vec2[8](
			vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0),
			vec2(0.707, 0.707), vec2(-0.707, 0.707), vec2(0.707, -0.707), vec2(-0.707, -0.707)
		);
		float halo_sum = 0.0;
		for (int i = 0; i < 8; i++) {
			float a_in = sample_alpha(UV + dirs[i] * step_in);
			max_in = max(max_in, a_in);
			min_in = min(min_in, a_in);
			halo_sum += sample_alpha(UV + dirs[i] * step_out);
		}
		float halo_avg = halo_sum / 8.0;

		// Pulso suave + leve onda ascendente de brilho
		float pulse = 0.78 + 0.22 * sin(TIME * pulse_speed);
		float shimmer = 0.86 + 0.14 * sin(TIME * (pulse_speed * 1.35) - UV.y * 20.0);
		vec3 glow_rgb = aura_color.rgb * aura_intensity * pulse * shimmer;

		if (center_a < 0.15 && max_in > 0.5) {
			// Contorno luminoso principal
			ALBEDO = glow_rgb;
			ALPHA = aura_color.a * (0.85 + 0.15 * pulse);
		} else if (center_a < 0.15 && halo_avg > 0.08) {
			// Halo externo suave com brilho difuso
			ALBEDO = glow_rgb * 0.9;
			ALPHA = clamp(halo_avg * 1.4, 0.0, 1.0) * halo_opacity * pulse;
		} else if (center_a >= 0.5 && min_in < 0.5) {
			// Brilho sutil na borda interna do personagem
			ALBEDO = glow_rgb;
			ALPHA = rim_opacity * pulse * shimmer;
		} else {
			discard;
		}
	} else {
		discard;
	}
}
