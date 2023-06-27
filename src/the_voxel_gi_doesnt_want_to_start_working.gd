extends VoxelGI

func _ready():
	await get_tree().create_timer(0.3).timeout
	if data:
		set_base(data.get_rid())
