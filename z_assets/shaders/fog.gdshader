shader_type canvas_item;

uniform sampler2D noise_texture: repeat_enable, filter_nearest;
instance uniform float density: hint_range(0.0, 1.0) = 0.25;
instance uniform float speed_x;
instance uniform float speed_y;
instance uniform float gap_density;
instance uniform float seed;

void fragment() {
	// make the fog move slowly
	vec2 uv = UV + vec2(speed_x, speed_y) * TIME;
	
	// sample the noise texture
	float noise = texture(noise_texture, uv).r;	
	
	// convert noise from [0.0, 1.0] to [-1.0, 1.0]
	float fog = noise * (1.0 / gap_density) - (1.0 / 2.0 * gap_density);
	
	// create voids by clamping to [0.0, 1.0]
	fog = clamp(fog, 0.0, 1.0);
	
	// apply the fog effect
	COLOR.a *= fog * density;
}
