shader_type spatial;

render_mode cull_disabled, unshaded;

vec4 grid(vec3 fragPos3D, float scale) {
    vec2 coord = fragPos3D.xz * scale;
    vec2 derivative = fwidth(coord);
    vec2 grid = abs(fract(coord - 0.5) - 0.5) / derivative;
    float line = min(grid.x, grid.y);
    float minimumz = min(derivative.y, 1);
    float minimumx = min(derivative.x, 1);
    vec4 color = vec4(0.2, 0.2, 0.2, 1.0 - min(line, 1.0));
    // z axis
    if(fragPos3D.x > -0.1 * minimumx && fragPos3D.x < 0.1 * minimumx)
        color.z = 1.0;
    // x axis
    if(fragPos3D.z > -0.1 * minimumz && fragPos3D.z < 0.1 * minimumz)
        color.x = 1.0;
    return color;
}

void fragment() {
	vec4 pos = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 clip_pos = PROJECTION_MATRIX * vec4(VERTEX, 1.0);
	float clip_space_depth = (clip_pos.z / clip_pos.w) * 2.0 - 1.0;

	float near = 0.05;
	float far = 100.0;
	float linearDepth = (2.0 * near * far) / (far + near - clip_space_depth * (far - near));
	linearDepth = linearDepth / far;
	float fading = max(0, (0.5 - linearDepth));

    vec4 outColor = (grid(pos.xyz, 10) * 0.5 + grid(pos.xyz, 1));

	ALBEDO = outColor.xyz;
	ALPHA = outColor.w * fading;
}
