extends Control

signal colour_picked(mousebutton, colour)

# Declare member variables here. Examples:
onready var map = $gms_map
var active_layer = null
var last_mouse_pos = Vector2()
var mouse_travel = 0
var draw_param = { }

var selection_param = { }

var tool_rect = Rect2()
var rect_state = 0
var rect_button = 0

var colour_picking = false
var selection_points = PoolVector2Array()
var selection_mode = false

func on_draw_param_change(params):
	draw_param = params
	map.set_show_tris(params.show_tris)
	rect_state = 0
	update()
	map.set_overlay_visible(params.show_selection)
	
func on_selection_param_change(params):
	selection_param = params
	rect_state = 0
	map.set_selection_invert(params.inverted)
	update()
	
func on_selection_mode_toggle(state):
	selection_mode = state
	if selection_mode:
		map.set_overlay_visible(true)
	else:
		map.set_overlay_visible(draw_param.show_selection)
	var toast_txt = "Selection Mode" if selection_mode else "Edit Mode"
	var toast = Toast.new(toast_txt, Toast.LENGTH_SHORT)
	get_node("/root").add_child(toast)
	toast.show()
	update()

func _process(delta):
	if !has_focus():
		return
	var translate_spd = 500
	var scale_strength = 0.2
	if Input.is_key_pressed(KEY_SHIFT):
		translate_spd *= 2
	translate_spd *= max(1, map.scale.x)
	map.position.x += Input.get_action_strength("scroll_left") * translate_spd * delta
	map.position.x -= Input.get_action_strength("scroll_right") * translate_spd *  delta
	map.position.y += Input.get_action_strength("scroll_up") * translate_spd *  delta
	map.position.y -= Input.get_action_strength("scroll_down") * translate_spd *  delta
	var prev_scale = map.scale.x
	var new_scale = prev_scale
	var ctrl_held = Input.is_key_pressed(KEY_CONTROL)
	var mmb_held = (Input.get_mouse_button_mask() & BUTTON_MASK_MIDDLE) != 0
	
	if Input.is_action_just_released("map_zoom_in"):
		new_scale += scale_strength
	if Input.is_action_just_released("map_zoom_out"):
		if map.scale.x > 0.3:
			new_scale -= scale_strength
	if ctrl_held && Input.is_action_just_pressed("map_zoom_reset"):
		new_scale = 1
	if new_scale != prev_scale:
		var scale_delta = new_scale - prev_scale
		map.position -= map.get_local_mouse_position() * scale_delta
		map.scale = Vector2(new_scale,new_scale)
	# keep the map onscreen at all times
	map.position.x = clamp(map.position.x, -map.bounds.size.x * map.scale.x + 64, rect_size.x - 64)
	map.position.y = clamp(map.position.y, -map.bounds.size.y * map.scale.y + 64, rect_size.y - 64)
	
	var mousepos = get_local_mouse_position()
	if mousepos != last_mouse_pos:
		if !ctrl_held && mmb_held:
			map.position += (mousepos - last_mouse_pos)
		mouse_travel += last_mouse_pos.distance_to(mousepos)
		update()
	
	colour_picking = Input.is_key_pressed(KEY_ALT)
		
	var mb = 0
	if (Input.get_mouse_button_mask() & BUTTON_MASK_LEFT) != 0:
		mb = BUTTON_LEFT
	elif (Input.get_mouse_button_mask() & BUTTON_MASK_RIGHT) != 0:
		mb = BUTTON_RIGHT
		
	# input handling
	if selection_mode:
		process_selection_tool(mb, mousepos)
	elif colour_picking:
		process_colour_picker(mb)
	else:
		process_regular_tool(mb, mousepos)
		
	# undo/redo
	if Input.is_action_just_pressed("tool_redo"):
		map.end_stroke()
		map.redo()
	elif Input.is_action_just_pressed("tool_undo"):
		map.end_stroke()
		map.undo()
	last_mouse_pos = mousepos
		
func process_colour_picker(mb):
	if mb != 0:
		var col = map.get_picked_colour()
		if col:
			emit_signal("colour_picked", mb, col)

func process_selection_tool(mb, mousepos):
	var should_commit = false
	match selection_param.tool:
		"LASSO":
			should_commit = update_lasso(mb, mousepos)
		"RECT":
			should_commit = update_tool_rect(mb, mousepos)
			if should_commit:
				if abs(tool_rect.get_area()) > 64:
					selection_points = PoolVector2Array([
						tool_rect.position,
						tool_rect.position + Vector2(tool_rect.size.x, 0),
						tool_rect.position + tool_rect.size,
						tool_rect.position + Vector2(0, tool_rect.size.y),
					])
				else:
					selection_points = PoolVector2Array()
		"GRAB":
			update_tool_rect(mb, mousepos)
			if rect_state == 1:
				var mouse_delta = mousepos - last_mouse_pos
				var transform = Transform2D(0, mouse_delta)
				map.selection = transform.xform(map.selection)
	if should_commit:
		if selection_points.size() > 3:
			selection_points.append(selection_points[0])
			if Input.is_key_pressed(KEY_SHIFT):
				var combined = Geometry.clip_polygons_2d(map.selection, selection_points)
				if combined.size() == 1:
					map.selection = combined[0]
			elif Input.is_key_pressed(KEY_CONTROL):
				var combined = Geometry.merge_polygons_2d(map.selection, selection_points)
				if combined.size() == 1:
					map.selection = combined[0]
			else:
				map.selection = selection_points
			update()
		else:
			map.selection = PoolVector2Array()
		selection_points = PoolVector2Array()
	
func process_regular_tool(mb, mousepos):
	match draw_param.tool:
		"DRAW":
			if mb != 0:
				if mouse_travel > 4:
					map.add_stroke_point(mb, draw_param)
					mouse_travel = 0
			else:
				mouse_travel = 0
				map.end_stroke()
		"RECT", "BLUR":
			if update_tool_rect(mb, mousepos):
				map.add_stroke_rect(rect_button, tool_rect, draw_param)
		"FILL":
			if mouse_travel > 10 && mb != 0:
				mouse_travel = 0
				map.add_stroke_fill(mb, draw_param)
		"GRAD":
			if update_tool_rect(mb, mousepos):
				map.add_stroke_gradient(get_gradient_colors(), tool_rect.position, tool_rect.position + tool_rect.size, draw_param)
	
# returns true if rect was committed
func update_tool_rect(mb, mousepos):
	if (mb != 0) && rect_state == 0:
		tool_rect = Rect2(mousepos, Vector2())
		rect_button = mb
		rect_state = 1
	else:
		var both_mousebutton = (Input.get_mouse_button_mask() & (BUTTON_MASK_LEFT|BUTTON_MASK_RIGHT)) == BUTTON_MASK_LEFT|BUTTON_MASK_RIGHT
		if both_mousebutton:
			rect_state = -1
			update()
		elif (mb == 0) && (rect_state == 1):
			rect_state = 0
			update()
			return true
		elif (mb == 0) && rect_state == -1:
			rect_state = 0
		else:
			tool_rect.size = mousepos - tool_rect.position
	return false
	
func update_lasso(mb, mousepos):
	if (mb != 0) && rect_state == 0:
		selection_points.append(mousepos)
		rect_button = mb
		rect_state = 1
	else:
		var both_mousebutton = (Input.get_mouse_button_mask() & (BUTTON_MASK_LEFT|BUTTON_MASK_RIGHT)) == BUTTON_MASK_LEFT|BUTTON_MASK_RIGHT
		if both_mousebutton:
			rect_state = -1
			selection_points = PoolVector2Array()
			update()
		elif (mb == 0) && (rect_state == 1):
			rect_state = 0
			update()
			return true
		elif (mb == 0) && rect_state == -1:
			rect_state = 0
		elif rect_state == 1:
			if mouse_travel > 8:
				selection_points.append(mousepos)
				mouse_travel = 0
				update()
	return false
		
func on_focus_loss():
	update()

func on_focus_gain():
	update()

func _draw():
	if has_focus():
		var outline = Color.deepskyblue if selection_mode else Color.wheat
		draw_rect(Rect2(0, 0, rect_size.x, rect_size.y), outline, false, 2.0)
		if map.layer_editable():
			if selection_mode:
				match selection_param.tool:
					"LASSO":
						if rect_state == 1 && selection_points.size() > 2:
							draw_polyline(selection_points, Color.magenta)
					"RECT":
						if rect_state == 1:
							draw_rect(tool_rect, Color.magenta, false)
			elif colour_picking:
				var drawcol = map.get_picked_colour()
				if !drawcol:
					drawcol = Color.black
				draw_circle(last_mouse_pos, 6, drawcol)
			else:
				match draw_param.tool:
					"DRAW":
						draw_arc(last_mouse_pos, draw_param.radius * map.scale.x, 0, 2*PI, 16, Color.magenta)
					"RECT":
						if rect_state == 1:
							draw_rect(tool_rect, Color.magenta, false, 2.0)
					"BLUR":
						if rect_state == 1:
							draw_rect(tool_rect, Color.cyan, false, 2.0)
					"FILL":
						draw_rect(Rect2(last_mouse_pos - Vector2(16, 16), Vector2(32, 32)), Color.magenta)
					"GRAD":
						if rect_state == 1:
							var pl_point = PoolVector2Array([tool_rect.position, tool_rect.position + tool_rect.size])
							var arr_col = get_gradient_colors()
							var pl_col = PoolColorArray(arr_col) 
							draw_polyline_colors(pl_point, pl_col, 2, true)
		else:
			var offsetA = Vector2(8, 8)
			var offsetB = Vector2(-8, 8)
			draw_line(last_mouse_pos + offsetA, last_mouse_pos - offsetA, Color.red, 2)
			draw_line(last_mouse_pos + offsetB, last_mouse_pos - offsetB, Color.red, 2)

func get_gradient_colors():
	return [draw_param.col_lmb, draw_param.col_rmb] if rect_button == BUTTON_LEFT else [draw_param.col_rmb, draw_param.col_lmb]

func on_mouse_exit():
	release_focus()
	map.end_stroke()

func on_mouse_enter():
	grab_focus()

func on_request_selection_clear():
	selection_points = PoolVector2Array()
	map.selection = selection_points
