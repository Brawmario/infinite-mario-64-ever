shader_type spatial;

render_mode blend_mix,depth_draw_opaque,cull_disabled,skip_vertex_transform;

uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D slope_texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D texture_gradient : source_color,filter_linear_mipmap,repeat_enable;
uniform vec3 color_multiply;
uniform float outer_time;
uniform float fade_in;
uniform float fade_in_duration;
uniform float fade_in_distance;
uniform vec3 spawn_dir;
uniform vec3 spawn_pos;
varying vec3 world_pos;
varying vec3 use_normal;
varying vec2 UVX;
varying vec2 UVY;
varying vec2 UVZ;

const float PHI = 1.61803398874989484820459;  // Φ = Golden Ratio

float gold_noise(in vec2 xy, in float seed) {
	   return fract(tan(distance(xy*PHI, xy)*seed)*xy.x);
}

float random (vec2 uv) {
	return fract(sin(dot(uv.xy,
		vec2(12.9898,78.233))) * 43758.5453123);
}
float rand(vec2 n) {
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 ip = floor(p);
	vec2 u = fract(p);
	u = u*u*(3.0-2.0*u);

	float res = mix(
		mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
		mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
	return res*res;
}

float spawn_ratio() {
	float initial_ratio = clamp((outer_time - fade_in) * (1.0 / fade_in_duration), 0.0, 1.0);
	return pow(1.0 - initial_ratio, 2.0);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	use_normal = NORMAL;
	UVZ = (VERTEX + spawn_pos).xy * 0.25;
	UVX = (VERTEX + spawn_pos).yz * 0.25;
	UVY = (VERTEX + spawn_pos).zx * 0.25;
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	VERTEX = VERTEX + spawn_dir * fade_in_distance * spawn_ratio() * noise(world_pos.xy + world_pos.yz) + NORMAL * ((spawn_ratio() * fade_in_distance) + 0.001);
}

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float linear_depth(in float depth, in vec2 screen_uv, in mat4 inv_projection_matrix) {
	// get raw depth, this is not a linear value in godot 4.0 vulkan rendering

	vec3 normalized_device_coordinates = vec3(screen_uv * 2.0 - 1.0, depth);

	//convert NDC to view space via the inverse projection matrix
	vec4 view_space = inv_projection_matrix * vec4(normalized_device_coordinates, 1.0);

	//linearize the depth
	view_space.xyz /= view_space.w;

	// camera view points in the negative Z direction, so all depths are negative
	// we invert the sign here to get positive depth values
	return -view_space.z;
}

void fragment() {

	int x = int(FRAGCOORD.x) % 4;
	int y = int(FRAGCOORD.y) % 4;
	int index = x + y * 4;
	float limit = 0.0;
	float tp_limit = 0.0;

	if (x < 8) {

		if (index == 0) limit = 0.0625;
		if (index == 1) limit = 0.5625;
		if (index == 2) limit = 0.1875;
		if (index == 3) limit = 0.6875;
		if (index == 4) limit = 0.8125;
		if (index == 5) limit = 0.3125;
		if (index == 6) limit = 0.9375;
		if (index == 7) limit = 0.4375;
		if (index == 8) limit = 0.25;
		if (index == 9) limit = 0.75;
		if (index == 10) limit = 0.125;
		if (index == 11) limit = 0.625;
		if (index == 12) limit = 1.0;
		if (index == 13) limit = 0.5;
		if (index == 14) limit = 0.875;
		if (index == 15) limit = 0.375;

		if (index == 0) tp_limit = 0.0;
		if (index == 1) tp_limit = 1.0;
		if (index == 2) tp_limit = 0.0;
		if (index == 3) tp_limit = 1.0;

		if (index == 4) tp_limit = 1.0;
		if (index == 5) tp_limit = 1.0;
		if (index == 6) tp_limit = 1.0;
		if (index == 7) tp_limit = 1.0;

		if (index == 8) tp_limit = 0.0;
		if (index == 9) tp_limit = 1.0;
		if (index == 10) tp_limit = 0.0;
		if (index == 11) tp_limit = 1.0;

		if (index == 12) tp_limit = 1.0;
		if (index == 13) tp_limit = 1.0;
		if (index == 14) tp_limit = 1.0;
		if (index == 15) tp_limit = 1.0;
	}
	if (limit <= spawn_ratio()){
		discard;
	}
	if (limit > length(VERTEX) * 0.25 - 1.0 && FRONT_FACING){
		discard;
	}
	if (!FRONT_FACING && limit >= 0.5){
		discard;
	}
	//if (tp_limit < 0.5){
	//	discard;
	//}
	//if (length(VERTEX) * 0.1 - 4.0 > limit){
	//	discard;
	//}
	float sample_pos = ((world_pos.x + world_pos.z) * 0.1 + world_pos.y) * 0.025;
	float x_factor = clamp(abs(use_normal.x) * 16.0 - 8.0, 0.0, 1.0);
	float y_factor = clamp(abs(use_normal.y) * 16.0 - 8.0, 0.0, 1.0);
	float z_factor = clamp(abs(use_normal.z) * 16.0 - 8.0, 0.0, 1.0);
	vec3 xy_tex = texture(texture_albedo, UVZ).rgb;
	vec3 yz_tex = texture(texture_albedo, UVX).rgb;
	vec3 zx_tex = texture(texture_albedo, UVY).rgb;
	vec3 xy_slope_tex = texture(slope_texture_albedo, UVZ).rgb;
	vec3 yz_slope_tex = texture(slope_texture_albedo, UVX).rgb;
	vec3 zx_slope_tex = texture(slope_texture_albedo, UVY).rgb;
	vec3 gradient_color = texture(texture_gradient, vec2(sample_pos, 0)).rgb;
	vec3 final_texture_color = mix(mix(xy_tex, yz_tex, x_factor), zx_tex, y_factor);
	vec3 final_slope_texture_color = mix(mix(xy_slope_tex, yz_slope_tex, x_factor), zx_slope_tex, y_factor);
	if (use_normal.y > 0.0 && use_normal.y < 0.99){
		vec3 hsv = rgb2hsv(gradient_color);
		hsv += vec3(0.5, 0.0, 0.0);
		hsv.z = 1.0 - hsv.z;
		gradient_color = hsv2rgb(hsv);
		if (FRONT_FACING){
			ALBEDO = final_slope_texture_color * gradient_color;
		}else{
			ALBEDO = final_slope_texture_color * gradient_color * 0.1;
			SPECULAR = 0.0;
		}
	}else{
		if (FRONT_FACING){
			ALBEDO = final_texture_color * gradient_color;
		}else{
			ALBEDO = final_texture_color * gradient_color * 0.1;
			SPECULAR = 0.0;
		}
	}
}
