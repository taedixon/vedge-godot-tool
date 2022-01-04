extends Control


# Declare member variables here. Examples:
onready var map = $map_container/gms_map
onready var mapcontainer = $map_container
onready var roomlist = $room_picker
onready var dialog_lightlayer = $dialog_light_layer_detail


func _ready():
	if GmsAssetCache.project_loaded():
		roomlist.set_room_list()
	var err = GmsAssetCache.connect("project_changed", self, "on_project_change")
	roomlist.connect("layer_visible_toggled", map, "layer_toggle_visible")
	assert (err == 0)

func on_project_change():
	map.room_path = ""
	roomlist.set_room_list()

func on_room_select(room_path):
	map.save()
	var toast = Toast.new("Room Saved", Toast.LENGTH_LONG)
	get_node("/root").add_child(toast)
	toast.show()
	map.room_path = room_path
	roomlist.light_layers = map.get_light_layers()

func on_layer_select(layer):
	map.set_active_layer(layer)
	
func on_layer_edit_detail(layer):
	var meta = map.get_metadata(layer)
	if meta && meta.kind == "light":
		dialog_lightlayer.layer_name = meta.name
		dialog_lightlayer.data = meta.detail
		dialog_lightlayer.popup_centered()

func on_layer_detail_changed(layer, detail):
	map.update_metadata(layer, detail)
	
func save():
	map.save()
