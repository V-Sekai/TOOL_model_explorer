extends Node

# Created and optimized by https://github.com/fire
# Huge thank!
func draw_uv_texture(mesh: Mesh) -> PackedVector2Array:
	var uvLines: PackedVector2Array
	
	for si in mesh.get_surface_count():
		var mesh_data_tool : MeshDataTool = MeshDataTool.new()
		mesh_data_tool.create_from_surface(mesh, si)
		for edge_i in mesh_data_tool.get_edge_count():
			for vertex_i in range(2):
				var vertex = mesh_data_tool.get_edge_vertex(edge_i, vertex_i)
				var uv = mesh_data_tool.get_vertex_uv(vertex)
				uvLines.push_back(uv)
		
	return uvLines

func face_count(mesh: Mesh) -> int:
	var face_count : int = 0
	for si in mesh.get_surface_count():
		var mesh_data_tool : MeshDataTool = MeshDataTool.new()
		mesh_data_tool.create_from_surface(mesh, si)
		face_count = face_count + mesh_data_tool.get_face_count()
	return face_count


const OUTLINE = "Outline"

func mesh_create_outline(mesh: MeshInstance3D):
	var outlineMesh = mesh.mesh.create_outline(mesh.mesh.get_aabb().size.length() / 300.0)
	var mat = StandardMaterial3D.new()
	mat.emission = Color.YELLOW
	mat.emission_enabled = true
	
	var instance = MeshInstance3D.new()
	instance.name = OUTLINE
	instance.mesh = outlineMesh
	instance.material_overlay = mat

	mesh.add_child(instance)
	
func mesh_remove_outline(mesh: MeshInstance3D):
	var outline = mesh.get_node(OUTLINE)
	if outline != null:
		outline.queue_free()
