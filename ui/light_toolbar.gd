extends PanelContainer

signal draw_param_changed(params)

onready var input_col_lmb = $GridContainer/col_lmb
onready var input_col_rmb = $GridContainer/col_rmb
onready var input_radius = $GridContainer/radius_select
onready var input_falloff = $GridContainer/falloff_select
onready var input_tool = $GridContainer/tool_select

var draw_param = {
	"tool": "DRAW",
	"radius": 32,
	"col_lmb": Color.maroon,
	"col_rmb": Color.darkslateblue,
	"falloff": "SQUARE",
	"mix_amount": 0.5,
}

func _ready():
	draw_param.radius = input_radius.value
	draw_param.col_lmb = input_col_lmb.color
	draw_param.col_rmb = input_col_rmb.color
	draw_param.falloff = input_falloff.get_item_text(input_falloff.get_selected_id())
	emit_signal("draw_param_changed", draw_param)
	
func on_colour_pick(mousebutton, col):
	col.a = 1
	if mousebutton == BUTTON_LEFT:
		input_col_lmb.color = col
		draw_param.col_lmb = col
	else:
		input_col_rmb.color = col
		draw_param.col_rmb = col
	emit_signal("draw_param_changed", draw_param)

func on_tool_change(idx):
	draw_param.tool = input_tool.get_item_text(idx)
	emit_signal("draw_param_changed", draw_param)

func on_col_lmb_change(col):
	draw_param.col_lmb = col
	emit_signal("draw_param_changed", draw_param)
	
func on_col_rmb_change(col):
	draw_param.col_rmb = col
	emit_signal("draw_param_changed", draw_param)
	
func on_radius_change(rad):
	draw_param.radius = rad
	emit_signal("draw_param_changed", draw_param)
	
func on_falloff_change(idx):
	draw_param.falloff = input_falloff.get_item_text(idx)
	emit_signal("draw_param_changed", draw_param)

func on_mix_change(mix):
	draw_param.mix_amount = mix
	emit_signal("draw_param_changed", draw_param)
