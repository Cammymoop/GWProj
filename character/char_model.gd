extends Node3D

var moving: = false
var on_floor: = true

var jump_frames: = 0
const JUMP_MIN: = 5

@onready var anim_tree: AnimationNodeStateMachine = $AnimationTree.tree_root
@onready var anim_state_machine: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/playback")

func play(anim: String) -> void:
	if anim_tree.has_node(anim):
		anim_state_machine.travel(anim)
		if anim == "Jump":
			jump_frames = JUMP_MIN

func _process(_delta):
	if jump_frames > 0:
		jump_frames -= 1
