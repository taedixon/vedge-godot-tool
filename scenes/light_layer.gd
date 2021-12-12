extends Node2D

var layer_data = null
var light_data = null
var tile_w = 0
var tile_h = 0

const sector_w = 16
const sector_h = 16
var mesh_material = null
var colour_data = {}
onready var meshgroup = $group_mesh
onready var pointgroup = $group_point

var light_mat = preload("res://shadermat/shd_light_layer.gdshader") as Shader
var dark_mat = preload("res://shadermat/shd_shadow_layer.gdshader") as Shader
const gaussian_55 = [
	1.0/256, 4.0/256, 6.0/256, 4.0/256, 1.0/256,
	4.0/256, 16.0/256, 24.0/256, 16.0/256, 4.0/256,
	6.0/256, 24.0/256, 36.0/256, 24.0/256, 6.0/256,
	4.0/256, 16.0/256, 24.0/256, 16.0/256, 4.0/256,
	1.0/256, 4.0/256, 6.0/256, 4.0/256, 1.0/256,
]

var sector_index_array = PoolIntArray()

var current_stroke = null

# Called when the node enters the scene tree for the first time.
func _ready():
	build_sector_indexes()
	if layer_data && light_data:
		mesh_material = get_mesh_material()
		colour_data = {}
		build_colors()
		for sector in colour_data.values():
			build_mesh(sector)
			meshgroup.add_child(sector.meshinst)
			pointgroup.add_child(sector.pointinst)
		
func sector_index(x, y):
	return x + y * sector_w

func build_sector_indexes():
	for y in range(0, sector_h-1):
		for x in range(0, sector_w-1):
			sector_index_array.append(sector_index(x, y))
			sector_index_array.append(sector_index(x+1, y))
			sector_index_array.append(sector_index(x+1, y+1))
			
			sector_index_array.append(sector_index(x, y))
			sector_index_array.append(sector_index(x+1, y+1))
			sector_index_array.append(sector_index(x, y+1))

func build_colors():
	var tileset_img = GmsAssetCache.get_tileset(layer_data.tilesetId.path).image as Image
	tileset_img.lock()
	var tileset_w = tileset_img.get_width() / 16
	tile_w = layer_data.tiles.SerialiseWidth
	tile_h = layer_data.tiles.SerialiseHeight
	var raw_color = []
	for tid in layer_data.tiles.TileSerialiseData:
		var itid = int(tid)
		var tid_real = itid & 0x7FFFF
		var tileset_x = (tid_real % tileset_w) * 16 + 8
		var tileset_y = floor(tid_real / tileset_w) * 16 + 8
		var col = tileset_img.get_pixel(tileset_x, tileset_y)
		raw_color.append(col)
	tileset_img.unlock()
	blend_color(raw_color)

func blend_color(raw_color):
	for ty in tile_h:
		for tx in tile_w:
			var aggregate = Color()
			for ix in range(-2, 3):
				for iy in range(-2, 3):
					var gaussian_fac = gaussian_55[(ix+2) + (iy+2)*5]
					var sample_x = clamp(tx + ix, 0, tile_w-1)
					var sample_y = clamp(ty + iy, 0, tile_h-1)
					var rawval = raw_color[_p(sample_x, sample_y)] as Color
					aggregate += rawval * gaussian_fac
			aggregate.a = 1
			set_vertex_colour(tx, ty, aggregate)

func get_colour_sector(x, y):
	var sector_x = floor(x/sector_w)
	var sector_y = floor(y/sector_h)
	var sector_key = encode_pair(sector_x, sector_y)
	if !sector_key in colour_data:
		var verts = []
		var colour = []
		var basex = sector_x * sector_w * 16
		var basey = sector_y * sector_h * 16
		for y in range(0, sector_h):
			for x in range(0, sector_w):
				verts.append(Vector2(x*16 + basex, y*16+basey))
				colour.append(Color.black)
				
		var mesh = MeshInstance2D.new()
		mesh.name = "mesh_%d" % sector_key
		mesh.material = mesh_material
		var pointmesh = MeshInstance2D.new()
		pointmesh.name = "point_%d" % sector_key
		colour_data[sector_key] = {
			"begin_x": sector_x * sector_w,
			"begin_y": sector_y * sector_h,
			"meshinst": mesh,
			"pointinst": pointmesh,
			"colour": colour,
			"vertex": verts,
			"dirty": false,
		}
	return colour_data[sector_key]

func set_vertex_colour(x, y, colour):
	var sector = get_colour_sector(x, y)
	var local_x = x - sector.begin_x
	var local_y = y - sector.begin_y
	sector.colour[sector_index(local_x, local_y)] = colour
	sector.dirty = true
	
func get_vertex_colour(x, y):
	var sector = get_colour_sector(x, y)
	var local_x = x - sector.begin_x
	var local_y = y - sector.begin_y
	return sector.colour[sector_index(local_x, local_y)]

func get_mesh_material():
	var mesh_mat = ShaderMaterial.new()
	if light_data.get("is_glow") == "True":
		mesh_mat.shader = light_mat
	else:
		mesh_mat.shader = dark_mat
	var u_shimmer = Vector2(1, 1)
	var u_intensity = 1
	if "intensity" in light_data:
		u_intensity = float(light_data["intensity"])
	if "shimmerX" in light_data:
		u_shimmer.x = float(light_data["shimmerX"])
	if "shimmerY" in light_data:
		u_shimmer.y = float(light_data["shimmerY"])
	mesh_mat.set_shader_param("shimmer", u_shimmer)
	mesh_mat.set_shader_param("intensity", u_intensity)
	return mesh_mat

func _p(x, y):
	return x + y*tile_w

func build_mesh(sector):
	var meshbuilder = ArrayMesh.new()
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = PoolVector2Array(sector.vertex)
	arrays[ArrayMesh.ARRAY_COLOR] = PoolColorArray(sector.colour)
	arrays[ArrayMesh.ARRAY_INDEX] = sector_index_array
	meshbuilder.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	sector.meshinst.mesh = meshbuilder
	
func add_stroke_point(button, point: Vector2, params):
	if current_stroke == null:
		var drawcol
		if button == BUTTON_LEFT:
			drawcol = params.col_lmb
		else:
			drawcol = params.col_rmb
		current_stroke = {
			"count": 1, 
			"points": {},
			"colour": drawcol,
		}
	else:
		current_stroke.count += 1
		
	var xmin = max(0, ceil((point.x - params.radius)/16.0))
	var xmax = min(tile_w - 1, floor((point.x + params.radius)/16.0))
	var ymin = max(0, ceil((point.y - params.radius)/16.0))
	var ymax = min(tile_h - 1, floor((point.y + params.radius)/16.0))
	
	for tx in range(xmin, xmax+1):
		for ty in range(ymin, ymax+1):
			var strength
			var tilecoord = Vector2(tx*16, ty*16)
			var exponent
			match params.falloff:
				"CONST":
					exponent = 0
				"LINEAR":
					exponent = 1
				"SQUARE":
					exponent = 2
			strength = pow(max(0, 1.0 - (point.distance_to(tilecoord)/params.radius)), exponent)
			strength *= params.mix_amount
			if strength > 0:
				var encode = encode_pair(tx, ty)
				if encode in current_stroke.points:
					var current = current_stroke.points[encode]
					current_stroke.points[encode] = min(current + strength, 1)
				else:
					current_stroke.points[encode] = strength
				
	if current_stroke.count > 12:
		end_stroke()
		
func end_stroke():
	if !current_stroke:
		return
	var drawcol = current_stroke.colour
	for key in current_stroke.points.keys():
		var xy = decode_pair(key)
		var strength = current_stroke.points[key]
		var curcol = get_vertex_colour(xy[0], xy[1]) as Color
		drawcol.a = strength
		set_vertex_colour(xy[0], xy[1], curcol.blend(drawcol))
	current_stroke = null
	update_dirty_sectors()

func update_dirty_sectors():
	for sector in colour_data.values():
		if sector.dirty:
			build_mesh(sector)
			sector.dirty = false

func encode_pair(x, y):
	return x*10000 + y
	
func decode_pair(n):
	return [floor(n/10000), n % 10000]

func get_colour(mousepos):
	var x = clamp(floor(mousepos.x/16), 0, tile_w-1)
	var y = clamp(floor(mousepos.y/16), 0, tile_h-1)
	var col_idx = _p(x, y)
	return colour_data[col_idx]
