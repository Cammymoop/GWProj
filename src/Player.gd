extends RigidBody3D

@onready var camera_pivot = find_child("CameraHorizontalPivot")

@onready var seed_root = find_child("Seed")

var mouse_sensitivity = 0.5
var controller_look_sensitivity = 12

var floored := false

var gems_collected = 0

const GRAPPLE_LAYER := 3

@export var GRAPPLE_OFFSET := 0.6
# average speed to travel during grapple
@export var GRAPPLE_SPEED := 20.0

@export var movement_force := .6
@export var vel_limit = 5.0

@export var jump_upwards := 8.0
@export var jump_forwards := 4.0

@onready var camera_spring_arm = camera_pivot.find_child("SpringArm3D", true)
@onready var initial_camera_spring_length = camera_spring_arm.spring_length

@onready var look_ray_cast: RayCast3D = find_child("LookRayCast", true)

var controllable := true
var is_grappling := false
var grappling_to: Vector3 = Vector3.ZERO
var grappling_from: Vector3 = Vector3.ZERO
var grapple_progress := 0.0
var grapple_timescale := 1.0

var platform_push: Vector3 = Vector3.ZERO

var first_person := false


func _ready():
	randomize()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta):
	var mouse_click_used := false
	if Input.is_action_just_pressed("mouse_click"):
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_click_used = true
	if Input.is_action_just_pressed("Esc"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_pressed("Restart"):
		get_tree().reload_current_scene()

	if controllable:
		if Input.is_action_just_pressed("grapple"):
			if Input.is_action_just_pressed("mouse_click") and mouse_click_used:
				pass  # just used mouse to focus the game
			else:
				if first_person:
					if check_valid_grapple():
						initiate_grapple()
					else:
						switch_to_third_person()
				else:
					switch_to_first_person()
		if Input.is_action_just_pressed("grapple_cancel"):
			if first_person:
				switch_to_third_person()

	var controller_h_look = Input.get_axis("controller_look_left", "controller_look_right")
	var controller_v_look = Input.get_axis("controller_look_up", "controller_look_down")
	if controller_h_look or controller_v_look:
		camera_look(Vector2(controller_h_look, controller_v_look), controller_look_sensitivity)

	if first_person:
		var target_ring = $GrappleTargetRing
		look_ray_cast.force_raycast_update()
		if look_ray_cast.get_collision_point():
			target_ring.global_position = look_ray_cast.get_collision_point()
			var normal: Vector3 = look_ray_cast.get_collision_normal().normalized()
			if normal == Vector3.UP:
				target_ring.transform.basis = Basis.IDENTITY
			elif normal * -1 == Vector3.UP:
				target_ring.transform.basis = Basis.FLIP_Y
			else:
				var x_axis = normal.cross(Vector3.UP).normalized()
				target_ring.transform.basis = Basis(x_axis, normal, normal.cross(x_axis))

			target_ring.update_color(check_valid_grapple())

	if is_grappling:
		grapple_progress += delta

		global_position = Tween.interpolate_value(
			grappling_from,
			grappling_to - grappling_from,
			grapple_progress,
			grapple_timescale,
			Tween.TRANS_CUBIC,
			Tween.EASE_OUT
		)

		if grapple_progress >= grapple_timescale:
			finish_grapple()


func check_valid_grapple() -> bool:
	if look_ray_cast.get_collision_point():
		var body = look_ray_cast.get_collider() as PhysicsBody3D
		if not body:
			return false
		if body.get_collision_layer_value(GRAPPLE_LAYER):
			return true
	return false


func initiate_grapple() -> void:
	grappling_to = look_ray_cast.get_collision_point()
	grappling_to -= (grappling_to - global_transform.origin).normalized() * GRAPPLE_OFFSET
	grappling_from = global_transform.origin
	is_grappling = true
	controllable = false
	$GrappleTargetRing.hide_me()
	grapple_progress = 0.0

	# disable physics
	freeze = true

	# calculate travel time
	var distance = (global_transform.origin - grappling_to).length()
	grapple_timescale = distance / GRAPPLE_SPEED


func finish_grapple() -> void:
	is_grappling = false
	controllable = true
	switch_to_third_person()

	# enable physics
	freeze = false


func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_look(event.relative, mouse_sensitivity)


func camera_look(delta: Vector2, sensitivity) -> void:
	var arm = camera_pivot.get_child(0)
	arm.rotate_x(-delta.y * 0.01 * sensitivity)
	camera_pivot.rotate_y(-delta.x * 0.01 * sensitivity)
	arm.rotation.x = clamp(arm.rotation.x, -1.2, 1.2)


func switch_to_first_person() -> void:
	camera_spring_arm.spring_length = 0.0
	$Model.visible = false
	first_person = true
	$GrappleTargetRing.show_me()


func switch_to_third_person() -> void:
	camera_spring_arm.spring_length = initial_camera_spring_length
	$Model.visible = true
	first_person = false
	$GrappleTargetRing.hide_me()


func _physics_process(_delta):
	var bodies = $FloorDetector.get_overlapping_bodies()
	floored = len(bodies) > 0
	$Model.on_floor = floored

	platform_push = Vector3.ZERO
	if floored and controllable:
		var touching_bodies = get_colliding_bodies()
		for b in bodies:
			if b not in touching_bodies:
				continue
			if b.has_method("get_delta_motion"):
				platform_push = b.get_delta_motion()
				break


func _integrate_forces(state: PhysicsDirectBodyState3D):
	if not controllable:
		return
	var forward_vec = -camera_pivot.transform.basis.z
	var left_vec = -camera_pivot.transform.basis.x

	var move_vec = Vector3.ZERO

	var actual_vel_limit = vel_limit

	var fb = Input.get_axis("backward", "forward")
	if fb != 0:
		var projected = state.linear_velocity.project(forward_vec * fb)
		var current_vel = projected.length() * sign(projected.dot(forward_vec * fb))

		var effective_force = movement_force
		if current_vel > actual_vel_limit:
			effective_force = 0
		if current_vel < 0:
			effective_force *= 2

		if not floored:
			effective_force *= 0.4
		state.linear_velocity += forward_vec * fb * effective_force
		move_vec += forward_vec * fb

	var lr = Input.get_axis("right", "left")
	if lr != 0:
		var projected = state.linear_velocity.project(left_vec * lr)
		var current_vel = projected.length() * sign(projected.dot(left_vec * lr))

		var effective_force = movement_force
		if current_vel > actual_vel_limit:
			effective_force = 0
		if current_vel < 0:
			effective_force *= 2

		if not floored:
			effective_force *= 0.4
		state.linear_velocity += left_vec * lr * effective_force
		move_vec += left_vec * lr

	state.linear_velocity += platform_push

	# need to add drag for if the player is not inputting movement
	if floored and abs(fb) < 0.1 and abs(lr) < 0.1:
		var lv := state.linear_velocity
		var relative_vel := lv - platform_push
		state.linear_velocity = relative_vel.lerp(Vector3(0, lv.y, 0), 0.1) + platform_push

	if Input.is_action_just_pressed("jump") and floored:
		state.linear_velocity.y += 8
		state.linear_velocity -= transform.basis.z.normalized() * jump_forwards
		$Model.play("Jump")

	if move_vec:
		var rotated = (
			global_transform.looking_at(global_position + move_vec).orthonormalized().basis
		)
		state.transform.basis = global_transform.basis.slerp(rotated, 0.2)
	$Model.moving = true if move_vec else false
	
func add_gem(ammount) -> void:
	gems_collected += ammount
