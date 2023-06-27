extends Node3D

@export var no_grapple_color: Color = Color.RED
@export var grapple_color: Color = Color.GREEN

@onready var matt: StandardMaterial3D = $MeshInstance3D.get_surface_override_material(0)
var color_cache: = false

func show_me() -> void:
	visible = true
	$AnimationPlayer.play("pulse")


func hide_me() -> void:
	visible = false
	$AnimationPlayer.stop()


func update_color(valid: bool) -> void:
	if valid == color_cache:
		return
	color_cache = valid
	matt.albedo_color = grapple_color if valid else no_grapple_color
