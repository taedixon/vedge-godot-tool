extends CenterContainer


var last_mouse_pos = Vector2()
var was_mousedown = false

var hitbox_active setget set_hitbox_active
var hitrect setget ,get_hitrect

onready var hitbox = $Control/sprite_root


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if !has_focus():
		return
	var mb = (Input.get_mouse_button_mask() &BUTTON_LEFT) != 0
	var mousepos = hitbox.get_local_mouse_position()
	
	if was_mousedown:
		if mb:
			var delta = mousepos - hitbox.hitrect.position
			hitbox.hitrect.size = Vector2(round(delta.x), round(delta.y))
			hitbox.update()
		else:
			was_mousedown = false
	else:
		if mb:
			hitbox.hitrect.position = Vector2(round(mousepos.x), round(mousepos.y))
			hitbox.hitrect.size = Vector2()
			was_mousedown = true


func set_hitbox_active(active):
	hitbox.hitbox_active = active
	hitbox.update()

func get_hitrect():
	return hitbox.hitrect
