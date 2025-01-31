
shader_type sky;
render_mode use_debanding;

uniform sampler2D sky_texture;
uniform sampler2D sky_color_ramp;
global uniform float aspect_ratio;

void sky() {
	vec2 use_uv = SKY_COORDS * vec2(aspect_ratio, 1.0) * 0.5 + vec2(0.25, 0.25);
	vec3 use_color = texture(sky_texture, use_uv).rgb;
	vec3 use_color_blurred = texture(sky_texture, use_uv, 6.0).rgb;
	vec3 ramp = texture(sky_color_ramp, -use_uv.yx + use_color.rg * 0.025 + use_color.gb * 0.025 + use_color.br * 0.025).rgb;
	use_color_blurred = max(use_color_blurred - 0.08, vec3(0.0));
	float one_zero_one = (sin(use_uv.y - 2.08) + 1.0) * 8.0;
	COLOR = mix((use_color + use_color_blurred) * 0.5, ramp, pow(one_zero_one, 0.333));
}
