extends Control

onready var map = $gms_map

var cam_position = Vector2()
var last_mousepos = Vector2()
const view_size = Vector2(480, 270)
var view_scale = 1.0


func _process(delta):
	if !has_focus():
		return
	var translate_spd = 500
	var scale_strength = 0.2
	if Input.is_key_pressed(KEY_SHIFT):
		translate_spd *= 2
	translate_spd *= max(1, map.scale.x)
	var last_cam_position = cam_position
	var ctrl_held = Input.is_key_pressed(KEY_CONTROL)
	var mmb_held = (Input.get_mouse_button_mask() & BUTTON_MASK_MIDDLE) != 0
	cam_position.x -= Input.get_action_strength("scroll_left") * translate_spd * delta
	cam_position.x += Input.get_action_strength("scroll_right") * translate_spd *  delta
	cam_position.y -= Input.get_action_strength("scroll_up") * translate_spd *  delta
	cam_position.y += Input.get_action_strength("scroll_down") * translate_spd *  delta
	if !ctrl_held && mmb_held:
		cam_position += get_local_mouse_position() - last_mousepos
	last_mousepos = get_local_mouse_position()
		
	cam_position.x = clamp(cam_position.x, view_size.x/2, map.bounds.size.x - view_size.x/2)
	cam_position.y = clamp(cam_position.y, view_size.y/2, map.bounds.size.y - view_size.y/2)
	
	if cam_position != last_cam_position:
		var bound_begin = (cam_position - view_size/2) * view_scale
		var bound_end = (cam_position + view_size/2) * view_scale
		var margin = 16
		map.position.x = clamp(map.position.x, -bound_begin.x + margin, -bound_end.x + rect_size.x - margin)
		map.position.y = clamp(map.position.y, -bound_begin.y + margin, -bound_end.y + rect_size.y - margin)
		map.camera_offset = cam_position - view_size/2
		update()
	
	var prev_scale = map.scale.x
	var new_scale = prev_scale
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
		view_scale = new_scale
		update()

func _draw():
	if map.room_name != "":
		var offset_cam_position = cam_position* view_scale + map.position
		var cam_rect = Rect2(offset_cam_position - view_size/2*view_scale, view_size * view_scale)
		draw_rect(cam_rect, Color.red, false, 2.0)
		var off1 = Vector2(-2, 0)
		var off2 = Vector2(0, -2)
		draw_line(offset_cam_position + off1, offset_cam_position - off1, Color.red)
		draw_line(offset_cam_position + off2, offset_cam_position - off2, Color.red)
		if has_focus():
			draw_rect(Rect2(0, 0, rect_size.x, rect_size.y), Color.wheat, false)

func on_focus_loss():
	update()

func on_focus_gain():
	update()
	
func on_mouse_exit():
	release_focus()

func on_mouse_enter():
	grab_focus()

func on_room_changed():
	cam_position = map.bounds.size/2 + view_size/2
	view_scale = 1.0
	update()
