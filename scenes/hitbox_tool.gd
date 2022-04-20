extends Control

onready var spritelist = $tool_panel/VBoxContainer/sprite_list
onready var spritefilter = $tool_panel/VBoxContainer/sprite_name_filter
onready var showsprite = $sprite_container/Control/sprite_root/Sprite
onready var frameselect = $frameselect
onready var spriteroot = $sprite_container/Control/sprite_root
onready var container = $sprite_container

onready var e_startframe = $tool_panel/VBoxContainer/slash_opts/e_startframe
onready var e_launchtype = $tool_panel/VBoxContainer/slash_opts/e_launchtype
onready var e_follows = $tool_panel/VBoxContainer/slash_opts/e_follows
onready var e_damage = $tool_panel/VBoxContainer/slash_opts/e_damage
onready var e_poise = $tool_panel/VBoxContainer/slash_opts/e_poise
onready var e_meter = $tool_panel/VBoxContainer/slash_opts/e_meter
onready var e_hitcount = $tool_panel/VBoxContainer/slash_opts/e_hitcount
onready var e_hitdelay = $tool_panel/VBoxContainer/slash_opts/e_hitdelay
onready var e_continuous = $tool_panel/VBoxContainer/slash_opts/e_continuous
onready var e_dmgstart = $tool_panel/VBoxContainer/slash_opts/e_startframe2
onready var e_special = $tool_panel/VBoxContainer/slash_opts/e_special_case
onready var e_dmgtype = $tool_panel/VBoxContainer/slash_opts/e_dmgtype
onready var e_launchdir = $tool_panel/VBoxContainer/slash_opts/e_launchdir
onready var e_activeframes = $tool_panel/VBoxContainer/slash_opts/e_activeframes
onready var e_sfx = $tool_panel/VBoxContainer/slash_opts/e_sfx
onready var l_frame = $frameselect/l_frame


var spritelist_content = []

var current_sprite = null

# Called when the node enters the scene tree for the first time.
func _ready():
	if GmsAssetCache.project_loaded():
		set_sprite_list()
	var err = GmsAssetCache.connect("project_changed", self, "on_project_change")


func on_project_change():
	set_sprite_list()


func set_sprite_list():
	spritelist.clear()
	var all_sprites = GmsAssetCache.get_sprite_list()
	spritelist_content = []
	var filter = spritefilter.text.to_lower()
	for sprite in all_sprites:
		if (filter == "") || sprite.name.to_lower().find(filter) > -1:
			spritelist.add_item(sprite.name)
			spritelist_content.push_back(sprite)


func _on_copy_button_pressed():
	var outstr = """character_slash_set(s_generichitbox, %d, create_slash_p.%s, %s, %d,
		%d, %d, %d, %d, %s, %d, "%s", "%s", "%s", false,
		%d, %.2f, %.2f, %d, %d"""
	var rect_scale = 64
	var hitrect = container.hitrect
	var param = [
		e_startframe.value,
		e_launchtype.get_item_text(e_launchtype.get_selected_id()),
		e_follows.pressed,
		e_damage.value,
		e_poise.value,
		e_meter.value,
		e_hitcount.value,
		e_hitdelay.value,
		e_continuous.pressed,
		e_dmgstart.value,
		e_special.text,
		e_dmgtype.get_item_text(e_dmgtype.get_selected_id()),
		e_launchdir.get_item_text(e_launchdir.get_selected_id()),
		e_activeframes.value,
		abs(hitrect.size.x/rect_scale),
		abs(hitrect.size.y/rect_scale),
		hitrect.position.x + hitrect.size.x/2,
		hitrect.position.y + max(0, hitrect.size.y),
	]
	if e_sfx.text != "":
		outstr += ", %s)"
		param.append(e_sfx.text)
	else:
		outstr += ")"
	OS.clipboard = outstr % param


func on_copy_rect():
	var rect_scale = 64.0
	var hitrect = container.hitrect
	var outstr = "%.2f, %.2f, %d, %d"
	var param = [
		abs(hitrect.size.x/rect_scale),
		abs(hitrect.size.y/rect_scale),
		hitrect.position.x + hitrect.size.x/2,
		hitrect.position.y + max(0, hitrect.size.y),
	]
	OS.clipboard = outstr % param


func on_filter_change(new_text):
	set_sprite_list()


func on_sprite_selected(index):
	var path = spritelist_content[index].path
	var spriteinfo = GmsAssetCache.get_sprite(path)
	current_sprite = spriteinfo
	frameselect.max_value = spriteinfo.frames.size() - 1
	showsprite.texture = spriteinfo.frames[0]
	showsprite.offset = spriteinfo.offset
	frameselect.value = 0


func on_set_preview_frame(value):
	if current_sprite != null:
		showsprite.texture = current_sprite.frames[value]
	var frame_min = e_startframe.value
	var frame_max = frame_min + 2*(e_activeframes.value)
	container.hitbox_active = (value >= frame_min) && (value < frame_max)
	l_frame.text = "Frame %d" % value


func on_scale_slider_value_changed(value):
	spriteroot.scale = Vector2(value, value)
