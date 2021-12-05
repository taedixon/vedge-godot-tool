extends Popup

# Declare member variables here. Examples:
onready var input = $Panel/VBoxContainer/HBoxContainer/project_input
onready var error_text = $Panel/VBoxContainer/error
var filebrowser = null

# Called when the node enters the scene tree for the first time.
func _ready():
	input.text = Config.config.get_value("paths", "last_project_file", "")

func on_browse():
	if filebrowser == null:
		filebrowser = FileDialog.new()
		filebrowser.mode = FileDialog.MODE_OPEN_FILE
		filebrowser.access = FileDialog.ACCESS_FILESYSTEM
		filebrowser.popup_exclusive = true
		var basedir = input.text.get_base_dir()
		if basedir:
			filebrowser.current_dir = basedir
		filebrowser.filters = PoolStringArray(["*.yyp ; GMS2 Project Files"])
		filebrowser.connect("file_selected", self, "on_file_selected")
		$"/root".add_child(filebrowser)
	filebrowser.popup_centered_minsize(Vector2(640, 480))
	
func on_file_selected(path):
	input.text = path
	
func on_submit():
	error_text.visible = false
	if GmsAssetCache.set_project(input.text):
		Config.config.set_value("paths", "last_project_file", input.text)
		Config.save()
		hide()
	else:
		error_text.visible = true
