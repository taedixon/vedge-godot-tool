extends PanelContainer

signal draw_param_changed(params)

onready var input_col_lmb = $GridContainer/col_lmb
onready var input_col_rmb = $GridContainer/col_rmb
onready var input_radius = $GridContainer/radius_select
onready var input_falloff = $GridContainer/falloff_select
onready var input_tool = $GridContainer/tool_select
onready var input_show_selection = $GridContainer/btn_selection

var draw_param = {
	"tool": "DRAW",
	"radius": 32,
	"col_lmb": Color.maroon,
	"col_rmb": Color.darkslateblue,
	"falloff": "SQUARE",
	"mix_amount": 0.5,
	"show_tris": false,
	"show_selection": true,
}

onready var col_history_lmb = [input_col_lmb.color]
var history_pos_lmb = 0

onready var col_history_rmb = [input_col_rmb.color]
var history_pos_rmb = 0

func _ready():
	draw_param.radius = input_radius.value
	draw_param.col_lmb = input_col_lmb.color
	draw_param.col_rmb = input_col_rmb.color
	draw_param.falloff = input_falloff.get_item_text(input_falloff.get_selected_id())
	emit_signal("draw_param_changed", draw_param)
	
func _unhandled_input(event):
	if event.is_action_pressed("toggle_selection_visible"):
		if !Input.is_key_pressed(KEY_SHIFT):
			input_show_selection.pressed = !input_show_selection.pressed
			on_show_selection_change(input_show_selection.pressed)
			get_tree().set_input_as_handled()
	
func _process(delta):
	var history_input_dir = 0
	if Input.is_action_just_released("map_zoom_in"):
		history_input_dir = 1
	elif Input.is_action_just_released("map_zoom_out"):
		history_input_dir = -1
	if history_input_dir != 0:
		if input_col_lmb.is_hovered():
			advance_col_history_lmb(history_input_dir)
		elif input_col_rmb.is_hovered():
			advance_col_history_rmb(history_input_dir)

func advance_col_history_lmb(amt):
	history_pos_lmb = clamp(history_pos_lmb + amt, 0, col_history_lmb.size()-1)
	var c = col_history_lmb[history_pos_lmb]
	input_col_lmb.color = c
	on_col_lmb_change(c)

func advance_col_history_rmb(amt):
	history_pos_rmb = clamp(history_pos_rmb + amt, 0, col_history_rmb.size()-1)
	var c = col_history_rmb[history_pos_rmb]
	input_col_rmb.color = c
	on_col_rmb_change(c)
	
func push_history_lmb(col: Color):
	if col.is_equal_approx(input_col_lmb.color):
		return
	if col_history_lmb.size() > (history_pos_lmb+1):
		col_history_lmb.resize(history_pos_lmb+1)
	col_history_lmb.append(col)
	print("lmb history size %d" % col_history_lmb.size())
	history_pos_lmb += 1
	
func push_history_rmb(col):
	if col.is_equal_approx(input_col_rmb.color):
		return
	if col_history_rmb.size() > (history_pos_rmb+1):
		col_history_rmb.resize(history_pos_rmb+1)
	col_history_rmb.append(col)
	print("rmb history size %d" % col_history_rmb.size())
	history_pos_rmb += 1
	
func on_colour_pick(mousebutton, col):
	col.a = 1
	if mousebutton == BUTTON_LEFT:
		push_history_lmb(col)
		input_col_lmb.color = col
		draw_param.col_lmb = col
	else:
		push_history_rmb(col)
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

func on_show_tris_change(val):
	draw_param.show_tris = val
	emit_signal("draw_param_changed", draw_param)

func on_show_selection_change(val):
	draw_param.show_selection = val
	emit_signal("draw_param_changed", draw_param)
	
func on_col_lmb_popup_closed():
	push_history_lmb(input_col_lmb.color)

func on_col_rmb_popup_closed():
	push_history_rmb(input_col_rmb.color)
