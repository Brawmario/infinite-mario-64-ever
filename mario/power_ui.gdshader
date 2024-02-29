shader_type canvas_item;

uniform float checkerRepeat = 8.0;
uniform float checkerRotate = 0.1;
uniform float outlineSize = 1.0;

uniform vec2 checkerScrollSpeed = vec2(0.2, -0.1);

uniform vec3 outlineColor : source_color = vec3(0.9, 0.5, 0.4);

uniform vec3 topGradientCheck1 : source_color = vec3(1.0, 0.6, 0.7);
uniform vec3 bottomGradientCheck1 : source_color = vec3(1.0, 0.15, 0.6);

uniform vec3 topGradientCheck2 : source_color = vec3(0.6, 0.2, 0.3);
uniform vec3 bottomGradientCheck2 : source_color = vec3(0.4, 0.05, 0.2);

uniform sampler2D checkerTexture : repeat_enable;

vec2 rotate(vec2 uv, vec2 pivot, float angle)
{
	mat2 rotation = mat2(vec2(sin(angle), -cos(angle)),
						vec2(cos(angle), sin(angle)));
	
	uv -= pivot;
	uv = uv * rotation;
	uv += pivot;
	return uv;
}

void fragment(){
	float ratio = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float repeat = checkerRepeat;
	vec2 loopingUV = vec2(SCREEN_UV.x * ratio * repeat, SCREEN_UV.y * repeat);
	loopingUV = rotate(loopingUV, vec2(0, 0), checkerRotate);
	loopingUV.x = loopingUV.x + TIME * checkerScrollSpeed.x;
	loopingUV.y = loopingUV.y + TIME * checkerScrollSpeed.y;
	vec3 color1 = mix(topGradientCheck1, bottomGradientCheck1, SCREEN_UV.y);
	vec3 color2 = mix(topGradientCheck2, bottomGradientCheck2, SCREEN_UV.y);
	vec4 textureColor = texture(checkerTexture, loopingUV);
	vec3 checkerColor = mix(color1, color2, textureColor.r);
	vec3 outlineInterp = mix(checkerColor, outlineColor, clamp(outlineSize - min(outlineSize, COLOR.r * 20.0), 0.0, 1.0));
	
	COLOR = vec4(outlineInterp, COLOR.r * 10.0);
}