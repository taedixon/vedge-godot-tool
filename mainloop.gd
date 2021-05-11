extends MainLoop

var time_elapsed = 0
signal file_drop(paths)

func _initialize():
	print("Initialized:")
	print("  Starting time: %s" % str(time_elapsed))


func _drop_files(files, from_screen):
	print("See drop")
	emit_signal("file_drop", files)
