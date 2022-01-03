extends WindowDialog

signal detail_changed(layer, data)

onready var i_shimmerx = $CenterContainer/VBoxContainer/input_shimmerx
onready var i_shimmery = $CenterContainer/VBoxContainer/input_shimmery
onready var i_intensity = $CenterContainer/VBoxContainer/input_intensity
onready var i_glow = $CenterContainer/VBoxContainer/input_glow
onready var i_shimmerspd = $CenterContainer/VBoxContainer/input_shimmerspd

var layer_name setget set_layername
var data = {
	"shimmerX": 0,
	"shimmerY": 0,
	"intensity": 1,
	"shimmerSpeed": 1,
	"is_glow": true
} setget set_data

func set_layername(name):
	layer_name = name
	window_title = "Layer Detail - %s" % name

func set_data(in_data):
	data = in_data
	i_shimmerx.value = float(data["shimmerX"])
	i_shimmery.value = float(data["shimmerY"])
	i_intensity.value = float(data["intensity"])
	i_glow.pressed = data.get("is_glow", false)
	i_shimmerspd = float(data.get("shimmerSpeed", 1))

func on_shimmerx_change(val):
	data["shimmerX"] = val
	emit_signal("detail_changed", layer_name, data)
	
func on_shimmery_change(val):
	data["shimmerY"] = val
	emit_signal("detail_changed", layer_name, data)
	
func on_intensity_change(val):
	data["intensity"] = val
	emit_signal("detail_changed", layer_name, data)

func on_shimmerspeed_change(val):
	data["shimmerSpeed"] = val
	emit_signal("detail_changed", layer_name, data)

func on_glow_change(val):
	data["is_glow"] = val
	emit_signal("detail_changed", layer_name, data)
