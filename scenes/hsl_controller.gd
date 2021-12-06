extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var text_hue = $"panel/margin/list/text_hue"
onready var text_sat = $"panel/margin/list/text_sat"
onready var text_light = $"panel/margin/list/text_light"
onready var text_contrast = $"panel/margin/list/text_contrast"
onready var text_alpha = $"panel/margin/list/text_alpha"
onready var text_bright = $"panel/margin/list/text_bright"
onready var sprite = $"center/Control/Sprite"
onready var text_err = $"panel/margin/list/err"
onready var text_all = $"panel/margin/list/text_combine"
onready var text_bg = $"bgcolor_panel/TextEdit"

var sprite_hsv = Vector3(0, 0, 0)
var sprite_bca = Vector3(0, 1, 1)

# Called when the node enters the scene tree for the first time.
func _ready():
	var loop = load("res://mainloop.gd")
	get_tree().set_script(loop)
	var err = get_tree().connect("file_drop", self, "on_file_drop")
	assert (err == 0)

func on_file_drop(files):
	var f = files[0] as String
	var img = Image.new()
	var err = img.load(f)
	if (err == OK):
		var tex = ImageTexture.new()
		tex.create_from_image(img)
		tex.set_flags(0)
		sprite.texture = tex
	else:
		text_err.text = "Error %s" % err


func _on_lightness_changed(value):
	sprite_hsv.z = value
	(sprite.material as ShaderMaterial).set_shader_param("in_hsv", sprite_hsv)
	text_light.text = String(value)
	update_combined()


func on_sat_changed(value):
	sprite_hsv.y = value
	(sprite.material as ShaderMaterial).set_shader_param("in_hsv", sprite_hsv)
	text_sat.text = String(value)
	update_combined()


func on_hue_changed(value):
	sprite_hsv.x = value
	(sprite.material as ShaderMaterial).set_shader_param("in_hsv", sprite_hsv)
	text_hue.text = String(value)
	update_combined()

func on_scale_changed(value):
	sprite.scale = Vector2(value, value)


func on_brightness_changed(value):
	sprite_bca.x = value
	(sprite.material as ShaderMaterial).set_shader_param("in_bca", sprite_bca)
	text_bright.text = String(value)
	update_combined()


func on_contrast_changed(value):
	sprite_bca.y = value
	(sprite.material as ShaderMaterial).set_shader_param("in_bca", sprite_bca)
	text_contrast.text = String(value)
	update_combined()


func on_alpha_changed(value):
	sprite_bca.z = value
	(sprite.material as ShaderMaterial).set_shader_param("in_bca", sprite_bca)
	text_alpha.text = String(value)
	update_combined()

func update_combined():
	text_all.text = String([
		sprite_hsv.x, sprite_hsv.y, sprite_hsv.z, 
		sprite_bca.x, sprite_bca.y, sprite_bca.z])


func on_reset_pressed():
	sprite_hsv = Vector3(0, 0, 0)
	sprite_bca = Vector3(0, 1, 1)
	var s_hue = $"panel/margin/list/slider_hue"
	s_hue.value = 0
	var s_sat = $"panel/margin/list/slider_sat"
	s_sat.value = 0
	var s_val = $"panel/margin/list/slider_light"
	s_val.value = 0
	var s_bright = $"panel/margin/list/slider_bright"
	s_bright.value = 0
	var s_cont = $"panel/margin/list/slider_contrast"
	s_cont.value = 1
	var s_alpha = $"panel/margin/list/slider_alpha"
	s_alpha.value = 1


func _on_colour_text_changed():
	var parsed = Color(text_bg.text)
	VisualServer.set_default_clear_color(parsed)
