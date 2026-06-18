shader_type canvas_item;

uniform sampler2D dissolve_noise;
uniform float dissolve_amount: hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color: source_color = vec4(0.8, 0.1, 0.1, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	float noise_val = texture(dissolve_noise, UV).r;
	if (noise_val < dissolve_amount) {
		tex_color.a = 0.0;
	} else if (noise_val < dissolve_amount + 0.05){
		tex_color = edge_color;
		tex_color.a *= texture(TEXTURE, UV).a;
	}
	
	COLOR = tex_color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
