extends Control


# Declare member variables here. Examples:
onready var scene_container = $active_scene
var scn_hsl = preload("res://scenes/hsl_editor.tscn")
var scn_plants = preload("res://scenes/asset_metadata.tscn")
var scn_lights = preload("res://scenes/light_editor.tscn")
var active_scene = null


# Called when the node enters the scene tree for the first time.
func _ready():
	var menu_file = $menu_bar/MarginContainer/HBoxContainer/menu_file
	menu_file.get_popup().connect("id_pressed", self, "on_menu_file")
	
	var menu_tool = $menu_bar/MarginContainer/HBoxContainer/menu_tool
	menu_tool.get_popup().connect("id_pressed", self, "on_menu_tool")


func on_menu_file(id):
	match id:
		0:
			pass
		1:
			pass
			
func on_menu_tool(id):
	for node in scene_container.get_children():
		if "commit_changes" in node:
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
	if next_scene:
		scene_container.add_child(next_scene)
		active_scene = next_scene
