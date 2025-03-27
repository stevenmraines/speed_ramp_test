extends CharacterBody3D


@export_group("Speed")
@export var speed_multiplier := 100.0
@export var reverse_speed_multiplier := 30.0
@export var time_till_max_speed := 3.0
@export var acceleration_curve : Curve
@export_group("Boost")
@export var boost_speed_multiplier := 200.0
@export var boost_duration := 2.0
@export var boost_cooldown := 3.0
@export var boost_gravity_modifier := 0.33
@export_group("Strafe")
@export var strafe_speed := 0.5
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
@export_group("")
@export var grounded_gravity_modifier := 10.0
@export var no_clip_movement_speed := 100.0

@onready var mesh := $racer
@onready var engine_particles := $EngineParticles
@onready var boost_sfx_player := $BoostSFXPlayer
@onready var floor_raycaster := $FloorRaycaster
@onready var right_wall_raycaster := $RightWallRaycaster
@onready var collider := $RacerCollisionShape
@onready var camera_rig := $CameraRig

# Speed vars
var current_speed := 0.0
var starting_speed := 0.0
var max_speed := 0.0
var movement_time_elapsed := 0.0

# Boost vars
var boost_time_elapsed := 0.0
var is_boosted := false

# Turn vars
var current_tilt_degrees := 0.0
var tilt_time_elapsed := 0.0
var recenter_tilt_time_elapsed := 0.0
var last_tilt_direction := 0.0

# Brake vars
var braking_start_speed := 0.0
var braking_start_velocity := Vector3.ZERO
var braking_time_elapsed := 0.0

# Jump vars
var jump_charge_time_elapsed := 0.0
var is_jumping := false

# Other vars
var base_gravity_force = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_direction := Vector3.DOWN
var starting_position : Vector3
var engine_particles_material : StandardMaterial3D
var engine_particles_default_color : Color


func _ready() -> void:
	starting_position = global_position
	starting_speed = speed_multiplier * acceleration_curve.sample(0)
	max_speed = speed_multiplier * acceleration_curve.sample(1)
	engine_particles_material = engine_particles.draw_pass_1.material
	engine_particles_default_color = engine_particles_material.albedo_color


func _physics_process(_delta: float) -> void:
	# TODO Something like this may eventually be necessary: https://stackoverflow.com/questions/78658624/align-characterbody3d-in-godot-4-to-the-surface-of-a-cyllinder-or-other-meshes
	if floor_raycaster.is_colliding() or right_wall_raycaster.is_colliding():
		var raycaster = floor_raycaster if floor_raycaster.is_colliding() \
			else right_wall_raycaster
		var collision_point = raycaster.get_collision_point()
		var collision_normal = raycaster.get_collision_normal()
		var distance_to_collision = (collision_point - global_position).length()
		var max_distance = abs(raycaster.target_position.y) if \
			floor_raycaster.is_colliding() else abs(raycaster.target_position.x)
		var weight = min(1, distance_to_collision / max_distance)
		# Smoothly lerp from UP to collision_normal depending
		# on how far from the track your vehicle is
		up_direction = collision_normal
		gravity_direction = -up_direction
		var up = lerp(up_direction, Vector3.UP, weight)
		var back = global_basis.z
		var right = up.cross(back)
		var camera_rig_back = camera_rig.global_basis.z
		var camera_rig_right = up.cross(camera_rig_back)
		global_basis = Basis(right, up_direction, back).orthonormalized()
		camera_rig.global_basis = Basis(camera_rig_right, up_direction, camera_rig_back).orthonormalized()
	else:
		up_direction = Vector3.UP
		gravity_direction = Vector3.DOWN
		var back = global_basis.z
		var right = up_direction.cross(back)
		var camera_rig_back = camera_rig.global_basis.z
		var camera_rig_right = up_direction.cross(camera_rig_back)
		global_basis = Basis(right, up_direction, back).orthonormalized()
		camera_rig.global_basis = Basis(camera_rig_right, up_direction, camera_rig_back).orthonormalized()


func _process(delta: float) -> void:
	# Handle noclip
	if Input.is_action_just_released("No Clip"):
		collider.disabled = ! collider.disabled
	
	if collider.disabled:
		velocity = Vector3.ZERO
		var vertical_axis = Input.get_axis("Backward", "Forward")
		var horizontal_axis = Input.get_axis("Strafe Left", "Strafe Right")
		global_position.x += horizontal_axis * no_clip_movement_speed * delta
		global_position.y += vertical_axis * no_clip_movement_speed * delta
		return
	
	# Recenter position
	if Input.is_action_just_released("Center"):
		global_position = starting_position
		velocity = Vector3.ZERO
		current_speed = 0.0
		movement_time_elapsed = 0.0
		gravity_direction = Vector3.DOWN
	
	# Handle turning
	# right == negative axis because negative rotation is CW in Godot
	var turn_axis = Input.get_axis("Turn Right", "Turn Left")
	
	if turn_axis != 0:
		# FIXME This doesn't always turn the right direction when riding on pipes
		rotate_y(turn_speed * delta * turn_axis)
		
		# Handle tilt
		tilt_time_elapsed += delta
		# TODO Make from always go from current rotation? Probably need to grab the current rotation when direction is changed and go from that
		var from = 0 if last_tilt_direction == 0 else mesh.rotation.z
		var weight = min(1, tilt_time_elapsed / tilt_duration)
		current_tilt_degrees = lerpf(from, tilt_degrees * turn_axis, weight)
		last_tilt_direction = turn_axis
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
	
	# Apply tilt
	mesh.rotation.z = deg_to_rad(current_tilt_degrees)
	
	# Handle boost
	if Input.is_action_just_released("Boost"):
		is_boosted = true
		engine_particles_material.albedo_color = Color.WHITE
		boost_sfx_player.play()
	if is_boosted and boost_time_elapsed < boost_duration:
		boost_time_elapsed = min(boost_duration, boost_time_elapsed + delta)
	else:
		is_boosted = false
		boost_time_elapsed = 0
		engine_particles_material.albedo_color = engine_particles_default_color
	
	# Handle Movement
	if Input.is_action_pressed("Forward") or Input.is_action_pressed("Backward"):
		var move_direction = Input.get_axis("Backward", "Forward")
		var acceleration_sample = acceleration_curve.sample(movement_time_elapsed / time_till_max_speed)
		current_speed = speed_multiplier * acceleration_sample
		if move_direction < 0:
			current_speed = reverse_speed_multiplier * acceleration_sample
		elif is_boosted:
			current_speed = boost_speed_multiplier * acceleration_curve.sample(movement_time_elapsed / time_till_max_speed)
		movement_time_elapsed = min(time_till_max_speed, movement_time_elapsed + delta)
		var forward = -global_basis.z
		var velocity_y = velocity.y
		velocity = move_direction * forward * current_speed * delta
		velocity.y = velocity_y
	elif movement_time_elapsed > 0:
		movement_time_elapsed = 0.0
	
	# Handle strafing
	# FIXME Strafe velocity needs to be relative to basis
	#var strafe_axis = Input.get_axis("Strafe Left", "Strafe Right")
	#if strafe_axis != 0:
		#velocity.x += strafe_axis * strafe_speed * delta
		#mesh.rotate_z(strafe_axis * deg_to_rad(15))
	#else:
		# FIXME This is making it so that you can only move forward and backward, turning doesn't work
		#velocity.x = 0
		#mesh.rotate_z(0)
	
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
	
	# Set gravity force
	var gravity_force := 0.0
	var final_gravity_direction = gravity_direction
	if floor_raycaster.is_colliding() or right_wall_raycaster.is_colliding():
		# A little extra force helps keep the racer glued to the track when
		# going fast on the inside or outside of pipes, on walls, etc.
		gravity_force = base_gravity_force * grounded_gravity_modifier
	elif is_boosted:
		gravity_force = base_gravity_force * boost_gravity_modifier
	elif is_jumping:
		gravity_force = base_gravity_force
	
	# Handle jumping
	if is_jumping and is_on_floor():
		is_jumping = false
	
	if Input.is_action_pressed("Jump"):
		jump_charge_time_elapsed = min(jump_charge_duration, jump_charge_time_elapsed + delta)
	elif Input.is_action_just_released("Jump") and ! is_jumping:
		is_jumping = true
		var jump_strength_sample = jump_strength_curve.sample(jump_charge_time_elapsed / jump_charge_duration)
		gravity_force = jump_strength_sample * jump_strength_multiplier
		# Apply jump force opposite to direction of gravity
		final_gravity_direction = -gravity_direction
		jump_charge_time_elapsed = 0
	
	# Apply gravity
	velocity += final_gravity_direction * gravity_force
	
	move_and_slide()
