extends Polygon2D

export (Color) var fill_col = Color.white
export (Color) var border_col = Color.white

var selection = PoolVector2Array() setget set_selection
var selection_col = PoolVector2Array()

# Called when the node enters the scene tree for the first time.
func _draw():
	if polygon.size() > 1:
		draw_polyline(polygon, border_col)

func set_selection(newsel):
	polygon = newsel
	selection_col = PoolColorArray()
	for _i in range(0, selection.size()):
		selection_col.append(fill_col)
	update()
