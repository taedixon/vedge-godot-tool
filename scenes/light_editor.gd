extends Control


# Declare member variables here. Examples:
onready var map = $map_container/gms_map
onready var mapcontainer = $map_container
onready var roomlist = $Panel/TabContainer/Rooms/room_list
onready var layerlist = $Panel/TabContainer/Layers/layer_items
onready var roomfilter = $Panel/TabContainer/Rooms/room_filter
onready var dialog_lightlayer = $dialog_light_layer_detail

var scn_layer_item = preload("res://ui/layer_list_item.tscn")
var style_panel_select = preload("res://style/style_panel_selected.tres")
var roomlist_content = []

func _ready():
	if GmsAssetCache.project_loaded():
		set_room_list()
	var err = GmsAssetCache.connect("project_changed", self, "on_project_change")
	assert (err == 0)
	roomlist.connect("item_selected", self, "on_room_select")

func on_project_change():
	map.room_path = ""
	set_room_list()

func on_room_select(idx):
	var room_path = roomlist_content[idx].path
	map.room_path = room_path
	set_layer_list(room_path)

func on_filter_change(_newtext):
	set_room_list()

func set_room_list():
	roomlist.clear()
	var all_rooms = GmsAssetCache.get_room_list()
	roomlist_content = []
	var filter = roomfilter.text.to_lower()
	for room in all_rooms:
		if (filter == "") || room.name.to_lower().find(filter) > -1:
			roomlist.add_item(room.name)
			roomlist_content.push_back(room)

func set_layer_list(room_path):
	for child in layerlist.get_children():
		layerlist.remove_child(child)
	var roomdata = GmsAssetCache.get_room(room_path)
	for layer in roomdata.layers:
		var layer_type = layer.resourceType
		if layer_type == "GMRTileLayer" || layer_type == "GMRAssetLayer":
			var listitem = scn_layer_item.instance()
			var meta = map.get_metadata(layer.name)
			listitem.layer_name = layer.name
			listitem.layer_visible = layer.visible
			listitem.connect("visible_toggled", map, "layer_toggle_visible")
			listitem.connect("layer_selected", self, "on_layer_select")
			listitem.connect("layer_edit_detail", self, "on_layer_edit_detail")
			listitem.selectable = meta && meta.kind == "light"
			if listitem.selectable:
				listitem.layer_visible = true
			layerlist.add_child(listitem)

func on_layer_select(layer):
	for child in layerlist.get_children():
		if child is Control && child.layer_name == layer:
			child.add_stylebox_override("panel", style_panel_select)
		else:
			child.add_stylebox_override("panel", null)
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
