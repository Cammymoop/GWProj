extends RigidBody3D

var dust_threshold := 0.4


func _process(delta):
	# No dust in the air
	if abs(linear_velocity.y) > 0.01:
		return

	if linear_velocity.length() > dust_threshold:
		$Dust.emitting = true
	else:
		$Dust.emitting = false
