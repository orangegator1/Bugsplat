shader_type canvas_item;

// Increase this value (e.g., 2.0 or 4.0) to make it sharper
// Decrease it to make it smoother
uniform float sharpness : hint_range(1.0, 10.0) = 4.0;

void fragment() {
    vec2 size = vec2(textureSize(TEXTURE, 0));
    vec2 pixel = UV * size;
    
    // The "Magic" math for fractional scaling
    // It creates a very steep gradient at the edge of pixels
    vec2 edge_pos = fract(pixel) - 0.5;
    vec2 smooth_edge = clamp(edge_pos * sharpness + 0.5, 0.0, 1.0);
    vec2 final_pixel = floor(pixel) + smooth_edge;
    
    COLOR = texture(TEXTURE, final_pixel / size);
}