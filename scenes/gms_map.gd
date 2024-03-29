extends Node2D


# Declare member variables here. Examples:
export (String) var room_path setget set_room_path
onready var layers_root = $tile_layers
onready var overlay = $overlay
var scn_light_layer = preload("res://scenes/light_layer.tscn")

var layer_metadata = {}
var room_name = ""
var show_tris = false

var active_layer = null

var bounds = Rect2(0, 0, 0, 0)
var camera_offset = Vector2(0, 0) setget set_camera_offset

var selection = PoolVector2Array() setget set_selection, get_selection

func _ready():
	set_room_path(room_path)

func set_room_path(p):
	room_path = p
	if typeof(room_path) == TYPE_STRING && room_path.length() > 0 && layers_root:
		load_room_data(room_path)

func load_room_data(path):
	var _roomdata = GmsAssetCache.get_yy(path)
	active_layer = null
	if _roomdata:
		populate_map(_roomdata)
		
func layer_toggle_visible(layer, vis):
	for child in layers_root.get_children():
		if child.name == layer:
			child.visible = vis
			
func set_overlay_visible(vis):
	overlay.visible = vis
			
func populate_map(roomdata):
	bounds.size = Vector2(roomdata.roomSettings.Width,roomdata.roomSettings.Height)
	room_name = roomdata.name
	for child in layers_root.get_children():
		layers_root.remove_child(child)
	layer_metadata = create_layer_metadata(roomdata, {})
	var newnodes = populate_layers(roomdata.layers, layer_metadata, [])
	newnodes.sort_custom(self, "layer_depth_sort")
	for i in newnodes:
		layers_root.add_child(i.node)
	position = Vector2()
	update()

func layer_depth_sort(a, b):
	return a.depth > b.depth
	
func populate_layers(layers_list, metadata, nodes_to_add):
	find_light_layers(layers_list, metadata)
	find_parallax_data(layers_list, metadata)
	for layer in layers_list:
		var meta = metadata[layer.name]
		match meta.kind:
			"tile":
				nodes_to_add.push_front({
					"node": add_tile_layer(layer), 
					"depth": layer.depth
				})
			"light": 
				nodes_to_add.push_front({
					"node": add_light_layer(layer),
					"depth": layer.depth
				})
			"asset": 
				nodes_to_add.push_front({
					"node": add_asset_layer(layer),
					"depth": layer.depth
				})
			"background":
				nodes_to_add.push_front({
					"node": add_background_layer(layer),
					"depth": layer.depth
				})
			"instance":
				nodes_to_add.push_front({
					"node": add_instance_layer(layer),
					"depth": layer.depth
				})
			"nested":
				populate_layers(layer.layers, metadata, nodes_to_add)
	return nodes_to_add
	
func add_instance_layer(layer):
	var base = Node2D.new()
	for inst in layer.instances:
		var spr_info = GmsAssetCache.get_object(inst.objectId.path).sprite
		if spr_info != null:
			var spr = Sprite.new()
			spr.centered = false
			spr.offset = spr_info.offset
			spr.texture = spr_info.frames[inst.imageIndex]
			spr.position = Vector2(inst.x, inst.y)
			spr.rotation_degrees = -inst.rotation
			spr.scale = Vector2(inst.scaleX, inst.scaleY)
			base.add_child(spr)
	base.name = layer.name
	return base
		
func add_asset_layer(layer):
	var base = Node2D.new()
	for asset in layer.assets:
		var spr = Sprite.new()
		var spr_info = GmsAssetCache.get_sprite(asset.spriteId.path)
		spr.centered = false
		spr.offset = spr_info.offset
		spr.texture = spr_info.frames[asset.headPosition]
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
	tmap.cell_size = Vector2(tileinfo.tile_width, tileinfo.tile_height)
	var tx = 0
	var ty = 0
	var xmax = layer.tiles.SerialiseWidth
	if layer.tiles.TileDataFormat == 1:
		var repeat = 0
		var value_is_raw = false
		for tid in layer.tiles.TileCompressedData:
			if repeat == 0:
				repeat = tid
			else:
				var itid = int(tid)
				var tid_real = itid & 0x7FFFF
				if repeat < 0:
					# RLE tile data
					repeat = abs(repeat)
					for i in range(repeat):
						if tid_real > 0:
							tmap.set_cell(tx, ty, tid_real, (itid & 0x10000000) != 0, (itid & 0x20000000) != 0, (itid & 0x40000000) != 0)
						tx += 1
						if (tx >= xmax):
							tx = 0
							ty += 1
					repeat = 0
				else:
					# raw tile data
					repeat -= 1
					if tid_real > 0:
						tmap.set_cell(tx, ty, tid_real, (itid & 0x10000000) != 0, (itid & 0x20000000) != 0, (itid & 0x40000000) != 0)
					tx += 1
					if (tx >= xmax):
						tx = 0
						ty += 1
	else:
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
	
func add_background_layer(layer):
	var node
	var layer_blend = GmsAssetCache.parse_yycolor(layer.colour)
	if layer.spriteId == null:
		
		node = Node2D.new()
		var rect = ColorRect.new()
		rect.color = layer_blend
		rect.rect_size = bounds.size
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(rect)
		pass
	else:
		node = Sprite.new()
		var spr_info = GmsAssetCache.get_sprite(layer.spriteId.path)
		node.offset = spr_info.offset
		node.texture = spr_info.texture
		node.centered = false
		node.region_enabled = true
		node.region_rect = Rect2(0, 0, spr_info.texture.get_width(), spr_info.texture.get_height())
		if layer.htiled:
			node.region_rect.size.x = bounds.size.x
		if layer.vtiled:
			node.region_rect.size.y = bounds.size.y
		node.modulate = layer_blend
	node.name = layer.name
	node.visible = layer.visible
	return node
	
	
func create_layer_metadata(roomdata, data_object):
	for layer in roomdata.layers:
		var meta = {
			"kind": "unknown",
			"name": layer.name,
			"detail": {},
			"parallax": {"x": 0, "y": 0},
		}
		match layer.resourceType:
			"GMRInstanceLayer":
				meta.kind = "instance"
			"GMRAssetLayer": 
				meta.kind = "asset"
			"GMRTileLayer":
				meta.kind = "tile"
			"GMRBackgroundLayer":
				meta.kind = "background"
			"GMRLayer":
				meta.kind = "nested"
				meta.detail = create_layer_metadata(layer, data_object)
		data_object[layer.name] = meta
	return data_object
	
func get_light_layers():
	var lightlayers = []
	for layer in layer_metadata.values():
		if layer.kind == "light":
			lightlayers.push_back(layer.name)
	return lightlayers
	
func find_parallax_data(layerlist, metadata):
	for layer in layerlist:
		if layer.resourceType == "GMRInstanceLayer" && layer.instances:
			for inst in layer.instances:
				if inst.objectId.name == "o_background":
					var data = []
					for prop in inst.properties:
						if prop.propertyId.name == "layers":
							var parsed = JSON.parse(prop.value)
							if parsed.error == OK:
								data = parsed.result
					for item in data:
						var meta = metadata.get(item[0])
						if meta:
							meta.parallax.x = float(item[1])
							meta.parallax.y = float(item[2])

func find_light_layers(layerlist, metadata):
	for layer in layerlist:
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
					var meta = metadata[inst_simple.layer_name]
					inst_simple.vertex_count = 0
					inst_simple.version = "vtf_lightmap_1"
					inst_simple.build = "baked" 
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
		params.invert_selection = overlay.invert_enable
		active_layer.add_stroke_point(mb, get_local_mouse_position(), params, selection)

func add_stroke_rect(mb, rec: Rect2, params):
	if layer_editable():
		params.invert_selection = overlay.invert_enable
		var rec_local = Rect2((rec.position - position)/scale, rec.size / scale)
		active_layer.add_stroke_rect(mb, rec_local, params, selection)

func add_stroke_fill(mb, params):
	if layer_editable():
		params.invert_selection = overlay.invert_enable
		active_layer.add_stroke_rect(mb, bounds, params, selection)
		
func add_stroke_gradient(grad_color, p1, p2, params):
	if layer_editable():
		params.invert_selection = overlay.invert_enable
		var p1_local = (p1-position)/scale
		var p2_local = (p2-position)/scale
		active_layer.add_stroke_gradient(grad_color, p1_local, p2_local, params, selection)
		
func preview_drag(offset):
	if layer_editable():
		active_layer.position = offset * 16
	
func commit_drag(offset):
	if layer_editable():
		active_layer.position = Vector2()
		active_layer.shift_all(offset)

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

func set_camera_offset(offset):
	camera_offset = offset
	if layer_metadata:
		for child in layers_root.get_children():
			var meta = layer_metadata.get(child.name)
			child.position.x = offset.x * meta.parallax.x
			child.position.y = offset.y * meta.parallax.y

func set_selection(points):
	selection = PoolVector2Array()
	for p in points:
		selection.append((p - position) / scale)
	overlay.selection = selection

func get_selection():
	var translated = PoolVector2Array()
	for p in selection:
		translated.append(p*scale + position)
	return translated

func set_selection_invert(is_invert):
	overlay.invert_enable = is_invert
