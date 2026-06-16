shader_type canvas_item;

uniform bool active = false;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	if (active) {
		// Substitui a cor por branco, mantendo o canal alpha (transparência)
		COLOR = vec4(1.0, 1.0, 1.0, tex_color.a);
	} else {
		COLOR = tex_color;
	}
}