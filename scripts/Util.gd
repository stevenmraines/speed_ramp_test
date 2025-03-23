extends Node


###################################
# Debug functions
###################################
func draw_gizmo(transform : Transform3D, persist := 1, scale := 1.0) -> void:
	Draw3D.line(
		transform.origin,
		transform.origin + transform.basis.x.normalized() * scale,
		Color.RED,
		persist
	)
	Draw3D.line(
		transform.origin,
		transform.origin + transform.basis.y.normalized() * scale,
		Color.GREEN,
		persist
	)
	Draw3D.line(
		transform.origin,
		transform.origin + transform.basis.z.normalized() * scale,
		Color.BLUE,
		persist
	)


func draw_vector(vector : Vector3, persist := 1, scale := 1.0) -> void:
	var x_to = vector + Vector3(vector.x, 0, 0).normalized() * scale
	var y_to = vector + Vector3(0, vector.y, 0).normalized() * scale
	var z_to = vector + Vector3(0, 0, vector.z).normalized() * scale
	Draw3D.line(vector, x_to, Color.RED, persist)
	Draw3D.line(vector, y_to, Color.GREEN, persist)
	Draw3D.line(vector, z_to, Color.BLUE, persist)


###################################
# PhantomCamera functions
###################################
func get_p_cam_from_path(cam_path : NodePath) -> PhantomCamera3D:
	for cam in PhantomCameraManager.phantom_camera_3ds:
		if cam.name == cam_path.get_name(cam_path.get_name_count() - 1):
			return cam
	return null


func get_p_cam_from_name(cam_name : String) -> PhantomCamera3D:
	for cam in PhantomCameraManager.phantom_camera_3ds:
		if cam.name == cam_name:
			return cam
	return null


func get_prioritized_p_cam() -> PhantomCamera3D:
	var max_priority = 0
	var prioritized_p_cam = null
	for cam in PhantomCameraManager.phantom_camera_3ds:
		if cam.priority > max_priority:
			max_priority = cam.priority
			prioritized_p_cam = cam
	return prioritized_p_cam


func deprioritize_all_p_cams() -> void:
	for cam in PhantomCameraManager.phantom_camera_3ds:
		cam.set_priority(0)


func prioritize_p_cam(cam_identifier) -> PhantomCamera3D:
	Util.deprioritize_all_p_cams()
	
	# Return prioritized cam in case we need to await a PhantomCamera3D signal
	var return_cam : PhantomCamera3D
	
	if cam_identifier is String:
		return_cam = Util.get_p_cam_from_name(cam_identifier)
	elif cam_identifier is NodePath:
		return_cam = Util.get_p_cam_from_path(cam_identifier)
	elif cam_identifier is PhantomCamera3D:
		return_cam = cam_identifier
	else:
		push_error("Could not set priority on PhantomCamera3D with identifier '", cam_identifier, "'")
	
	if return_cam && return_cam is PhantomCamera3D:
		return_cam.set_priority(1)
	
	return return_cam


###################################
# Math functions
###################################
func bin2int(binary_value) -> int:
	var decimal_value = 0 
	var count = 0 
	var temp 
 
	while(binary_value != 0): 
		temp = binary_value % 10 
		binary_value /= 10 
		decimal_value += temp * pow(2, count) 
		count += 1 
 
	return decimal_value
 

func int2bin(value : int) -> String:
	var binary_string = "" 
	var temp 
	var count = 31 # Checking up to 32 bits 
 
	while(count >= 0): 
		temp = value >> count 
		if(temp & 1): 
			binary_string = binary_string + "1" 
		else: 
			binary_string = binary_string + "0" 
		count -= 1 

	return binary_string
