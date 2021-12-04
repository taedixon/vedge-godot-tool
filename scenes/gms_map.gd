extends Node2D


# Declare member variables here. Examples:
var _roomdata = null
export (String) var room_path setget set_room_path

func set_room_path(p):
	room_path = p
	if typeof(room_path) == TYPE_STRING:
		_roomdata = load_room_data(room_path)

func load_room_data(path):
	_roomdata = GmsTool.load_yy(path)
	if _roomdata:
		populate_map(_roomdata)
		
func populate_map(roomdata):
	GmsAssetCache.root_path = "C:/Users/Noxid/Documents/dev/GitHub/Unmend-Project/VernalEdge/"
	var tilesets_root = $"tile_layers"
	var nodes_to_add = []
	for layer in roomdata.layers:
		if layer.resourceType == "GMRTileLayer":
			nodes_to_add.push_front(add_tile_layer(layer))
		elif layer.resourceType == "GMRAssetLayer":
			nodes_to_add.push_front(add_asset_layer(layer))
	for i in nodes_to_add:
		tilesets_root.add_child(i)
		
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
	return tmap
