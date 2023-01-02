extends Node

signal project_changed()

# Declare member variables here. Examples:
var saved_tilesets = {}
var saved_sprites = {}
var saved_instances = {}
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
	var frame_obj = sprite_data.frames[0]
	var sprite_path
	if frame_obj.resourceVersion == "1.1":
		sprite_path = root_path + sprite_folder + frame_obj.name + ".png"
	else:
		sprite_path = root_path + sprite_folder + frame_obj.compositeImage.FrameId.name + ".png"
	img.load(sprite_path)
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	tex.flags = 3
	var tileset = TileSet.new()
	var tile_idx = 0
	var twidth = tdata.tileWidth
	var theight = tdata.tileHeight
	for y in range(0, sprite_data.height, theight):
		for x in range(0, sprite_data.width, twidth):
			tileset.create_tile(tile_idx)
			tileset.tile_set_texture(tile_idx, tex)
			tileset.tile_set_region(tile_idx, Rect2(x, y, twidth, theight))
			tile_idx += 1
	tileset_info.tileset = tileset
	tileset_info.mask = tdata.tile_count
	tileset_info.image = img
	tileset_info.tile_width = twidth
	tileset_info.tile_height = theight
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
	sprite_info.frames = []
	for f in yydata.frames:
		var sprite_path
		if f.resourceVersion == "1.1":
			sprite_path = root_path + "sprites/" + yydata.name + "/" + f.name + ".png"
		else:
			var frame = f.compositeImage
			var sprite_folder = frame.FrameId.path.get_base_dir() + "/"
			sprite_path = root_path + sprite_folder + frame.FrameId.name + ".png"
		var img = Image.new()
		img.load(sprite_path)
		var tex = ImageTexture.new()
		tex.create_from_image(img)
		tex.flags = 3
		sprite_info.frames.append(tex)
	sprite_info.texture = sprite_info.frames[0]
	sprite_info.offset = Vector2(-yydata.sequence.xorigin, -yydata.sequence.yorigin)
	return sprite_info

func get_object(path):
	if !(path in saved_instances):
		saved_instances[path] = load_object(path)
	return saved_instances[path]

func load_object(path):
	var yydata = _load_yy(root_path + path)
	if yydata:
		return populate_object(yydata)

func populate_object(yydata):
	var inst_info = {}
	if yydata.spriteId != null:
		inst_info.sprite = get_sprite(yydata.spriteId.path)
	else:
		inst_info.sprite = null
	return inst_info

func get_room_list():
	var list = []
	for res in project.resources:
		if res.id.path.begins_with("rooms/"):
			list.push_front(res.id)
	return list

func get_sprite_list():
	var list = []
	for res in project.resources:
		if res.id.path.begins_with("sprites/"):
			list.push_front(res.id)
	return list
	
func get_yy(path):
	return _load_yy(root_path + path)
	
func parse_yycolor(col_int):
	col_int = int(col_int)
	var r = col_int % 256
	var g = (col_int >> 8) % 256
	var b = (col_int >> 16) % 256
	return Color(r/256.0, g/256.0, b/256.0, 1.0)
	
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
