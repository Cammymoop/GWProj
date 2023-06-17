extends RigidBody3D

@export var travelTime : float
@export var delay : float

enum ActivationMode {
	CONTINUOUS_ONE_WAY,
	CONTINUOUS_LOOP,
	CONTINUOUS_SPRING,
	TOGGLE_DESTINATION,
	TOGGLE_LOOP,
	NO_TAKEBACKS,
}
@export var activation_mode : ActivationMode = ActivationMode.TOGGLE_DESTINATION

@export var activator: NodePath
var last_activator: Node = null

@export var end_position_node: NodePath

var moving_forward: = true
var looping: = false
var start_position : Vector3
var end_position : Vector3
var deltaMove : Vector3

var current_progress: float = 0.0
var total_time: float = 0.0

var active: = false

var my_tween: Tween = null

func _ready():
	if end_position_node.is_empty():
		var end_node = get_node_or_null("../EndPos")
		if end_node:
			end_position = end_node.global_position
		else:
			print("No end position node found")
			set_process(false)
			return
	else:
		end_position = get_node(end_position_node).global_position
	start_position = global_position

	if activation_mode in [ActivationMode.CONTINUOUS_LOOP, ActivationMode.TOGGLE_LOOP]:
		looping = true
	
	if activation_mode == ActivationMode.TOGGLE_DESTINATION:
		moving_forward = false

	total_time = travelTime
	if looping:
		total_time = (total_time + delay) * 2

	if activator:
		set_new_activator(get_node(activator))

func set_new_activator(new_activator: Node) -> void:
	if new_activator == null:
		return
	if not new_activator.has_signal("state_changed"):
		return
	
	if last_activator and is_instance_valid(last_activator):
		last_activator.disconnect("state_changed", do_activate)
	last_activator = new_activator
	new_activator.connect("state_changed", do_activate)

func do_activate(new_on_state: bool) -> void:
	match activation_mode:
		ActivationMode.CONTINUOUS_ONE_WAY, ActivationMode.CONTINUOUS_LOOP:
			active = new_on_state
		ActivationMode.CONTINUOUS_SPRING:
			active = true
			moving_forward = new_on_state
		ActivationMode.TOGGLE_DESTINATION:
			if new_on_state:
				active = true
				moving_forward = not moving_forward
		ActivationMode.TOGGLE_LOOP:
			if new_on_state:
				active = not active
		ActivationMode.NO_TAKEBACKS:
			if new_on_state:
				active = true


func _process(delta):
	if not active:
		return
	
	if moving_forward:
		if looping:
			current_progress = fmod(current_progress + (delta / total_time), 1.0)
		else:
			current_progress = min(current_progress + (delta / total_time), 1.0)
	else:
		if looping:
			current_progress = fposmod(current_progress - (delta / total_time), 1.0)
		else:
			current_progress = max(current_progress - (delta / total_time), 0.0)
	

	var progress = current_progress
	if looping:
		progress = get_looped_adjusted_progress()
		
	var from_pos = global_position
	global_position = get_new_position(progress)
	deltaMove = global_position - from_pos

	if not looping and from_pos == global_position:
		active = false

func get_new_position(progress: float) -> Vector3:
	#return Tween.interpolate_value(start_position, end_position - start_position, progress * total_time, total_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	return lerp(start_position, end_position, progress)

func get_looped_adjusted_progress() -> float:
	var adjusted_progress = fmod(current_progress * 2.0, 1.0)
	var adjustment_ratio = total_time / (travelTime * 2.0) # inverse ratio of total time to travel time both ways
	adjusted_progress = min(adjusted_progress * adjustment_ratio, 1.0)
	if current_progress >= 0.5:
		adjusted_progress = 1.0 - adjusted_progress
	return adjusted_progress
	
# func setup_tween(start_pos, end_pos):
# 	var tween = create_tween()
# 	tween.set_trans(Tween.TRANS_LINEAR)
# 	tween.set_loops()
# 	tween.tween_property(self, "global_position", end_pos, travelTime)
# 	tween.tween_interval(delay)
# 	tween.tween_property(self, "global_position", start_pos, travelTime)
# 	tween.tween_interval(delay)

func get_delta_motion():
	return deltaMove	
