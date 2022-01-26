extends Control

signal draw_param_changed(params)
signal selection_param_changed(params)
signal selection_mode_toggle(state)
signal request_selection_clear()

onready var selection_mode_panel =  $selection_toggle_panel
onready var selection_toolbar = $selection_toolbar
onready var edit_toolbar = $light_toolbar

var c_edit = Color(0x323e45FF)
var c_selection = Color(0x893111FF)

func on_selection_mode_toggle(button_pressed):
	selection_toolbar.visible = button_pressed
	edit_toolbar.visible = !button_pressed
	selection_mode_panel.get_stylebox("panel", "").set_bg_color(c_selection if button_pressed else c_edit)
	emit_signal("selection_mode_toggle", button_pressed)

func on_edit_toolbar_draw_param_changed(params):
	emit_signal("draw_param_changed", params)

func on_selection_param_changed(params):
	emit_signal("selection_param_changed", params)


func on_request_selection_clear():
	emit_signal("request_selection_clear")
