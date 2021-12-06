extends Node2D


# Declare member variables here. Examples:
var _roomdata = null
export (String) var room_path setget set_room_path
onready var layers_root = $tile_layers
var scn_light_layer = preload("res://scenes/light_layer.tscn")

var light_layers = {}

var active_layer = null

var bounds = Rect2(0, 0, 0, 0)

func _ready():
	set_room_path(room_path)

func set_room_path(p):
	room_path = p
	if typeof(room_path) == TYPE_STRING && room_path.length() > 0 && layers_root:
		_roomdata = load_room_data(room_path)

func load_room_data(path):
	_roomdata = GmsAssetCache.get_room(path)
	active_layer = null
	if _roomdata:
		populate_map(_roomdata)
		
func layer_toggle_visible(layer, vis):
	for child in layers_root.get_children():
		if child.name == layer:
			child.visible = vis
			
func populate_map(roomdata):
	for child in layers_root.get_children():
		layers_root.remove_child(child)
	var nodes_to_add = []
	find_light_layers(roomdata)
	for layer in roomdata.layers:
		if layer.resourceType == "GMRTileLayer" && layer.tilesetId:
			if layer.name in light_layers:
				nodes_to_add.push_front(add_light_layer(layer))
			else:
				nodes_to_add.push_front(add_tile_layer(layer))
		elif layer.resourceType == "GMRAssetLayer":
			nodes_to_add.push_front(add_asset_layer(layer))
	for i in nodes_to_add:
		layers_root.add_child(i)
		
	bounds.size = Vector2(roomdata.roomSettings.Width,roomdata.roomSettings.Height)
	position = -bounds.size / 2
	update()
		
func add_asset_layer(layer):
	var base = Node2D.new()
	for asset in layer.assets:
		var spr = Sprite.new()
		var spr_info = GmsAssetCache.get_sprite(asset.spriteId.path)
		spr.centered = false
		spr.offset = spr_info.offset
		spr.texture = spr_info.texture
		spr.position = Vector2(asset.x, asset.y)
		spr.rotation_degrees = -asset.rotation
		spr.scale = Vector2(asset.scaleX, asset.scaleY)
		base.add_child(spr)
	base.name = layer.name
	return base

func add_tile_layer(layer):
	var tileinfo = GmsAssetCache.get_tileset(layer.tilesetId.path)
	var tmap = TileMap.new()
	tmap.tile_set = tileinfo.tileset
	tmap.cell_size = Vector2(16, 16)
	var tx = 0
	var ty = 0
	var xmax = layer.tiles.SerialiseWidth
	for tid in layer.tiles.TileSerialiseData:
		var itid = int(tid)
		var tid_real = itid & 0x7FFFF
		if tid_real > 0:
			tmap.set_cell(tx, ty, tid_real, (itid & 0x10000000) != 0, (itid & 0x20000000) != 0, (itid & 0x40000000) != 0)
		tx += 1
		if (tx >= xmax):
			tx = 0
			ty += 1
	tmap.visible = layer.visible
	tmap.name = layer.name
	return tmap
	
func add_light_layer(layer):
	var light_data = light_layers[layer.name]
	var node = scn_light_layer.instance()
	node.layer_data = layer
	node.light_data = light_data
	node.name = layer.name
	node.visible = layer.visible
	return node

func find_light_layers(roomdata):
	light_layers = {}
	for layer in roomdata.layers:
		if layer.resourceType == "GMRInstanceLayer" && layer.instances:
			for inst in layer.instances:
				if inst.objectId.name == "o_grid_light":
					var inst_simple = {}
					for prop in inst.properties:
						inst_simple[prop.propertyId.name] = prop.value
					if !("layer_name" in inst_simple):
						inst_simple.layer_name = "shadow"
					inst_simple._gmsobj = inst
					light_layers[inst_simple.layer_name] = inst_simple

func _draw():
	draw_rect(bounds, Color.cyan, false)
	
func set_active_layer(layer):
	active_layer = null
	for node in layers_root.get_children():
		if node.name == layer:
			active_layer = node
			break;
	
func add_stroke_point(mb, params):
	if active_layer:
		active_layer.add_stroke_point(mb, get_local_mouse_position(), params)
