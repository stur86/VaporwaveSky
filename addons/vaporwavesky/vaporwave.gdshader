shader_type sky;


uniform vec3 sky_color: source_color = vec3(0.1, 0.07, 0.2);

group_uniforms Sun;

group_uniforms Sun.Size;
uniform float sun_angle_span: hint_range(1.0, 90.0, 0.1) = 10.0; 
uniform float sun_smoothing: hint_range(0.01, 10.0, 0.001) = 0.35;

group_uniforms Sun.Gradient;
uniform bool sun_gradient = true;
uniform vec3 sun_color_1: source_color = vec3(0.96, 0.9, 0.35);
uniform vec3 sun_color_2: source_color = vec3(0.96, 0.35, 0.9);
uniform float sun_gradient_pos_frac: hint_range(0.0, 1.0, 0.01) = 0.6;
uniform float sun_gradient_span_frac: hint_range(0.0, 10.0, 0.01) = 0.8;

group_uniforms Sun.Banding;
uniform bool sun_banding = true;
uniform float sun_banding_base_gap: hint_range(0.01, 1.0, 0.001) = 0.03;
uniform float sun_banding_gap_mul: hint_range(1.0, 10.0, 0.1) = 1.1;
uniform float sun_banding_stop_height: hint_range(0.0, 1.0, 0.01) = 0.7;
uniform float sun_banding_thickness: hint_range(0.001, 1.0, 0.001) = 0.01;

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
		// Gradient
		vec3 sc = sun_color_1;
		float sun_y_coord = 0.5*(acos(LIGHT0_DIRECTION.y)-theta+sun_span_rad)/sun_span_rad;
		if (sun_gradient) {
			float sg = smoothstep(sun_gradient_pos_frac+sun_gradient_span_frac/2.0,
								  sun_gradient_pos_frac-sun_gradient_span_frac/2.0,
								  sun_y_coord);
			sc = mix(sun_color_1, sun_color_2, sg);			
		}
		// Banding
		if (sun_banding) {
			float sun_band_gap = sun_banding_base_gap;
			float sun_band = 0.0;
			float ssmooth = sun_banding_thickness/2.0;
			while (sun_band < sun_banding_stop_height) {
				float sbd = abs(sun_y_coord-sun_band);
				sun *= smoothstep(sun_banding_thickness-ssmooth, 
								  sun_banding_thickness+ssmooth,
								  sbd);
				sun_band_gap *= sun_banding_gap_mul;
				sun_band += sun_band_gap;
			}
		}
		COLOR = mix(COLOR, sc, sun);
	}	
}
