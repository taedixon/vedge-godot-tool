extends Panel

signal room_selected(room_name)
signal layer_selected(layer_name)
signal layer_visible_toggled(layer_name, vis)
signal layer_edit_detail(layer_name)

onready var roomlist = $TabContainer/Rooms/room_list
onready var roomfilter = $TabContainer/Rooms/room_filter
onready var layerlist = $TabContainer/Layers/layer_items

var scn_layer_item = preload("res://ui/layer_list_item.tscn")
var style_panel_select = preload("res://style/style_panel_selected.tres")

var roomlist_content = []
var light_layers = [] setget _set_light_layers
var current_room = ""

func _ready():
	roomlist.connect("item_selected", self, "on_room_selected")

func set_room_list():
	roomlist.clear()
	var all_rooms = GmsAssetCache.get_room_list()
	roomlist_content = []
	var filter = roomfilter.text.to_lower()
	for room in all_rooms:
		if (filter == "") || room.name.to_lower().find(filter) > -1:
			roomlist.add_item(room.name)
			roomlist_content.push_back(room)

func on_filter_change(_newtext):
	set_room_list()
	
func on_room_selected(idx):
	var room_path = roomlist_content[idx].path
	current_room = room_path
	set_layer_list(room_path)
	emit_signal("room_selected", room_path)
	
func on_layer_select(layer):
	for child in layerlist.get_children():
		if child is Control && child.layer_name == layer:
			child.add_stylebox_override("panel", style_panel_select)
		else:
			child.add_stylebox_override("panel", null)
	emit_signal("layer_selected", layer)

func on_layer_edit_detail(layer):
	emit_signal("layer_edit_detail", layer)
	
func on_layer_toggle_visible(layer, vis):
	emit_signal("layer_visible_toggled", layer, vis)

func _set_light_layers(layers):
	light_layers = layers
	if current_room != "":
		set_layer_list(current_room)

func set_layer_list(room_path):
	for child in layerlist.get_children():
		layerlist.remove_child(child)
	var roomdata = GmsAssetCache.get_yy(room_path)
	for layer in roomdata.layers:
		var layer_type = layer.resourceType
		if layer_type == "GMRTileLayer" || layer_type == "GMRAssetLayer" || layer_type == "GMRBackgroundLayer":
			var listitem = scn_layer_item.instance()
			listitem.layer_name = layer.name
			listitem.layer_visible = layer.visible
			listitem.connect("visible_toggled", self, "on_layer_toggle_visible")
			listitem.connect("layer_selected", self, "on_layer_select")
			listitem.connect("layer_edit_detail", self, "on_layer_edit_detail")
			listitem.selectable = layer.name in light_layers
			if listitem.selectable:
				listitem.layer_visible = true
			layerlist.add_child(listitem)
