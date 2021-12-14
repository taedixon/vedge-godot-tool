extends Node

signal project_changed()

# Declare member variables here. Examples:
var saved_tilesets = {}
var saved_sprites = {}
var saved_rooms = {}
var project = null
var root_path = ""

func set_project(path):
	var try_load = _load_yy(path)
	if try_load && try_load.resourceType == "GMProject":
		project = try_load
		root_path = path.get_base_dir() + "/"
		emit_signal("project_changed")
		return true
	else:
		return false

func project_loaded():
	return project != null

func get_tileset(path):
	if !(path in saved_tilesets):
		saved_tilesets[path] = load_tileset(path)
	return saved_tilesets[path]
	
func load_tileset(path):
	var tdata = _load_yy(root_path + path)
	if tdata:
		return populate_tileset(tdata)
		
func populate_tileset(tdata):
	var tileset_info = {}
	var img = Image.new()
	var sprite_data = _load_yy(root_path + tdata.spriteId.path)
	var sprite_folder = tdata.spriteId.path.get_base_dir() + "/"
	var sprite_path = root_path + sprite_folder + sprite_data.frames[0].compositeImage.FrameId.name + ".png"
	img.load(sprite_path)
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	tex.flags = 3
	var tileset = TileSet.new()
	var tile_idx = 0
	for y in range(0, sprite_data.height, 16):
		for x in range(0, sprite_data.width, 16):
			tileset.create_tile(tile_idx)
			tileset.tile_set_texture(tile_idx, tex)
			tileset.tile_set_region(tile_idx, Rect2(x, y, 16, 16))
			tile_idx += 1
	tileset_info.tileset = tileset
	tileset_info.mask = tdata.tile_count
	tileset_info.image = img
	return tileset_info

func get_sprite(path):
	if !(path in saved_sprites):
		saved_sprites[path] = load_sprite(path)
	return saved_sprites[path]
	
func load_sprite(path):
	var yydata = _load_yy(root_path + path)
	if yydata:
		return populate_sprite(yydata)
		
func populate_sprite(yydata):
	var sprite_info = {}
	var frame = yydata.frames[0].compositeImage
	var sprite_folder = frame.FrameId.path.get_base_dir() + "/"
	var sprite_path = root_path + sprite_folder + frame.FrameId.name + ".png"
	var img = Image.new()
	img.load(sprite_path)
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	tex.flags = 3
	sprite_info.texture = tex
	sprite_info.offset = Vector2(-yydata.sequence.xorigin, -yydata.sequence.yorigin)
	return sprite_info

func get_room_list():
	var list = []
	for res in project.resources:
		if res.id.path.begins_with("rooms/"):
			list.push_front(res.id)
	return list
	
func get_room(path):
	if !(path in saved_rooms):
		saved_rooms[path] = _load_yy(root_path + path)
	return saved_rooms[path]
	
func _load_yy(path):
	var f = File.new()
	f.open(path, File.READ)
	if f.is_open():
		var content = f.get_as_text()
		f.close()
		var parsed = JSON.parse(content)
		if parsed.error == OK:
			return parsed.result
		else:
			push_error(parsed.error_string)
	else:
		push_error("Failed to open " + path)
		return
