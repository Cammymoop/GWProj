extends Node3D

func show_me() -> void:
	visible = true
	$AnimationPlayer.play("pulse")

func hide_me() -> void:
	visible = false
	$AnimationPlayer.stop()
