shader_type spatial;

render_mode unshaded;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = vec3(1.0, 0.2, 0.2);
	ALPHA = max(0.0, 0.5 - length(VERTEX) * 0.01);
}

void light() {
	// Called for every pixel for every light affecting the material.
}
