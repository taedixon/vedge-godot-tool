shader_type canvas_item;
render_mode skip_vertex_transform, blend_mul;

uniform vec2 shimmer;
uniform float intensity;

void vertex() {
	vec2 offset = sin(VERTEX.xy + TIME * 5. + distance(VERTEX.xy, vec2(0, 0))) * shimmer;
	VERTEX = (EXTRA_MATRIX * (WORLD_MATRIX * vec4(VERTEX + offset, 0.0, 1.0))).xy;
}

void fragment() {
	COLOR = mix(vec4(1.0), COLOR, intensity);
}