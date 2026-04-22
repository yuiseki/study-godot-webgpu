extends Node3D


func _ready() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 1.6, 4.0)
	add_child(camera)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45.0, 25.0, 0.0)
	add_child(light)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.2, 1.2, 1.2)
	mesh_instance.mesh = mesh
	add_child(mesh_instance)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.82, 0.28, 0.2, 1.0)
	mesh_instance.set_surface_override_material(0, material)

	print("006_meshinstance3d_one ready")
