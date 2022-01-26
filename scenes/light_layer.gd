extends Node2D

var layer_data
var preview_exported_triangles = false setget set_export_preview
var detail = null setget set_detail
var tile_w = 0
var tile_h = 0

const sector_w = 32
const sector_h = 32
const apply_stroke_limit = 12
var mesh_material = null
var colour_data = {}
onready var meshgroup = $group_mesh
onready var pointgroup = $group_point
onready var bridge_mesh = $inbetween
var fill_colour = Color.white
var out_alpha = 1

var stroke_history = []
var history_location = 0

var light_mat = preload("res://shadermat/shd_light_layer.gdshader") as Shader
var dark_mat = preload("res://shadermat/shd_shadow_layer.gdshader") as Shader
var preview_mat = preload("res://shadermat/shd_show_exportable.gdshader") as Shader
const gaussian_55 = [
	1.0/256, 4.0/256, 6.0/256, 4.0/256, 1.0/256,
	4.0/256, 16.0/256, 24.0/256, 16.0/256, 4.0/256,
	6.0/256, 24.0/256, 36.0/256, 24.0/256, 6.0/256,
	4.0/256, 16.0/256, 24.0/256, 16.0/256, 4.0/256,
	1.0/256, 4.0/256, 6.0/256, 4.0/256, 1.0/256,
]

var sector_index_array = PoolIntArray()

const col_min_dist = 3/256

var current_stroke = null
var initialized = false

# Called when the node enters the scene tree for the first time.
func _ready():
	build_sector_indexes()
	if detail:
		colour_data = {}
		mesh_material = get_mesh_material()
		if layer_data:
			load_colours_from_file(layer_data)
		for sector in colour_data.values():
			build_mesh(sector)
		create_bridge_mesh()
		initialized = true
		
func set_export_preview(val):
	if val != preview_exported_triangles:
		preview_exported_triangles = val
		if initialized:
			update_mesh_material()
		
func update_mesh_material():
	mesh_material = get_mesh_material()
	for child in meshgroup.get_children():
		child.material = mesh_material
	bridge_mesh.material = mesh_material

func set_detail(new_detail):
	detail = new_detail
	if initialized:
		update_mesh_material()

func save(f: File):
	detail.vertex_count = 0
	for y in range(0, tile_h-1):
		for x in range(0, tile_w-1):
			try_save_quad(x, y, f)
	print(detail.vertex_count)
	
func try_save_quad(x, y, f: File):
	var c1 = get_vertex_colour(x, y)
	var c2 = get_vertex_colour(x+1, y)
	var c3 = get_vertex_colour(x, y+1)
	var c4 = get_vertex_colour(x+1, y+1)
	var p1 = {"x": x, "y": y, "c": c1}
	var p2 = {"x": x+1, "y": y, "c": c2}
	var p3 = {"x": x, "y": y+1, "c": c3}
	var p4 = {"x": x+1, "y": y+1, "c": c4}
	if (y % 2) == 1:
		try_save_tri(f, p1, p2, p4)
		try_save_tri(f, p1, p4, p3)
	else:
		try_save_tri(f, p1, p2, p3)
		try_save_tri(f, p3, p2, p4)
	
func try_save_tri(f: File, p1, p2, p3):
	var base_col = Color.black if detail.get("is_glow") else Color.white
	if colour_approximate(base_col, p1.c) && colour_approximate(base_col, p2.c) && colour_approximate(base_col, p3.c):
		return
	for p in [p1, p2, p3]:
		p.c.a = out_alpha
		f.store_float(p.x*16)
		f.store_float(p.y*16)
		f.store_32(p.c.to_abgr32())
		detail.vertex_count += 1
		
func colour_approximate(c1, c2):
	var dist = (abs(c1.r-c2.r) + abs(c1.g-c2.g) + abs(c1.b-c2.b))/3.0
	return dist <= col_min_dist

func sector_index(x, y):
	return x + y * sector_w

func build_sector_indexes():
	for y in range(0, sector_h-1):
		for x in range(0, sector_w-1):
			if (y % 2) == 1:
				sector_index_array.append(sector_index(x, y))
				sector_index_array.append(sector_index(x+1, y))
				sector_index_array.append(sector_index(x+1, y+1))
				
				sector_index_array.append(sector_index(x, y))
				sector_index_array.append(sector_index(x+1, y+1))
				sector_index_array.append(sector_index(x, y+1))
			else:
				sector_index_array.append(sector_index(x, y))
				sector_index_array.append(sector_index(x+1, y))
				sector_index_array.append(sector_index(x, y+1))
				
				sector_index_array.append(sector_index(x, y+1))
				sector_index_array.append(sector_index(x+1, y))
				sector_index_array.append(sector_index(x+1, y+1))

func build_colors(layer):
	var tileset_img = GmsAssetCache.get_tileset(layer.tilesetId.path).image as Image
	tileset_img.lock()
	var tileset_w = tileset_img.get_width() / 16
	var tx = 0
	var ty = 0
	for tid in layer.tiles.TileSerialiseData:
		var itid = int(tid)
		var tid_real = itid & 0x7FFFF
		var tileset_x = (tid_real % tileset_w) * 16 + 8
		var tileset_y = floor(tid_real / tileset_w) * 16 + 8
		var col = tileset_img.get_pixel(tileset_x, tileset_y)
		set_vertex_colour(tx, ty, col)
	tileset_img.unlock()
	blend_color()
	
func get_blended_color(tx, ty):
	var aggregate = Color()
	for ix in range(-2, 3):
		for iy in range(-2, 3):
			var gaussian_fac = gaussian_55[(ix+2) + (iy+2)*5]
			var sample_x = clamp(tx + ix, 0, tile_w-1)
			var sample_y = clamp(ty + iy, 0, tile_h-1)
			var rawval = get_vertex_colour(sample_x, sample_y)
			aggregate += rawval * gaussian_fac
	aggregate.a = 1
	return aggregate

func blend_color():
	for ty in tile_h:
		for tx in tile_w:
			var aggregate = get_blended_color(tx,ty)
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
				colour.append(fill_colour)
				
		var mesh = MeshInstance2D.new()
		mesh.name = "mesh_%d" % sector_key
		mesh.material = mesh_material
		meshgroup.add_child(mesh)
		var pointmesh = MeshInstance2D.new()
		pointmesh.name = "point_%d" % sector_key
		pointgroup.add_child(pointmesh)
		colour_data[sector_key] = {
			"begin_x": sector_x * sector_w,
			"begin_y": sector_y * sector_h,
			"meshinst": mesh,
			"pointinst": pointmesh,
			"colour": colour,
			"vertex": verts,
			"dirty": false,
			"dirty_bridge": false,
			"bridge_right": encode_pair(sector_x+1, sector_y) in colour_data,
			"bridge_down": encode_pair(sector_x, sector_y+1) in colour_data,
		}
		var sec_left = colour_data.get(encode_pair(sector_x-1, sector_y))
		if sec_left:
			sec_left.bridge_right = true
		var sec_up = colour_data.get(encode_pair(sector_x, sector_y-1))
		if sec_up:
			sec_up.bridge_down = true
	return colour_data[sector_key]

func set_vertex_colour(x, y, colour):
	var sector = get_colour_sector(x, y)
	var local_x = x - sector.begin_x
	var local_y = y - sector.begin_y
	sector.colour[sector_index(local_x, local_y)] = colour
	sector.dirty = true
	if (local_x == (sector_w-1) && sector.bridge_right) || (local_y == (sector_h-1) && sector.bridge_down):
		sector.dirty_bridge = true
	
func get_vertex_colour(x, y):
	var sector = get_colour_sector(x, y)
	var local_x = x - sector.begin_x
	var local_y = y - sector.begin_y
	return sector.colour[sector_index(local_x, local_y)]

func get_mesh_material():
	var mesh_mat = ShaderMaterial.new()
	if preview_exported_triangles:
		mesh_mat.shader = preview_mat
		mesh_mat.set_shader_param("ignore_col", Color.black if detail.get("is_glow") else Color.white)
		mesh_mat.set_shader_param("ignore_dist", col_min_dist)
		return mesh_mat
	if detail.get("is_glow"):
		mesh_mat.shader = light_mat
		fill_colour = Color.black
	else:
		mesh_mat.shader = dark_mat
		fill_colour = Color.white
	var u_shimmer = Vector2(1, 1)
	var u_intensity = 1
	if "intensity" in detail:
		u_intensity = float(detail["intensity"])
	if "shimmerX" in detail:
		u_shimmer.x = float(detail["shimmerX"])
	if "shimmerY" in detail:
		u_shimmer.y = float(detail["shimmerY"])
	var u_speed = float(detail.get("shimmerSpeed", 1))
	mesh_mat.set_shader_param("shimmer", u_shimmer)
	mesh_mat.set_shader_param("intensity", u_intensity)
	out_alpha = u_intensity
	mesh_mat.set_shader_param("timescale", u_speed)
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
	
func create_bridge_mesh():
	bridge_mesh.material = mesh_material
	var meshbuilder = SurfaceTool.new()
	meshbuilder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for key in colour_data.keys():
		var this_sec = colour_data[key]
		var decoded = decode_pair(int(key))
		var sector_x = decoded[0]
		var sector_y = decoded[1]
		var sec_right = colour_data.get(encode_pair(sector_x+1, sector_y))
		var sec_down = colour_data.get(encode_pair(sector_x, sector_y+1))
		var sec_diag = colour_data.get(encode_pair(sector_x+1, sector_y+1))
		if sec_right:
			this_sec.bridge_right = true
			var x = sector_w-1
			for y in range(0, sector_h-1):
				var topleft = Vector2((x+this_sec.begin_x)*16, (y+this_sec.begin_y)*16)
				var c1 = this_sec.colour[sector_index(x, y)]
				var c2 = sec_right.colour[sector_index(0, y)]
				var c3 = this_sec.colour[sector_index(x, y+1)]
				var c4 = sec_right.colour[sector_index(0, y+1)]
				tool_add_quad(meshbuilder, topleft, c1, c2, c3, c4)
		if sec_down:
			this_sec.bridge_down = true
			var y = sector_h-1
			for x in range(0, sector_w-1):
				var topleft = Vector2((x+this_sec.begin_x)*16, (y+this_sec.begin_y)*16)
				var c1 = this_sec.colour[sector_index(x, y)]
				var c2 = this_sec.colour[sector_index(x+1, y)]
				var c3 = sec_down.colour[sector_index(x, 0)]
				var c4 = sec_down.colour[sector_index(x+1, 0)]
				tool_add_quad(meshbuilder, topleft, c1, c2, c3, c4)
		if sec_right && sec_down && sec_diag:
			var topleft = Vector2((sec_diag.begin_x-1) * 16, (sec_diag.begin_y-1) * 16)
			var c1 = this_sec.colour[sector_index(sector_w-1, sector_h-1)]
			var c2 = sec_right.colour[sector_index(0, sector_h-1)]
			var c3 = sec_down.colour[sector_index(sector_w-1, 0)]
			var c4 = sec_diag.colour[0]
			tool_add_quad(meshbuilder, topleft, c1, c2, c3, c4)
	bridge_mesh.mesh = meshbuilder.commit()
			
func tool_add_quad(meshbuilder: SurfaceTool, topleft: Vector2, c1: Color, c2: Color, c3: Color, c4: Color):
	var p1 = Vector3(topleft.x, topleft.y, 0)
	var p2 = Vector3(topleft.x+16, topleft.y, 0)
	var p3 = Vector3(topleft.x, topleft.y+16, 0)
	var p4 = Vector3(topleft.x+16, topleft.y+16, 0)
	if (int(topleft.y/16) % 2) == 1:
		meshbuilder.add_color(c1)
		meshbuilder.add_vertex(p1)
		meshbuilder.add_color(c2)
		meshbuilder.add_vertex(p2)
		meshbuilder.add_color(c4)
		meshbuilder.add_vertex(p4)
		
		meshbuilder.add_color(c1)
		meshbuilder.add_vertex(p1)
		meshbuilder.add_color(c4)
		meshbuilder.add_vertex(p4)
		meshbuilder.add_color(c3)
		meshbuilder.add_vertex(p3)
	else:
		meshbuilder.add_color(c1)
		meshbuilder.add_vertex(p1)
		meshbuilder.add_color(c2)
		meshbuilder.add_vertex(p2)
		meshbuilder.add_color(c3)
		meshbuilder.add_vertex(p3)
		
		meshbuilder.add_color(c3)
		meshbuilder.add_vertex(p3)
		meshbuilder.add_color(c2)
		meshbuilder.add_vertex(p2)
		meshbuilder.add_color(c4)
		meshbuilder.add_vertex(p4)
		
	
func add_stroke_point(button, point: Vector2, params, selection):
	var use_selection = selection.size() > 4
	if current_stroke == null:
		var drawcol
		if button == BUTTON_LEFT:
			drawcol = params.col_lmb
		else:
			drawcol = params.col_rmb
		current_stroke = {
			"count": 1, 
			"points": {},
			"new_points": {},
			"basis": {},
			"colour": drawcol,
		}
	else:
		current_stroke.count += 1
		
	var xmin = max(0, ceil((point.x - params.radius)/16.0))
	var xmax = min(tile_w, floor((point.x + params.radius)/16.0))
	var ymin = max(0, ceil((point.y - params.radius)/16.0))
	var ymax = min(tile_h, floor((point.y + params.radius)/16.0))
	
	for tx in range(xmin, xmax+1):
		for ty in range(ymin, ymax+1):
			var tilecoord = Vector2(tx*16, ty*16)
			if use_selection && !(Geometry.is_point_in_polygon(tilecoord, selection)):
				continue
			var strength
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
				stroke_add_point(tx, ty, strength)
				
	if current_stroke.count > apply_stroke_limit:
		apply_stroke_new(current_stroke)
		current_stroke.count = 0
		
func add_stroke_rect(button, r: Rect2, params, selection):
	var use_selection = selection.size() > 4
	var drawcol
	if button == BUTTON_LEFT:
		drawcol = params.col_lmb
	else:
		drawcol = params.col_rmb
	current_stroke = {
		"count": 1, 
		"points": {},
		"new_points": {},
		"basis": {},
		"colour": drawcol,
	}
	var use_blur = false
	if params.tool == "BLUR":
		current_stroke.fullcolor_points = true
		use_blur = true 
	var p1 = r.position
	var p2 = r.position + r.size
	if r.size.x < 0:
		var tmp = p1.x
		p1.x = p2.x
		p2.x = tmp
	if r.size.y < 0:
		var tmp = p1.y
		p1.y = p2.y
		p2.y = tmp
		
	var xmin = max(0, ceil(p1.x/16.0))
	var xmax = min(tile_w, floor(p2.x/16.0))
	var ymin = max(0, ceil(p1.y /16.0))
	var ymax = min(tile_h, floor(p2.y/16.0))
	for tx in range(xmin, xmax+1):
		for ty in range(ymin, ymax+1):
			if use_selection && !(Geometry.is_point_in_polygon(Vector2(tx*16, ty*16), selection)):
				continue
			if use_blur:
				stroke_blur_point(tx, ty)
			else:
				stroke_add_point(tx, ty, params.mix_amount)
	end_stroke()
	
func add_stroke_gradient(cols, p1, p2, params, selection):
	var use_selection = selection.size() > 4
	current_stroke = {
		"count": 1, 
		"points": {},
		"new_points": {},
		"basis": {},
		"colour": Color.white,
		"fullcolor_points": true,
	}
	var p_len = p1.distance_to(p2)
	if p_len == 0:
		p_len = 0.001
	for tx in range(0, tile_w+1):
		for ty in range(0, tile_h+1):
			var tilecoord = Vector2(tx*16, ty*16)
			if use_selection && !(Geometry.is_point_in_polygon(Vector2(tx*16, ty*16), selection)):
				continue
			var seg_point = Geometry.get_closest_point_to_segment_2d(tilecoord, p1, p2)
			var blend_fac = p1.distance_to(seg_point)/p_len
			var point_col = cols[0].linear_interpolate(cols[1], blend_fac)
			stroke_add_point_color(tx, ty, point_col, params.mix_amount)
	end_stroke()

func stroke_add_point(tx, ty, strength):
	var encode = encode_pair(tx, ty)
	if !encode in current_stroke.basis:
		# add original colour of point
		current_stroke.basis[encode] = get_vertex_colour(tx, ty)
	if encode in current_stroke.points:
		var current = current_stroke.points[encode]
		strength = min(current + strength, 1)
	current_stroke.points[encode] = strength
	current_stroke.new_points[encode] = true
	
func stroke_add_point_color(tx, ty, col, strength):
	var encode = encode_pair(tx, ty)
	if !encode in current_stroke.basis:
		# add original colour of point
		current_stroke.basis[encode] = get_vertex_colour(tx, ty)
	var curcol = current_stroke.basis[encode]
	var mixcol = curcol.linear_interpolate(col, strength)
	current_stroke.points[encode] = mixcol
	current_stroke.new_points[encode] = true
	
func stroke_blur_point(tx, ty):
	var encode = encode_pair(tx, ty)
	if !encode in current_stroke.basis:
		# add original colour of point
		current_stroke.basis[encode] = get_vertex_colour(tx, ty)
	var blended_col = get_blended_color(tx, ty)
	current_stroke.points[encode] = blended_col
	current_stroke.new_points[encode] = true
	

# only applies new points in the stroke
func apply_stroke_new(stroke):
	apply_stroke(stroke, true)
	stroke.new_points = {}
	
# applies every point in the stroke
func apply_stroke(stroke, new_points_only=false):
	var abs_points = stroke.get("fullcolor_points", false)
	var drawcol = stroke.colour
	var keys = stroke.new_points.keys() if new_points_only else stroke.points.keys()
	for key in keys:
		var xy = decode_pair(key)
		if abs_points:
			set_vertex_colour(xy[0], xy[1], stroke.points[key])
		else:
			var strength = stroke.points[key]
			var curcol = stroke.basis[key] as Color
			drawcol.a = strength
			set_vertex_colour(xy[0], xy[1], curcol.blend(drawcol))
	update_dirty_sectors()
	

# set every point in the stroke to basis colour
func revert_stroke(stroke):
	for key in stroke.basis.keys():
		var xy = decode_pair(key)
		set_vertex_colour(xy[0], xy[1], stroke.basis[key])
	update_dirty_sectors()
	
func end_stroke():
	if !current_stroke:
		return
	if current_stroke.count > 0:
		apply_stroke(current_stroke)
	if stroke_history.size() > history_location:
		stroke_history.resize(history_location)
	stroke_history.append(current_stroke)
	history_location += 1
	current_stroke = null

func update_dirty_sectors():
	var dirty_bridge = false
	for sector in colour_data.values():
		if sector.dirty:
			build_mesh(sector)
			sector.dirty = false
		dirty_bridge = dirty_bridge || sector.dirty_bridge
	if dirty_bridge:
		create_bridge_mesh()

func encode_pair(x, y):
	return x*10000 + y
	
func decode_pair(n):
	return [floor(n/10000), n % 10000]

func get_colour(mousepos):
	var x = clamp(floor(mousepos.x/16), 0, tile_w-1)
	var y = clamp(floor(mousepos.y/16), 0, tile_h-1)
	return get_vertex_colour(x, y)

func undo():
	if history_location > 0:
		history_location -= 1
		var stroke_to_undo = stroke_history[history_location]
		revert_stroke(stroke_to_undo)
	
func redo():
	if history_location < stroke_history.size():
		var stroke_to_redo = stroke_history[history_location]
		apply_stroke(stroke_to_redo)
		history_location += 1
		
func load_colours_from_file(vertex_path):
	var meta = File.new()
	var e = meta.open(vertex_path + ".meta", File.READ)
	if e != OK:
		push_error("Failed to open meta file for " + vertex_path)
		return
	var meta_raw = meta.get_as_text()
	meta.close()
	var parsed = JSON.parse(meta_raw)
	if parsed.error != OK:
		push_error("Failed to parse meta file for " + vertex_path)
		return
	detail = parsed.result
	mesh_material = get_mesh_material()
		
	var f = File.new()
	e = f.open(vertex_path, File.READ)
	if e != OK:
		push_error("Failed to open vertex file " + vertex_path)
		return
	
	while !f.eof_reached():
		var x = floor(f.get_float() / 16)
		var y = floor(f.get_float() / 16)
		var c_raw = f.get_32()
		var c = Color8((c_raw ) & 0xFF, (c_raw >> 8 & 0xFF), (c_raw >> 16) & 0xFF)
		set_vertex_colour(x, y, c)
