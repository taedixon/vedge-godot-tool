extends Node

# Declare member variables here. Examples:
var saved_tilesets = {}
var saved_sprites = {}
var root_path = ""

func get_tileset(path):
	if !(path in saved_tilesets):
		saved_tilesets[path] = load_tileset(path)
	return saved_tilesets[path]
	
func load_tileset(path):
	var tdata = GmsTool.load_yy(root_path + path)
	if tdata:
		return populate_tileset(tdata)
		
func populate_tileset(tdata):
	var tileset_info = {}
	var img = Image.new()
	var sprite_data = GmsTool.load_yy(root_path + tdata.spriteId.path)
	var sprite_folder = tdata.spriteId.path.get_base_dir() + "/"
	var sprite_path = root_path + sprite_folder + sprite_data.frames[0].compositeImage.FrameId.name + ".png"
	print(sprite_path)
	img.load(sprite_path)
	var tex = ImageTexture.new()
	tex.create_from_image(img)
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
	return tileset_info

func get_sprite(path):
	if !(path in saved_sprites):
		saved_sprites[path] = load_sprite(path)
	return saved_sprites[path]
	
func load_sprite(path):
	var yydata = GmsTool.load_yy(root_path + path)
	if yydata:
		return populate_sprite(yydata)
		
func populate_sprite(yydata):
	var sprite_info = {}
	var frame = yydata.frames[0].compositeImage
	var sprite_folder = frame.FrameId.path.get_base_dir() + "/"
	var sprite_path = root_path + sprite_folder + frame.FrameId.name + ".png"
	print(sprite_path)
	var img = Image.new()
	img.load(sprite_path)
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	sprite_info.texture = tex
	sprite_info.offset = Vector2(-yydata.sequence.xorigin, -yydata.sequence.yorigin)
	return sprite_info
