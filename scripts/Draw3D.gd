@tool
extends Node


func line(pos1: Vector3, pos2: Vector3, color = Color.WHITE_SMOKE, persist_ms = 0):
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()

	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(pos1)
	immediate_mesh.surface_add_vertex(pos2)
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	
	if color.a < 1:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	return await final_cleanup(mesh_instance, persist_ms)


# TODO Get this function working, tired of these super thin barely visible lines
func cylinder(pos1 : Vector3, pos2 : Vector3, radius := 1.0, color := Color.WHITE_SMOKE, persist_ms := 0):
	var mesh_instance := MeshInstance3D.new()
	var cylinder_mesh := CylinderMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = cylinder_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.position = pos1
	# FIXME This doesn't work
	mesh_instance.look_at_from_position(pos1, pos2)
	mesh_instance.rotate_z(deg_to_rad(90))
	
	cylinder_mesh.cap_bottom = true
	cylinder_mesh.cap_top = true
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.top_radius = radius
	cylinder_mesh.radial_segments = 8
	cylinder_mesh.height = (pos2 - pos1).length()
	cylinder_mesh.rings = 4
	cylinder_mesh.material = material
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	
	if color.a < 1:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	return await final_cleanup(mesh_instance, persist_ms)


func point(pos: Vector3, radius = 0.05, color = Color.WHITE_SMOKE, persist_ms = 0):
	var mesh_instance := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	var material := ORMMaterial3D.new()

	mesh_instance.mesh = sphere_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.position = pos

	sphere_mesh.radius = radius
	sphere_mesh.height = radius*2
	sphere_mesh.material = material

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	
	if color.a < 1:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	return await final_cleanup(mesh_instance, persist_ms)


func square(pos: Vector3, size: Vector3, color = Color.WHITE_SMOKE, persist_ms = 0):
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	var material := ORMMaterial3D.new()

	mesh_instance.mesh = box_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.position = pos

	box_mesh.size = Vector3(size.x, size.y, size.z)
	box_mesh.material = material

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	
	if color.a < 1:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	return await final_cleanup(mesh_instance, persist_ms)


## 1 -> Lasts ONLY for current physics frame
## >1 -> Lasts X time duration.
## <1 -> Stays indefinitely
func final_cleanup(mesh_instance: MeshInstance3D, persist_ms: float):
	get_tree().get_root().add_child(mesh_instance)
	if persist_ms == 1:
		await get_tree().physics_frame
		mesh_instance.queue_free()
	elif persist_ms > 0:
		await get_tree().create_timer(persist_ms).timeout
		mesh_instance.queue_free()
	else:
		return mesh_instance
