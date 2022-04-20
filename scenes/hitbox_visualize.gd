extends Node2D

var hitrect = Rect2()
var hitbox_active = false

var c_active = Color(1, 0.2, 0.2, 0.6)
var c_inactive = Color(0.2, 1, 1, 0.5)

func _draw():
	var drawcol = c_active if hitbox_active else c_inactive
	draw_rect(hitrect, drawcol, true)
