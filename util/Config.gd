extends Node


# Declare member variables here. Examples:
var config = ConfigFile.new()
const save_path = "user://vedge_tool.cfg"

func _ready():
	config.load(save_path)

func save():
	config.save(save_path)
