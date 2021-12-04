extends Control


# Declare member variables here. Examples:
onready var map = $gms_map


# Called when the node enters the scene tree for the first time.
func _ready():
	$project_select.popup_centered()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var translate_spd = 300
	if Input.is_key_pressed(KEY_SHIFT):
		translate_spd *= 2
	map.position.x += Input.get_action_strength("ui_left") * translate_spd * delta
	map.position.x -= Input.get_action_strength("ui_right") * translate_spd *  delta
	map.position.y += Input.get_action_strength("ui_up") * translate_spd *  delta
	map.position.y -= Input.get_action_strength("ui_down") * translate_spd *  delta
