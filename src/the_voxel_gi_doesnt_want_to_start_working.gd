extends VoxelGI

func _ready():
	data = null
	$Timer.start()


func _on_timer_timeout():
	print("ooh!")
	data = load("res://baked/test_world_interior_voxel_gi_data.res")
