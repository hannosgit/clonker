shader_type canvas_item;

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 water = texture(TEXTURE, UV);
	float wave = sin(world_position.x * 0.047 + world_position.y * 0.09 + TIME * 1.25);
	float caustic = sin(world_position.x * 0.023 - world_position.y * 0.057 - TIME * 0.65);
	water.rgb += (wave + caustic) * 0.012;
	COLOR = water;
}
