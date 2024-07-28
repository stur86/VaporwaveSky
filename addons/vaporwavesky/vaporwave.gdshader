shader_type sky;
/*
VaporwaveSky shader by Simone Sturniolo
Created on 28-07-2024
https://github.com/stur86/VaporwaveSky
*/

group_uniforms Sky;
uniform vec3 sky_color: source_color = vec3(0.1, 0.07, 0.2);
uniform vec3 sky_horizon_color: source_color = vec3(0.56, 0.18, 0.42);
uniform float sky_horizon_decay: hint_range(0.0, 90.0, 0.1) = 3.0;

group_uniforms Ground;
uniform vec3 ground_color: source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 ground_horizon_color: source_color = vec3(0.1, 0.0, 0.07);
uniform float ground_horizon_decay: hint_range(0.0, 90.0, 0.1) = 1.0;

group_uniforms Stars;
uniform bool stars_enabled = true;
uniform bool stars_below_horizon = false;
uniform vec3 star_color: source_color = vec3(0.95, 0.9, 0.6);
uniform float star_radius: hint_range(0.1, 1.0, 0.01) = 0.3;
uniform float star_density: hint_range(0.5, 100.0, 0.1) = 5.0;
uniform float star_randomness: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform vec2 star_seed = vec2(0.0, 0.0);

group_uniforms Grid;
uniform bool grid_enabled = true;
uniform vec3 grid_color: source_color = vec3(0.18, 0.92, 0.74);
uniform float grid_depth: hint_range(1.0, 10.0, 0.1) = 2.0;
uniform float grid_spacing: hint_range(0.1, 10.0, 0.1) = 1.0;
uniform float grid_thickness: hint_range(0.01, 1.0, 0.01) = 0.03;
uniform float grid_max_distance: hint_range(0.0, 100.0, 0.1) = 25.0;
uniform float grid_max_distance_fade: hint_range(0.0, 1.0, 0.1) = 0.3;
uniform float grid_energy: hint_range(0.0, 10.0, 0.1) = 1.0;

group_uniforms Sun.Size;
uniform float sun_radius: hint_range(1.0, 90.0, 0.1) = 10.0; 
uniform float sun_smoothing: hint_range(0.01, 10.0, 0.001) = 0.35;

group_uniforms Sun.Glow;
uniform vec3 sun_glow_color: source_color = vec3(0.96, 0.9, 0.35);
uniform float sun_glow_radius: hint_range(1.0, 90.0, 0.1) = 30.0; 
uniform float sun_glow_intensity: hint_range(0.0, 1.0, 0.01) = 0.5;

group_uniforms Sun.Gradient;
uniform bool sun_gradient_enabled = true;
uniform vec3 sun_color_1: source_color = vec3(0.96, 0.9, 0.35);
uniform vec3 sun_color_2: source_color = vec3(0.96, 0.35, 0.9);
uniform float sun_gradient_pos_frac: hint_range(0.0, 1.0, 0.01) = 0.6;
uniform float sun_gradient_span_frac: hint_range(0.0, 10.0, 0.01) = 0.8;

group_uniforms Sun.Banding;
uniform bool sun_banding_enabled = true;
uniform float sun_banding_base_gap: hint_range(0.001, 1.0, 0.001) = 0.03;
uniform float sun_banding_gap_mul: hint_range(1.0, 10.0, 0.1) = 1.1;
uniform float sun_banding_stop_height: hint_range(0.0, 1.0, 0.01) = 0.7;
uniform float sun_banding_thickness: hint_range(0.001, 1.0, 0.001) = 0.01;

// Randomness
// From The Book of Shaders
// Author @patriciogv - 2015
// https://thebookofshaders.com/10/
float random(vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

vec2 randvec(vec2 st) {
	return vec2(random(st), random(st+vec2(.5, .5)));
}

// Direction in sphere from polar angles
vec3 sph_direction(float phi, float theta) {
	float st = sin(theta);
	return vec3(st*sin(phi), cos(theta), -st*cos(phi));
}

// Star computation
float star(vec2 sky_coords, vec3 sky_dir) {
	
	if (sky_dir.y < 0.0 && !stars_below_horizon) {
		return 0.0;
	}
	
	float theta_sectors_N = ceil(star_density*PI/2.0);
	float theta_sector = ceil(sky_coords.y*theta_sectors_N);
	float phi_sectors_N = ceil(star_density*TAU*sin(theta_sector/theta_sectors_N*PI/2.0));
	float phi_sector = ceil(sky_coords.x*phi_sectors_N);
	// Compute star position in this sector
	float rnd_dth = (random(vec2(theta_sector, phi_sector)+star_seed)-0.5)*star_randomness;
	float rnd_dphi = (random(vec2(phi_sector, theta_sector)+star_seed)-0.5)*star_randomness;
	float star_theta = (theta_sector-0.5+rnd_dth)/theta_sectors_N*PI;
	float star_phi = (phi_sector-0.5+rnd_dphi)/phi_sectors_N*TAU;
	vec3 star_dir = sph_direction(star_phi, star_theta);
	
	return smoothstep(cos(radians(star_radius)), 1.0, dot(star_dir, sky_dir));	
}

// Sun gradient
vec3 sun_gradient_color(float y) {
	float sg = smoothstep(sun_gradient_pos_frac+sun_gradient_span_frac/2.0,
						  sun_gradient_pos_frac-sun_gradient_span_frac/2.0,
						  y);
	return mix(sun_color_1, sun_color_2, sg);			
}

// Sun banding computation
float sun_band(float y) {
	float ans = 1.0;
	float sun_band_gap = sun_banding_base_gap;
	float sun_band = 0.0;
	float ssmooth = sun_banding_thickness/2.0;
	while (sun_band < sun_banding_stop_height) {
		float sbd = abs(y-sun_band);
		ans *= smoothstep(sun_banding_thickness-ssmooth, 
						  sun_banding_thickness+ssmooth,
						  sbd);
		sun_band_gap *= sun_banding_gap_mul;
		sun_band += sun_band_gap;
	}	
	return ans;
}

// Grid lines
float grid_line(vec3 sky_dir, vec3 p, vec3 v) {
	vec3 ucrossv = cross(sky_dir, v);
	ucrossv /= length(ucrossv);
	vec3 vuv = cross(v, ucrossv);
	float d = abs(dot(p, ucrossv));
	float c1 = dot(p, vuv)/dot(sky_dir, vuv);
	return (smoothstep(grid_thickness, 0.0, d)*
		    (sky_dir.y < 0.0? 1.0 : 0.0)*
			grid_energy*
			smoothstep(grid_max_distance, 
					   grid_max_distance*(1.0-grid_max_distance_fade), 
					   c1)
	);
}

float grid(vec3 sky_dir) {
	// Compute the maximum number of lines required
	int N = int(ceil(grid_max_distance/grid_spacing*2.0));
	float ans = 0.0;
	
	// X-parallel lines
	vec3 v = vec3(1.0, 0.0, 0.0);
	for (int i = -N; i <= N; ++i) {
		vec3 p = vec3(0.0, -grid_depth, float(i)*grid_spacing);
		ans = max(ans, grid_line(sky_dir, p, v));
	}
	
	// Z-parallel lines
	v = vec3(0.0, 0.0, 1.0);
	for (int i = -N; i <= N; ++i) {
		vec3 p = vec3(float(i)*grid_spacing, -grid_depth, 0.0);
		ans = max(ans, grid_line(sky_dir, p, v));
	}

	return ans;
}

void sky() {
	float phi = TAU*SKY_COORDS.x;
	float theta = PI*SKY_COORDS.y;
	// Direction of sky, using the general system of coordinates
	vec3 sky_dir = sph_direction(phi, theta);

	// Base color
	if (theta > PI/2.0) {
		COLOR = ground_color;
	}
	else {
		COLOR = sky_color;
	}
	
	// Stars
	if (stars_enabled) {
		COLOR = mix(COLOR, star_color, star(SKY_COORDS, sky_dir));
	}

	// Sun
	if (LIGHT0_ENABLED) {
		// Projection of the direction?
		float sun_angle = acos(dot(LIGHT0_DIRECTION, sky_dir));
		float smooth_hw_rad = radians(sun_smoothing/2.0);
		float sun_span_rad = radians(sun_radius);
		float sun_edge0 = sun_span_rad-smooth_hw_rad;
		float sun_edge1 = sun_span_rad+smooth_hw_rad;
		float sun = smoothstep(sun_edge1, sun_edge0, sun_angle);
		float sun_glow = smoothstep(radians(sun_glow_radius), 0.0, sun_angle)*sun_glow_intensity;
		// Also hide below the horizon
		float hor_factor = smoothstep(-smooth_hw_rad, smooth_hw_rad, sky_dir.y);
		sun *= hor_factor;
		sun_glow *= hor_factor;
		// Gradient
		vec3 sc = sun_color_1;
		float sun_y_coord = 0.5*(acos(LIGHT0_DIRECTION.y)-theta+sun_span_rad)/sun_span_rad;
		if (sun_gradient_enabled) {
			sc = sun_gradient_color(sun_y_coord);		
		}
		// Banding
		if (sun_banding_enabled) {
			sun *= sun_band(sun_y_coord);
		}
		COLOR = mix(COLOR, sun_glow_color, sun_glow);
		COLOR = mix(COLOR, sc, sun);
	}
	
	// Add horizon hazes
	if (sky_dir.y > 0.0) {
		// Sky
		float hor_deg = degrees(PI/2.0-theta);
		COLOR = mix(COLOR, sky_horizon_color, exp(-hor_deg/sky_horizon_decay));
	}
	else {
		// Ground
		float hor_deg = degrees(theta-PI/2.0);
		COLOR = mix(COLOR, ground_horizon_color, exp(-hor_deg/ground_horizon_decay));
	}
	
	// Grid
	if (grid_enabled) {
		float gv = grid(sky_dir);
		COLOR = max(1.0-gv, 0.0)*COLOR + gv*grid_color;		
	}
}
