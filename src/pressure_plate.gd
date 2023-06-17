extends Node3D

var on: = false

func _process(_delta):
	if $RigidBody3D.position.y < 0:
		if not on and $DebounceOn.is_stopped():
			$DebounceOn.start()
	else:
		if on and $DebounceOff.is_stopped():
			$DebounceOff.start()


func _on_debounce_on_timeout():
	#print("Now on")
	on = true


func _on_debounce_off_timeout():
	#print("Now off")
	on = false
