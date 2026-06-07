shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.35, 0.65, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 12.0) = 3.0;
uniform bool flicker_enabled = false;
uniform float flicker_speed = 10.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * outline_width;

	float a = tex.a;
	a = max(a, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
	a = max(a, texture(TEXTURE, UV + vec2(-px.x, 0.0)).a);
	a = max(a, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
	a = max(a, texture(TEXTURE, UV + vec2(0.0, -px.y)).a);
	a = max(a, texture(TEXTURE, UV + vec2(px.x, px.y)).a);
	a = max(a, texture(TEXTURE, UV + vec2(-px.x, px.y)).a);
	a = max(a, texture(TEXTURE, UV + vec2(px.x, -px.y)).a);
	a = max(a, texture(TEXTURE, UV + vec2(-px.x, -px.y)).a);

	vec4 col = outline_color;
	if (flicker_enabled) {
		float flick = 0.55 + 0.45 * sin(TIME * flicker_speed);
		col.rgb *= flick;
		col.a *= flick;
	}

	if (tex.a < 0.05 && a > 0.05) {
		COLOR = col;
	} else {
		COLOR = tex;
	}
}
