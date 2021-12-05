extends Control


# Declare member variables here. Examples:
onready var map = $map_container/gms_map
onready var mapcontainer = $map_container
onready var roomlist = $Panel/TabContainer/Rooms/room_list
onready var layerlist = $Panel/TabContainer/Layers/layer_items
onready var roomfilter = $Panel/TabContainer/Rooms/room_filter

var scn_layer_item = preload("res://ui/layer_list_item.tscn")
var roomlist_content = []


func _ready():
	if GmsAssetCache.project_loaded():
		set_room_list()
	GmsAssetCache.connect("project_changed", self, "on_project_change")
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !mapcontainer.has_focus():
		return
	var translate_spd = 500
	if Input.is_key_pressed(KEY_SHIFT):
		translate_spd *= 2
	translate_spd *= max(1, map.scale.x)
	map.position.x += Input.get_action_strength("scroll_left") * translate_spd * delta
	map.position.x -= Input.get_action_strength("scroll_right") * translate_spd *  delta
	map.position.y += Input.get_action_strength("scroll_up") * translate_spd *  delta
	map.position.y -= Input.get_action_strength("scroll_down") * translate_spd *  delta
	if Input.is_action_just_released("map_zoom_in"):
		map.scale += Vector2(0.1, 0.1)
	if Input.is_action_just_released("map_zoom_out"):
		if map.scale.x > 0.1:
			map.scale -= Vector2(0.1, 0.1)
	if Input.is_action_just_pressed("map_zoom_reset"):
		map.scale = Vector2(1, 1)

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
			listitem.layer_name = layer.name
			listitem.layer_visible = layer.visible
			listitem.connect("visible_toggled", map, "layer_toggle_visible")
			layerlist.add_child(listitem)
