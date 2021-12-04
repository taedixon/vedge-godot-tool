class_name GmsTool

static func load_yy(path):
	var f = File.new()
	f.open(path, File.READ)
	var content = f.get_as_text()
	f.close()
	var parsed = JSON.parse(content)
	if parsed.error == OK:
		return parsed.result
	else:
		push_error(parsed.error_string)
