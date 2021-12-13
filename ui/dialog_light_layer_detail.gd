extends WindowDialog

signal detail_changed(layer, data)

onready var i_shimmerx = $VBoxContainer/input_shimmerx
onready var i_shimmery = $VBoxContainer/input_shimmery
onready var i_intensity = $VBoxContainer/input_intensity
var layer_name setget set_layername
var data = {
	"shimmerX": 0,
	"shimmerY": 0,
	"intensity": 1,
} setget set_data

func set_layername(name):
	layer_name = name
	window_title = "Layer Detail - %s" % name

func set_data(in_data):
	data = in_data
	i_shimmerx.value = float(data["shimmerX"])
	i_shimmery.value = float(data["shimmerY"])
	i_intensity.value = float(data["intensity"])

func on_shimmerx_change(val):
	data["shimmerX"] = val
	emit_signal("detail_changed", layer_name, data)
	
func on_shimmery_change(val):
	data["shimmerY"] = val
	emit_signal("detail_changed", layer_name, data)
	
func on_intensity_change(val):
	data["intensity"] = val
	emit_signal("detail_changed", layer_name, data)
