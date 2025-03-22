extends CharacterBody3D


@export_group("Speed")
@export var speed_multiplier := 100.0
@export var secs_till_max_speed := 3.0
@export var acceleration_curve : Curve
@export_group("Turn")
@export var turn_speed := 0.5
@export var tilt_degrees := 15.0
@export var tilt_duration := 0.3
@export var recenter_tilt_duration := 0.15
@export_group("Brake")
@export var brake_duration := 1.0
@export_group("Jump")
@export var jump_charge_duration := 1.0
@export var jump_strength_multiplier := 10.0
@export var jump_strength_curve : Curve

@onready var mesh := $racer

# Speed vars
var current_speed := 0.0
var starting_speed := 0.0
var max_speed := 0.0
var secs_elapsed := 0.0

# Turn vars
var current_tilt_degrees := 0.0
var tilt_time_elapsed := 0.0
var recenter_tilt_time_elapsed := 0.0
var last_tilt_direction := 0

# Brake vars
var braking_start_speed := 0.0
var braking_start_velocity := Vector3.ZERO
var braking_time_elapsed := 0.0

# Jump vars
var jump_charge_time_elapsed := 0.0

# Other vars
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var starting_position : Vector3


func _ready() -> void:
	starting_position = global_position
	starting_speed = speed_multiplier * acceleration_curve.sample(0)
	max_speed = speed_multiplier * acceleration_curve.sample(1)


func _process(delta: float) -> void:
	# Recenter position
	if Input.is_action_just_released("Center"):
		global_position = starting_position
		velocity = Vector3.ZERO
		current_speed = 0.0
		secs_elapsed = 0.0
	
	# Handle turning
	if Input.is_action_pressed("Left") or Input.is_action_pressed("Right"):
		var turn_direction = 1 if Input.is_action_pressed("Left") else -1
		rotate_y(turn_speed * delta * turn_direction)
		
		# Handle tilt
		tilt_time_elapsed += delta
		# TODO Make from always go from current rotation? Probably need to grab the current rotation when direction is changed and go from that
		var from = 0 if last_tilt_direction == 0 else mesh.rotation.z
		var weight = min(1, tilt_time_elapsed / tilt_duration)
		current_tilt_degrees = lerpf(from, tilt_degrees * turn_direction, weight)
		last_tilt_direction = turn_direction
	elif current_tilt_degrees != 0.0:
		# Handle recenter tilt
		recenter_tilt_time_elapsed += delta
		var from = tilt_degrees * last_tilt_direction
		var weight = min(1, recenter_tilt_time_elapsed / recenter_tilt_duration)
		current_tilt_degrees = lerpf(from, 0, weight)
	else:
		# Reset tilt vars
		tilt_time_elapsed = 0
		recenter_tilt_time_elapsed = 0
		last_tilt_direction = 0
	
	mesh.rotation.z = deg_to_rad(current_tilt_degrees)
	
	# Handle Movement
	if Input.is_action_pressed("Forward") or Input.is_action_pressed("Backward"):
		current_speed = speed_multiplier * acceleration_curve.sample(secs_elapsed / secs_till_max_speed)
		secs_elapsed = min(secs_till_max_speed, secs_elapsed + delta)
		var move_direction = 1 if Input.is_action_pressed("Forward") else -1
		var forward = -global_basis.z
		var velocity_y = velocity.y
		velocity = move_direction * forward * current_speed * delta
		velocity.y = velocity_y
	elif secs_elapsed > 0:
		secs_elapsed = 0.0
	
	# Handle braking
	if Input.is_action_pressed("Brake"):
		if braking_start_speed == 0:
			braking_start_speed = current_speed
		if braking_start_velocity == Vector3.ZERO:
			braking_start_velocity = velocity
		# Updating current_speed is really just for UI purposes,
		# so it doesn't matter if it's super accurate
		current_speed = lerpf(braking_start_speed, 0, min(1, braking_time_elapsed / brake_duration))
		velocity.x = lerpf(braking_start_velocity.x, 0, min(1, braking_time_elapsed / brake_duration))
		velocity.z = lerpf(braking_start_velocity.z, 0, min(1, braking_time_elapsed / brake_duration))
		braking_time_elapsed += delta
	elif Input.is_action_just_released("Brake"):
		braking_start_speed = 0
		braking_start_velocity = Vector3.ZERO
		braking_time_elapsed = 0
	
	# Handle jumping
	if Input.is_action_pressed("Jump"):
		jump_charge_time_elapsed = min(jump_charge_duration, jump_charge_time_elapsed + delta)
	elif Input.is_action_just_released("Jump"):
		var jump_strength_sample = jump_strength_curve.sample(jump_charge_time_elapsed / jump_charge_duration)
		velocity.y += jump_strength_sample * jump_strength_multiplier
		jump_charge_time_elapsed = 0
	
	# Handle gravity
	velocity.y -= gravity
	
	move_and_slide()
