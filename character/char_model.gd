extends Node3D

var moving: = false
var on_floor: = true

var jump_frames: = 0
const JUMP_MIN: = 5

@onready var anim_tree: AnimationNodeStateMachine = $AnimationTree.tree_root
@onready var anim_state_machine: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/playback")

func play(anim: String) -> void:
	if anim_tree.has_node(anim):
		var to_node: = anim
		if anim_state_machine.get_fading_from_node() == anim:
			if anim_tree.has_node(anim + "Alt"):
				#to_node = anim + "Alt"
				print(anim_state_machine.get_current_node())
		anim_state_machine.travel(to_node)
		if anim == "Jump":
			jump_frames = JUMP_MIN

func get_playing_anim() -> String:
	return anim_state_machine.get_current_node()

func _process(_delta):
	if jump_frames > 0:
		jump_frames -= 1
