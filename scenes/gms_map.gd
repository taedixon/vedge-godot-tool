extends Node2D


# Declare member variables here. Examples:
var _roomdata = null
export (String) var room_path setget set_room_path


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_room_path(p):
	room_path = p
	if typeof(room_path) == TYPE_STRING:
		_roomdata = load_room_data(room_path)

func load_room_data(path):
	var f = File.new()
	f.open(path, File.READ)
	var content = f.get_as_text()
	var parsed = JSON.parse(content)
	if parsed.error == OK:
		_roomdata = parsed.result
		populate_map(_roomdata)
	else:
		print(parsed.error_string)
		
func populate_map(roomdata):
	pass
