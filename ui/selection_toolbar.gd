extends PanelContainer

signal selection_param_changed(params)
signal request_selection_clear()

onready var tool_select = $GridContainer/tool_select

var selection_param = {
	"tool": "LASSO",
	"inverted": false,
}

func _ready():
	emit_signal("selection_param_changed", selection_param)
	

func on_tool_select(index):
	selection_param.tool = tool_select.get_item_text(index)
	emit_signal("selection_param_changed", selection_param)

func on_invert_selection(button_pressed):
	selection_param.inverted = button_pressed
	emit_signal("selection_param_changed", selection_param)

func on_clear_pressed():
	emit_signal("request_selection_clear")
