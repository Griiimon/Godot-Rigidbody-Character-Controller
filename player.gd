extends RigidBody3D

const SPEED := 5.
const MAX_SLOPE_ANGLE := 45
const JUMP_FORCE := 7.5
const MOUSE_SENSITIVITY = 0.01
const HEIGHT := 1.9


@export var camera : Camera3D
@export var ground_detector : ShapeCast3D
@export var collision : CollisionShape3D


var _is_on_floor := true
var _jumping := false
var _last_ground_collision_count := 0
var _max_speed := SPEED



func _physics_process(delta):
	_max_speed = SPEED

	# Calculate the average surface normal of the ground below the character
	var normal_average := Vector3.ZERO
	var can_climb := true
	if ground_detector.is_colliding():
		# Build an average normal of all ground contacts
		for collision in ground_detector.get_collision_count():
			if not is_zero_approx(ground_detector.get_collision_normal(collision).y):
				normal_average += ground_detector.get_collision_normal(collision)
		normal_average /= ground_detector.get_collision_count()
		
		# Check if the slope is too steep to climb
		if normal_average.dot(Vector3.UP) <= acos(deg_to_rad(90 - MAX_SLOPE_ANGLE)):
			can_climb = false

	# Check if the character is on the floor
	_is_on_floor = normal_average.length_squared() > 0
	if _is_on_floor and ground_detector.get_collision_count() > _last_ground_collision_count and _jumping:
		_jumping = false
	_last_ground_collision_count = ground_detector.get_collision_count()

	# Handle jumping logic
	if _is_on_floor and can_climb:
		if Input.is_action_just_pressed("jump"):
			apply_central_impulse(Vector3(0, JUMP_FORCE, 0))
			_jumping = true
	elif not _jumping:
		if linear_velocity.y > 0:
			# Cancel upward velocity if not jumping
			apply_central_impulse(Vector3(0, -linear_velocity.y, 0))

	
	# Handle character movement based on input
	var direction = Input.get_vector("move_left","move_right","move_forward","move_backwards").rotated(-camera.rotation.y)
	if direction.length_squared() == 0:
		# Apply full friction if no movement input
		physics_material_override.friction = 1
	else:
		# Remove friction if there is movement input
		physics_material_override.friction = 0
	var target_velocity = direction * _max_speed
	var impulse = target_velocity - Vector2(linear_velocity.x,linear_velocity.z)
	var impulse_vec3 = Vector3(impulse.x, 0, impulse.y)

	# Handle climbing or sliding on slopes
	if can_climb:
		# Character can climb slopes
		if normal_average.length_squared() > 0:
			var plane = Plane(normal_average)
			
			# Project the movement impulse onto the slope to climb it
			impulse_vec3 = plane.project(impulse_vec3)
	else:
		# Character is sliding on a slope
		var new_normal = Vector3(normal_average.x, 0, normal_average.y).normalized()
		var dot_product = impulse_vec3.dot(new_normal)
		if dot_product > 0:
			# Calculate the projection of the impulse along the slope's direction
			var projection = new_normal * dot_product
			
			# Subtract the projection to prevent climbing and maintain sliding
			impulse_vec3 -= projection

	# Apply the calculated impulse to move the character
	apply_central_impulse(impulse_vec3)
	


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		_rotate_camera(event.relative * MOUSE_SENSITIVITY)

func _rotate_camera(rotation: Vector2):
	camera.rotation.y -= rotation.x
	camera.rotation.x = clamp(camera.rotation.x - rotation.y, -PI / 2, PI / 2)

