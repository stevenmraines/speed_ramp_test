extends Node3D


@onready var mover := $Mover
@onready var speed_progress_bar := $CanvasLayer/Control/ProgressBar
@onready var jump_progress_bar := $CanvasLayer/JumpControl/ProgressBar


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("Quit"):
		get_tree().quit(0)


func _process(_delta: float) -> void:
	# Update speed progress bar
	# FIXME This really isn't very accurate
	var starting_speed = mover.starting_speed
	var max_speed = mover.max_speed
	var current_speed = mover.current_speed
	
	# Avoid division by zero if starting_speed == max_speed
	if max_speed > starting_speed:
		speed_progress_bar.value = 100 * \
			((current_speed - starting_speed) / (max_speed - starting_speed))
	else:
		speed_progress_bar.value = 0
	
	# Update jump charge progress bar
	var jump_charge_time_elapsed = mover.jump_charge_time_elapsed
	var jump_charge_duration = mover.jump_charge_duration
	jump_progress_bar.value = 100 * (jump_charge_time_elapsed / jump_charge_duration)
