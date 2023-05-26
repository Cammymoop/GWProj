extends OmniLight3D

@export var target_energy: = 1.4
@export var variance: = 0.1
@export var height_variance: = 0.04

var timer = 0.06

@onready var y_home: float = global_position.y

func _process(delta):
	timer -= delta
	if timer < 0:
		timer = 0.06
	else:
		return
	var vary: = (randf() * 2) -1
	light_energy = target_energy + (vary * variance)
	#set_deferred("light_energy", target_energy + vary)
	
	global_position.y = y_home + (vary * height_variance)
