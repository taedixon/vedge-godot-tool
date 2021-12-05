extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func on_focus_loss():
	update()

func on_focus_gain():
	update()

func _draw():
	if has_focus():
		draw_rect(Rect2(0, 0, rect_size.x, rect_size.y), Color.wheat, false)


func on_mouse_exit():
	release_focus()


func on_mouse_enter():
	grab_focus()
