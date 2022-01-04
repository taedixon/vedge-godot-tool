extends Control

onready var roomlist = $room_picker
onready var map = $map_controller/gms_map
onready var controller = $map_controller

# Called when the node enters the scene tree for the first time.
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
	map.room_path = room_path
	controller.on_room_changed()

func on_layer_selected(layer_name):
	map.set_active_layer(layer_name)

func on_reload_room():
	map.set_room_path(map.room_path)
