shader_type canvas_item;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    vec4 light_blue = vec4(0.5, 0.5, 0.5,1);

    // Use the texture's alpha but apply consistent light blue color
    COLOR = vec4(light_blue.rgb, tex_color.a * light_blue.a);
}