extends Node2D

var layer_data = null
var light_data = null
var colour_data = []
var tile_w = 0
var tile_h = 0
onready var mesh = $mesh
onready var _showpoint = $points

var light_mat = preload("res://shadermat/shd_light_layer.gdshader") as Shader
var dark_mat = preload("res://shadermat/shd_shadow_layer.gdshader") as Shader
const gaussian_55 = [
	1.0/256, 4.0/256, 6.0/256, 4.0/256, 1.0/256,
	4.0/256, 16.0/256, 24.0/256, 16.0/256, 4.0/256,
	6.0/256, 24.0/256, 36.0/256, 24.0/256, 6.0/256,
	4.0/256, 16.0/256, 24.0/256, 16.0/256, 4.0/256,
	1.0/256, 4.0/256, 6.0/256, 4.0/256, 1.0/256,
]

var current_stroke = null

# Called when the node enters the scene tree for the first time.
func _ready():
	if layer_data && light_data && !mesh.mesh:
		build_colors()
		build_mesh()

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
	colour_data = PoolColorArray()
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
			colour_data.append(aggregate)
	

func _p(x, y):
	return x + y*tile_w

func build_mesh():
	var newmesh = Mesh.new()
	var pointmesh = Mesh.new()
	var surf_point = SurfaceTool.new()
	var surf = SurfaceTool.new()
	surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	surf_point.begin(Mesh.PRIMITIVE_POINTS)
	for y in range(0, tile_h - 1):
		for x in range(0, tile_w - 1):
			var c1 = colour_data[_p(x, y)]
			var p1 = Vector3(x, y, 0) * 16
			var c2 = colour_data[_p(x+1, y)]
			var p2 = Vector3(x+1, y, 0) * 16
			var c3 = colour_data[_p(x, y+1)]
			var p3 = Vector3(x, y+1, 0) * 16
			var c4 = colour_data[_p(x+1, y+1)]
			var p4 = Vector3(x+1, y+1, 0) * 16
			surf.add_color(c1)
			surf.add_vertex(p1)
			surf.add_color(c2)
			surf.add_vertex(p2)
			surf.add_color(c3)
			surf.add_vertex(p3)
			
			surf.add_color(c2)
			surf.add_vertex(p2)
			surf.add_color(c4)
			surf.add_vertex(p4)
			surf.add_color(c3)
			surf.add_vertex(p3)
			
			surf_point.add_color(c1)
			surf_point.add_vertex(p1)
			
	surf.commit(newmesh)
	surf_point.commit(pointmesh)
	mesh.mesh = newmesh
	_showpoint.mesh = pointmesh
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
	
	mesh.material = mesh_mat
	
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
		var col_idx = _p(xy[0], xy[1])
		var curcol = colour_data[col_idx] as Color
		drawcol.a = strength
		colour_data[col_idx] = curcol.blend(drawcol)
	build_mesh()
	current_stroke = null

func encode_pair(x, y):
	return x*10000 + y
	
func decode_pair(n):
	return [floor(n/10000), n % 10000]

func get_colour(mousepos):
	var x = clamp(floor(mousepos.x/16), 0, tile_w-1)
	var y = clamp(floor(mousepos.y/16), 0, tile_h-1)
	var col_idx = _p(x, y)
	return colour_data[col_idx]
