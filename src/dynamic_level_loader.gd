extends Node3D

var active := false
var levels = []
var current_level_index = -1

var lvl_script = preload("res://src/dynamic_level.gd")


func _ready():
	print_debug("dynamic level manager initializing")
	if get_child_count() < 1:
		print("No start level.")
		return

	levels.append(get_child(0))

	await get_tree().process_frame
	set_current_level(0)


func set_current_level(new_index) -> void:
	if new_index < 0 or new_index >= len(levels):
		print("Invalid level index.")
		return

	if current_level_index != new_index:
		current_level_index = new_index

		if current_level_index > 1:
			remove_earlier_levels()
		if current_level_index < len(levels) - 2:
			remove_later_levels()

		print_debug("current level index: %s" % current_level_index)

		var cur_level: Node3D = levels[current_level_index]
		if cur_level.get_script() != lvl_script:
			print_debug("level doesn't extend dynamic_level.gd")
			return

		if current_level_index == len(levels) - 1:
			var next_path = cur_level.next_scene
			print_debug("loading next level: %s" % next_path)
			var loaded: PackedScene = load("res://" + next_path) as PackedScene
			if not loaded:
				print_debug("Failed to load next level: %s" % next_path)
				return

			var new_level: Node3D = loaded.instantiate()
			if new_level.get_script() != lvl_script:
				print_debug("level %s doesn't extend dynamic_level.gd" % next_path)
				return

			var no_entrance = new_level.entrance == null or new_level.entrance.is_empty()
			if no_entrance or not (new_level.get_node(new_level.entrance) as Node3D):
				print_debug("next level doesn't have an entrance")
				new_level.queue_free()
				return

			var end_position: Node3D = cur_level.get_node(cur_level.exit) as Node3D
			var start_offset: Node3D = new_level.get_node(new_level.entrance) as Node3D

			# Note, here I can't set global_transform on the new level because it's not in the tree yet
			# transform is going to be equivalent in this case, because the level loader base node has a 0 transform
			var entrance_offset_local = start_offset.transform.inverse() * Vector3.ZERO
			new_level.transform = Transform3D(
				end_position.global_transform.rotated_local(Vector3(0, 1, 0), PI)
			)
			new_level.transform.origin = new_level.transform * entrance_offset_local
			add_child(new_level)

			new_level.find_child("Player").queue_free()
		else:
			print_debug("next level is already present")


func remove_earlier_levels() -> void:
	print_debug("culling earlier levels")
	var remove_count = current_level_index - 1
	for i in range(0, remove_count):
		levels[i].queue_free()

	levels = levels.slice(remove_count)
	current_level_index -= remove_count


func remove_later_levels() -> void:
	print_debug("culling later levels")
	for i in range(current_level_index + 2, len(levels) + 1):
		levels[i].queue_free()

	levels = levels.slice(0, current_level_index + 2)
