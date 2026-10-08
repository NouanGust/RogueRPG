shader_type canvas_item;

uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float shine_speed : hint_range(0.0, 10.0) = 1.5;
uniform float shine_width : hint_range(0.0, 1.0) = 0.15;
uniform float shine_angle : hint_range(0.0, 360.0) = 45.0;

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    
    // Converte o ângulo para radianos para fazer a linha diagonal
    float rad = radians(shine_angle);
    vec2 dir = vec2(cos(rad), sin(rad));
    
    // Faz a linha se mover com o tempo (usando fract para repetir em loop)
    float pos = fract(TIME * shine_speed) * 2.0 - 0.5;
    float dot_prod = dot(UV, dir);
    
    // Calcula a distância do pixel até a linha brilhante
    float dist = abs(dot_prod - pos);
    
    // Suaviza as bordas do brilho
    float shine = smoothstep(shine_width, 0.0, dist);
    
    // Aplica o brilho somando à cor original, mas respeitando a transparência (alpha) do sprite
    COLOR = vec4(base_color.rgb + (shine_color.rgb * shine * base_color.a), base_color.a);
}