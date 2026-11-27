shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform sampler2D sprite_texture : source_color, filter_nearest;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float colorize_strength : hint_range(0.0, 1.0) = 0.88;
uniform float glow_boost : hint_range(1.0, 3.0) = 1.45;

void vertex() {
	// Full billboard idêntico ao billboard = 1 do AnimatedSprite3D
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	float sz = length(MODEL_MATRIX[2].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(INV_VIEW_MATRIX[0].xyz * sx, 0.0),
		vec4(INV_VIEW_MATRIX[1].xyz * sy, 0.0),
		vec4(INV_VIEW_MATRIX[2].xyz * sz, 0.0),
		MODEL_MATRIX[3]
	);
}

void fragment() {
	vec4 tex = texture(sprite_texture, UV);
	if (tex.a < 0.05) {
		discard;
	}
	float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	float hot_core = smoothstep(0.68, 1.0, luma);
	vec3 recolored = mix(tint_color.rgb * clamp(luma * 1.45, 0.18, 1.25), vec3(1.0), hot_core * 0.45);
	ALBEDO = mix(tex.rgb * tint_color.rgb, recolored, colorize_strength) * glow_boost;
	ALPHA = tex.a * tint_color.a;
}
