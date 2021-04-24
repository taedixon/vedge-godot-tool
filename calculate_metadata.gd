extends Node2D


onready var asset_list = $assets
onready var output = $output


# Called when the node enters the scene tree for the first time.
func _ready():
	var items = []
	for asset in asset_list.get_children():
		if asset is GrassSprite:
			var asset_name = asset.get_gml_name()
			var asset_data = asset.get_data()
			items.append("ds_map_add(global.grass_metadata, \"%s\", %s)" % [
				asset_name, 
				var2str(asset_data).replace('"', "")])
	output.text = PoolStringArray(items).join("\n")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
