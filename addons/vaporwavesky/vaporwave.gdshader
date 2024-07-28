shader_type sky;

group_uniforms Colors;
uniform vec3 sky_color: source_color = vec3(0.1, 0.07, 0.2);
uniform vec3 sun_color_1: source_color = vec3(0.96, 0.9, 0.35);

group_uniforms Scales;
uniform float sun_angle_span: hint_range(1.0, 90.0, 0.1) = 10.0; 
uniform float sun_smoothing: hint_range(0.01, 10.0, 0.001) = 0.35;

void sky() {
	// Base color
	COLOR = sky_color;
	float phi = TAU*SKY_COORDS.x;
	float theta = PI*SKY_COORDS.y;
	// Direction of sky, using the general system of coordinates
	float st = sin(theta);
	vec3 sky_dir = vec3(st*sin(phi), cos(theta), -st*cos(phi));

	// Sun
	if (LIGHT0_ENABLED) {
		// Projection of the direction?
		float sun_angle = acos(dot(LIGHT0_DIRECTION, sky_dir));
		float smooth_hw_rad = radians(sun_smoothing/2.0);
		float sun_span_rad = radians(sun_angle_span);
		float sun_edge0 = sun_span_rad-smooth_hw_rad;
		float sun_edge1 = sun_span_rad+smooth_hw_rad;
		float sun = smoothstep(sun_edge1, sun_edge0, sun_angle);
		// Also hide below the horizon
		sun *= smoothstep(-smooth_hw_rad, smooth_hw_rad, sky_dir.y);
		COLOR = mix(COLOR, sun_color_1, sun);
	}	
	
	//COLOR = sky_dir;
}
