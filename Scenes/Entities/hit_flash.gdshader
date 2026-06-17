shader_type canvas_item;

// --- Controles do Hitflash ---
uniform bool active = false;

// --- Controles da Sombra ---
// Deslocamento em pixels (X, Y). Tente valores como (8.0, 8.0) para projetar diagonalmente
uniform vec2 shadow_offset = vec2(10.0, 10.0); 
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5); // Preto com 50% de transparência

void fragment() {
	// 1. Coleta a textura deslocada para ser a sombra
	vec2 shadow_uv = UV - (shadow_offset * TEXTURE_PIXEL_SIZE);
	vec4 shadow_tex = vec4(0.0);
	
	// Evita que a sombra "vaze" repetindo pelas bordas (wrapping)
	if (shadow_uv.x >= 0.0 && shadow_uv.x <= 1.0 && shadow_uv.y >= 0.0 && shadow_uv.y <= 1.0) {
		shadow_tex = texture(TEXTURE, shadow_uv);
	}

	// 2. Coleta a cor original do sprite
	vec4 base_color = texture(TEXTURE, UV);

	// 3. Aplica o efeito do Hitflash se o personagem tomar dano
	if (active && base_color.a > 0.0) {
		base_color = vec4(1.0, 1.0, 1.0, base_color.a); // Fica todo branco
	}

	// 4. Mistura tudo: Se tem sprite, desenha sprite. Se não tem sprite mas tem sombra, desenha a sombra.
	if (base_color.a > 0.0) {
		COLOR = base_color;
	} else if (shadow_tex.a > 0.0) {
		// Pinta a silhueta deslocada com a cor e transparência da sombra
		COLOR = vec4(shadow_color.rgb, shadow_tex.a * shadow_color.a); 
	} else {
		// Fundo transparente
		COLOR = vec4(0.0);
	}
}