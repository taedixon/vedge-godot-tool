extends Node2D


# Declare member variables here. Examples:
export (String) var room_path setget set_room_path
onready var layers_root = $tile_layers
var scn_light_layer = preload("res://scenes/light_layer.tscn")

var light_layers = {}
var layer_metadata = {}
var room_name = ""
var show_tris = false

var active_layer = null

var bounds = Rect2(0, 0, 0, 0)

func _ready():
	set_room_path(room_path)

func set_room_path(p):
	room_path = p
	if typeof(room_path) == TYPE_STRING && room_path.length() > 0 && layers_root:
		load_room_data(room_path)

func load_room_data(path):
	var _roomdata = GmsAssetCache.get_room(path)
	active_layer = null
	if _roomdata:
		populate_map(_roomdata)
		
func layer_toggle_visible(layer, vis):
	for child in layers_root.get_children():
		if child.name == layer:
			child.visible = vis
			
func populate_map(roomdata):
	bounds.size = Vector2(roomdata.roomSettings.Width,roomdata.roomSettings.Height)
	room_name = roomdata.name
	for child in layers_root.get_children():
		layers_root.remove_child(child)
	var nodes_to_add = []
	create_layer_metadata(roomdata)
	for layer in roomdata.layers:
		var meta = layer_metadata[layer.name]
		match meta.kind:
			"tile": 
				nodes_to_add.push_front(add_tile_layer(layer))
			"light": 
				nodes_to_add.push_front(add_light_layer(layer))
			"asset": 
				nodes_to_add.push_front(add_asset_layer(layer))
	for i in nodes_to_add:
		layers_root.add_child(i)
		
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
	var light_data = get_metadata(layer.name).detail
	var node = scn_light_layer.instance()
	var bufferpath = get_lightbuffer_path(layer.name)
	var dir = Directory.new()
	node.tile_w = ceil(bounds.size.x/16.0)
	node.tile_h = ceil(bounds.size.y/16.0)
	if dir.file_exists(bufferpath):
		node.layer_data = bufferpath
	else:
		node.layer_data = null
	node.detail = light_data
	node.name = layer.name
	node.visible = true
	return node
	
func create_layer_metadata(roomdata):
	layer_metadata = {}
	for layer in roomdata.layers:
		var meta = {
			"kind": "unknown",
			"name": layer.name,
			"detail": {}
		}
		match layer.resourceType:
			"GMRInstanceLayer":
				meta.kind = "instance"
			"GMRAssetLayer": 
				meta.kind = "asset"
			"GMRTileLayer":
				meta.kind = "tile"
		layer_metadata[layer.name] = meta
	find_light_layers(roomdata)

func find_light_layers(roomdata):
	for layer in roomdata.layers:
		if layer.resourceType == "GMRInstanceLayer" && layer.instances:
			for inst in layer.instances:
				if inst.objectId.name == "o_grid_light":
					var inst_simple = {}
					for prop in inst.properties:
						inst_simple[prop.propertyId.name] = prop.value
					if !("layer_name" in inst_simple):
						inst_simple.layer_name = "shadow"
					if !("shimmerX" in inst_simple):
						inst_simple.shimmerX = 0
					if !("shimmerY" in inst_simple):
						inst_simple.shimmerY = 0
					if !("shimmerSpeed" in inst_simple):
						inst_simple.shimmerSpeed = 1
					inst_simple.is_glow = inst_simple.get("is_glow") == "True"
					var meta = layer_metadata[inst_simple.layer_name]
					inst_simple.vertex_count = 0
					inst_simple.version = "vtf_lightmap_1"
					inst_simple.build = "dev_nov2021" 
					meta.detail = inst_simple
					meta.kind = "light"
					
func get_lightbuffer_path(layer_name):
	var filename = room_name + "_" + layer_name
	return GmsAssetCache.root_path + "datafiles/lightmaps/" + filename
					
func save():
	for layer in layer_metadata.values():
		var node = layers_root.get_node_or_null(layer.name)
		if node && node.has_method("save"):
			var filename = room_name + "_" + layer.name
			var binfile = File.new()
			var fullpath = get_lightbuffer_path(layer.name)
			var e = binfile.open(fullpath, File.WRITE)
			if e != OK:
				push_error("Failed to open %s for writing" % fullpath)
				continue
			node.save(binfile)
			binfile.close()
			
			var dir = Directory.new()
			var copydest = OS.get_user_data_dir() + "/../../../../Local/VernalEdge/lightmaps/"
			dir.copy(fullpath, copydest + filename)
			
			var metafile = File.new()
			e = metafile.open(fullpath + ".meta", File.WRITE)
			if e != OK:
				push_error("Failed to open %s.meta for writing" % fullpath)
				continue
			metafile.store_string(JSON.print(node.detail))
			metafile.close()
			dir.copy(fullpath + ".meta", copydest + filename + ".meta")
			

func get_metadata(layer):
	return layer_metadata.get(layer)

func update_metadata(layer, detail):
	var current = get_metadata(layer)
	var node = layers_root.get_node(layer)
	if current && node:
		current.detail = detail
		node.detail = detail

func _draw():
	draw_rect(bounds, Color.cyan, false)
	
func layer_editable():
	return active_layer != null && active_layer.visible
	
func set_active_layer(layer):
	if layer_editable():
		active_layer.preview_exported_triangles = false
	active_layer = null
	var meta = get_metadata(layer)
	if meta && meta.kind == "light":
		active_layer = layers_root.get_node(layer)
		active_layer.preview_exported_triangles = show_tris
	
func add_stroke_point(mb, params):
	if layer_editable():
		active_layer.add_stroke_point(mb, get_local_mouse_position(), params)

func add_stroke_rect(mb, rec: Rect2, params):
	if layer_editable():
		var rec_local = Rect2((rec.position - position)/scale, rec.size / scale)
		active_layer.add_stroke_rect(mb, rec_local, params)

func add_stroke_fill(mb, params):
	if layer_editable():
		active_layer.add_stroke_rect(mb, bounds, params)

func end_stroke():
	if layer_editable():
		active_layer.end_stroke()

func get_picked_colour():
	if layer_editable():
		return active_layer.get_colour(get_local_mouse_position())
		
func undo():
	if layer_editable():
		active_layer.undo()

func redo():
	if layer_editable():
		active_layer.redo()
		
func set_show_tris(show):
	show_tris = show
	if layer_editable():
		active_layer.preview_exported_triangles = show
