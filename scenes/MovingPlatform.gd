extends Node3D

@export var travelTime : float
@export var delay : float


@onready var endPos = get_node("../EndPos")
@onready var StartPos = self.global_position
var moveTowardsEnd = true
var oldPosition : Vector3
var deltaMove : Vector3
#@onready var startPos = parent.get_node("StartPos")

# Called when the node enters the scene tree for the first time.
func _ready():
	if(endPos == null): return
	startTween(endPos.global_position)
	oldPosition = global_position
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
		
		deltaMove = global_position - oldPosition
		oldPosition = global_position
	
func startTween(pos):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_loops()
	tween.tween_property(self, "global_position", pos,travelTime)
	tween.tween_interval(delay)
	tween.tween_property(self, "global_position", StartPos,travelTime)
	tween.tween_interval(delay)
	pass
	
