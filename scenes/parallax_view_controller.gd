extends Control

onready var map = $gms_map

var cam_position = Vector2()
const view_size = Vector2(480, 270)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _process(delta):
	if !has_focus():
		return
	var translate_spd = 500
	#var scale_strength = 0.2
	if Input.is_key_pressed(KEY_SHIFT):
		translate_spd *= 2
	translate_spd *= max(1, map.scale.x)
	var last_cam_position = cam_position
	cam_position.x -= Input.get_action_strength("scroll_left") * translate_spd * delta
	cam_position.x += Input.get_action_strength("scroll_right") * translate_spd *  delta
	cam_position.y -= Input.get_action_strength("scroll_up") * translate_spd *  delta
	cam_position.y += Input.get_action_strength("scroll_down") * translate_spd *  delta
	
	cam_position.x = clamp(cam_position.x, view_size.x/2, map.bounds.size.x - view_size.x/2)
	cam_position.y = clamp(cam_position.y, view_size.y/2, map.bounds.size.y - view_size.y/2)
	
	if cam_position != last_cam_position:
		var cam_bounds = Rect2(cam_position - view_size/2, view_size)
		var bound_begin = cam_bounds.position
		var bound_end = cam_bounds.position + cam_bounds.size
		var margin = 16
		map.position.x = clamp(map.position.x, -bound_begin.x + margin, -bound_end.x + rect_size.x - margin)
		map.position.y = clamp(map.position.y, -bound_begin.y + margin, -bound_end.y + rect_size.y - margin)
		map.camera_offset = bound_begin
		update()
	
func _draw():
	var offset_cam_position = cam_position + map.position
	var cam_rect = Rect2(offset_cam_position - view_size/2, view_size)
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

