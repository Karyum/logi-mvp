shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform float outline_size = 2.0;

void fragment() {
    vec4 base = texture(TEXTURE, UV);
    if (base.a == 0.0) {
        // Expand check radius based on outline size
        for (float x = -outline_size; x <= outline_size; x++) {
            for (float y = -outline_size; y <= outline_size; y++) {
                vec2 offset = vec2(x, y) / TEXTURE_PIXEL_SIZE;
                if (texture(TEXTURE, UV + offset).a > 0.0) {
                    COLOR = outline_color;
                }
            }
        }
        discard;
    }
    COLOR = base;
}
