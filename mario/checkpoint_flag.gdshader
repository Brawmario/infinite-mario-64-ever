shader_type spatial;
render_mode cull_disabled;

uniform vec3 color_one : source_color;
uniform vec3 color_two : source_color;
uniform vec3 color_three : source_color;
uniform vec3 color_for : source_color;

void fragment() {
	if (UV.x < 0.25){
		ALBEDO = mix(color_one, color_two, UV.y);
	}else if (UV.x < 0.5){
		ALBEDO = color_for;
	}else if (UV.x < 0.75){
		ALBEDO = color_three;
	}else{
		ALBEDO = color_for;
	}
}
