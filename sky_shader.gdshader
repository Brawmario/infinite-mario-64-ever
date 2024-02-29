
// NOTE: Shader automatically converted from Godot Engine 4.2.rc1's ProceduralSkyMaterial.

shader_type sky;
render_mode use_debanding;

uniform sampler2D sky_texture;
uniform sampler2D sky_color_ramp;
global uniform vec3 camera_angles;
global uniform float aspect_ratio;

void sky() {
	//EYEDIR
	vec2 use_uv = SCREEN_UV * vec2(aspect_ratio, 1.0) * 0.5 + vec2(0.25, 0.25);
	use_uv.x -= camera_angles.y / PI;
	use_uv.y -= camera_angles.x / PI;
	vec3 use_color = texture(sky_texture, use_uv).rgb;
	vec3 use_color_blurred = texture(sky_texture, use_uv, 6.0).rgb;
	vec3 ramp = texture(sky_color_ramp, -use_uv.yx + use_color.rg * 0.025 + use_color.gb * 0.025 + use_color.br * 0.025).rgb;
	use_color_blurred -= 0.08;
	use_color_blurred *= 1.0;
	use_color_blurred = max(vec3(0.0, 0.0, 0.0), use_color_blurred);
	float one_zero_one = (sin(use_uv.y - 2.08) + 1.0) * 8.0;
	//COLOR = vec3(one_zero_one);
	COLOR = mix((use_color + use_color_blurred) * 0.5, ramp, pow(one_zero_one, 0.333));
}
