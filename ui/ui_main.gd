extends Control


# Declare member variables here. Examples:
onready var scene_container = $active_scene
var scn_hsl = preload("res://scenes/hsl_editor.tscn")
var scn_plants = preload("res://scenes/asset_metadata.tscn")
var scn_lights = preload("res://scenes/light_editor.tscn")
var active_scene = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	var menu_file = $menu_bar/MarginContainer/HBoxContainer/menu_file
	menu_file.get_popup().connect("id_pressed", self, "on_menu_file")
	var scut = ShortCut.new()
	var evt = InputEventKey.new()
	evt.set_scancode(KEY_F2)
	scut.set_shortcut(evt)
	menu_file.get_popup().set_item_shortcut(1, scut)
	
	var menu_tool = $menu_bar/MarginContainer/HBoxContainer/menu_tool
	menu_tool.get_popup().connect("id_pressed", self, "on_menu_tool")
	# debug
	GmsAssetCache.set_project(Config.config.get_value("paths", "last_project_file"))
	active_scene = scene_container.get_child(0)


func on_menu_file(id):
	match id:
		0:
			pass
		1:
			if active_scene.has_method("save"):
				active_scene.save()
				var toast = Toast.new("Room Saved", Toast.LENGTH_LONG)
				get_node("/root").add_child(toast)
				toast.show()
			
func on_menu_tool(id):
	for node in scene_container.get_children():
		if node.has_method("commit_changes"):
			node.commit_changes()
		scene_container.remove_child(node)
	var next_scene
	match id:
		0:
			next_scene = scn_hsl.instance()
		1:
			next_scene = scn_plants.instance()
		2:
			next_scene = scn_lights.instance()
			if (!GmsAssetCache.project_loaded()):
				$project_select.popup_centered()
	if next_scene:
		scene_container.add_child(next_scene)
		active_scene = next_scene
