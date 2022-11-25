extends Node

class_name DrawUVTex

class Edge:
	var a: Vector2
	var b: Vector2

#FIXME: Extremely slow...
func draw_uv_texture(mesh: Mesh) -> PackedVector2Array:
	var edges: Array[Edge]
	var uvLines: PackedVector2Array
	
	for si in mesh.get_surface_count():
		var a = mesh.surface_get_arrays(si)
		
		var uv:PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
		var indices = a[Mesh.ARRAY_INDEX]
		
		var ic:int
		var useIndices = false
		
		if indices.size() > 0:
			ic = indices.size()
			useIndices = true
		else:
			ic = uv.size()
		
		for i in range(0, ic, 3):
			for j in range(3):
				var edge: Edge = Edge.new()
				
				if useIndices:
					edge.a = uv[indices[i + j]]
					edge.b = uv[indices[i + ((j + 1) % 3)]]
				else:
					edge.a = uv[i + j]
					edge.b = uv[i + ((j + 1) % 3)]
				
				if edges.has(edge):
					continue
				
				uvLines.push_back(edge.a)
				uvLines.push_back(edge.b)
				
				edges.append(edge)
		
	return uvLines
