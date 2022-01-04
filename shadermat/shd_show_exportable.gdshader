shader_type canvas_item;

uniform vec4 ignore_col;
uniform float ignore_dist;

void vertex() {
	if (distance(COLOR.rgb, ignore_col.rgb) <= ignore_dist) {
		COLOR.a = 0.0;
	}
}
void fragment() {
	COLOR.a = ceil(COLOR.a);
}