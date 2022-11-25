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
