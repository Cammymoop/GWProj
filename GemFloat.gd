extends Node3D

var start_pos : Vector3
var end_pos : Vector3
var rotationVector : Vector3
@export var travelTime : float = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	rotationVector = Vector3(0,2.5,0)
	start_pos = global_position
	end_pos = start_pos + Vector3.UP * 0.5
	setup_tween(start_pos,end_pos)
	setup_spinTween()


func setup_tween(start_pos, end_pos):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_loops()
	tween.tween_property(self, "global_position", end_pos,travelTime)
	tween.tween_property(self, "global_position", start_pos,travelTime)
	
func setup_spinTween():
	var spinTween = create_tween()
	spinTween.set_loops()
	spinTween.tween_property(self, "global_rotation", rotationVector, travelTime).as_relative()
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
