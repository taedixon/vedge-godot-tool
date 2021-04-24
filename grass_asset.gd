tool
extends Sprite
class_name GrassSprite

export (Vector2) var weight_end setget set_weight
export (String) var gml_asset_name
export (String, "LINEAR", "RADIAL") var weight_mode = "LINEAR"

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func set_weight(vec2):
	weight_end = vec2
	update()
	
func get_gml_name():
	if (!gml_asset_name.empty()):
		return gml_asset_name
	var name = texture.resource_path.rstrip(".png")
	return name.substr(name.find_last("/") + 1)

func get_data():
	var offset_weight_end = -offset + weight_end 
	var data = [
		texture.get_width(), 
		texture.get_height(), 
		-offset.x, 
		-offset.y,
		offset_weight_end.x, 
		offset_weight_end.y,
		"FOLIAGE_WEIGHT.%s" % weight_mode]
	var floored = []
	for i in data:
		if TYPE_REAL == typeof(i):
			floored.append(int(i))
		else:
			floored.append(i)
	return floored

func _draw():
	draw_line(Vector2(0, 0), weight_end, Color.blue, 1.1, true)
	draw_circle(weight_end, 1.5, Color.red)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
