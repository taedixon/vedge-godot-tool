extends Control

signal colour_picked(mousebutton, colour)


# Declare member variables here. Examples:
onready var map = $gms_map
var active_layer = null
var last_mouse_pos = Vector2()
var mouse_travel = 0
var draw_param = {
	"tool": "DRAW",
	"radius": 32,
	"col_lmb": Color.maroon,
	"col_rmb": Color.darkslateblue,
	"falloff": "SQUARE",
	"mix": 0.5,
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func on_draw_param_change(params):
	draw_param = params
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
	if Input.is_action_just_released("map_zoom_in"):
		map.scale += Vector2(scale_strength, scale_strength)
	if Input.is_action_just_released("map_zoom_out"):
		if map.scale.x > 0.3:
			map.scale -= Vector2(scale_strength, scale_strength)
	if Input.is_action_just_pressed("map_zoom_reset"):
		map.scale = Vector2(1, 1)
	if map.scale.x != prev_scale:
		var scale_delta = map.scale.x - prev_scale
		map.position -= map.get_local_mouse_position() * scale_delta
	# keep the map onscreen at all times
	map.position.x = clamp(map.position.x, -map.bounds.size.x * map.scale.x + 64, rect_size.x - 64)
	map.position.y = clamp(map.position.y, -map.bounds.size.y * map.scale.y + 64, rect_size.y - 64)
	
	var mousepos = get_local_mouse_position()
	if mousepos != last_mouse_pos:
		mouse_travel += last_mouse_pos.distance_to(mousepos)
		last_mouse_pos = mousepos
		update()
		
	var mb = 0
	if (Input.get_mouse_button_mask() & BUTTON_MASK_LEFT) != 0:
		mb = BUTTON_LEFT
	elif (Input.get_mouse_button_mask() & BUTTON_MASK_RIGHT) != 0:
		mb = BUTTON_RIGHT
		
	match draw_param.tool:
		"DRAW":
			if mb != 0:
				if mouse_travel > 4:
					map.add_stroke_point(mb, draw_param)
					mouse_travel = 0
			else:
				mouse_travel = 0
				map.end_stroke()
		"PICK":
			if mb != 0:
				var col = map.get_picked_colour()
				if col:
					emit_signal("colour_picked", mb, col)
		
func on_focus_loss():
	update()

func on_focus_gain():
	update()

func _draw():
	if has_focus():
		draw_rect(Rect2(0, 0, rect_size.x, rect_size.y), Color.wheat, false)
		if map.layer_editable():
			match draw_param.tool:
				"DRAW":
					draw_arc(last_mouse_pos, draw_param.radius * map.scale.x, 0, 2*PI, 16, Color.magenta)
				"PICK":
					var drawcol = map.get_picked_colour()
					if !drawcol:
						drawcol = Color.black
					draw_circle(last_mouse_pos, 6, drawcol)
		else:
			var offsetA = Vector2(8, 8)
			var offsetB = Vector2(-8, 8)
			draw_line(last_mouse_pos + offsetA, last_mouse_pos - offsetA, Color.red, 2)
			draw_line(last_mouse_pos + offsetB, last_mouse_pos - offsetB, Color.red, 2)
				

func on_mouse_exit():
	release_focus()
	map.end_stroke()

func on_mouse_enter():
	grab_focus()
