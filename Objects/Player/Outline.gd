extends Node2D

var texture : Texture

func draw():
	for i in range(4):
		draw_texture(texture, position + Vector2(i % 2 * 1 - 0.5, floor(i / 2) * 1 - 0.5) - Vector2(4, 4))
