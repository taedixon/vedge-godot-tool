extends PanelContainer

signal visible_toggled(layer, visible)

export (bool) var layer_visible = true setget set_layer_visible
export (String) var layer_name = "Layer Name"

var ic_hidden = preload("res://img/icon/GuiVisibilityHidden.svg")
var ic_visible = preload("res://img/icon/GuiVisibilityVisible.svg")

onready var label = $HBoxContainer/Label
onready var button = $HBoxContainer/Button

func _ready():
	label.text = layer_name
	set_button_icon(layer_visible)
	button.pressed = !layer_visible

func set_layer_visible(vis):
	layer_visible = vis
	if button:
		set_button_icon(vis)
		button.pressed = !vis
	
func on_button_press(press):
	var vis = !press
	set_button_icon(vis)
	layer_visible = vis
	emit_signal("visible_toggled", layer_name, vis)

func set_button_icon(vis):
	if vis:
		button.icon = ic_visible
	else:
		button.icon = ic_hidden
