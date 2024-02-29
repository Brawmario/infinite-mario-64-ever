shader_type spatial;
render_mode unshaded;

//render_mode ambient_light_disabled;


uniform vec4 albedo : source_color = vec4(1.0f);
uniform sampler2D albedo_texture : source_color;

varying vec3 e;
varying vec3 n;

void vertex() {
	vec4 matrixmult = MODELVIEW_MATRIX * vec4( VERTEX, 1.0 );
	e = normalize( vec3( matrixmult.x, matrixmult.y, matrixmult.z ) );
	n = normalize( MODELVIEW_NORMAL_MATRIX * NORMAL );
}

void fragment() {
	
	vec3 r = reflect( e, n );
	float m = 2. * sqrt( pow( r.x, 2. ) + pow( r.y, 2. ) + pow( r.z + 1., 2. ) );
	vec2 vN = r.xy / m + .5;

	//vec3 base = texture2D( tMatCap, vN ).rgb;

	//gl_FragColor = vec4( base, 1. );
	ALBEDO = albedo.rgb * texture(albedo_texture, vN * vec2(1, -1)).rgb * COLOR.rgb * 20.0;
	ALPHA = albedo.a;
}
