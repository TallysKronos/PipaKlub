extends RefCounted
## Piecewise-affine, reversible save-domain mapping. No save rewrites required.
var legacy := PackedVector2Array()
var painted := PackedVector2Array()
var triangles := PackedInt32Array()
var valid := true

func setup(anchors: Array) -> void:
	for anchor: Dictionary in anchors:
		legacy.append(Vector2(anchor.old[0],anchor.old[1]))
		painted.append(Vector2(anchor.map[0],anchor.map[1]))
	triangles=Geometry2D.triangulate_delaunay(legacy)
	for i in range(0,triangles.size(),3):
		var a := triangles[i];var b := triangles[i+1];var c := triangles[i+2]
		if (legacy[b]-legacy[a]).cross(legacy[c]-legacy[a])*(painted[b]-painted[a]).cross(painted[c]-painted[a])<=.001:valid=false
	assert(valid,"The legacy coordinate map must not fold or collapse.")

func weights(p: Vector2,a: Vector2,b: Vector2,c: Vector2) -> Vector3:
	var determinant := (b-a).cross(c-a)
	var v := (p-a).cross(c-a)/determinant
	var w := (b-a).cross(p-a)/determinant
	return Vector3(1.0-v-w,v,w)

func transform(p: Vector2,inverse: bool=false) -> Vector2:
	var input := painted if inverse else legacy
	var output := legacy if inverse else painted
	for i in range(0,triangles.size(),3):
		var a := triangles[i];var b := triangles[i+1];var c := triangles[i+2]
		var w := weights(p,input[a],input[b],input[c])
		if minf(w.x,minf(w.y,w.z))>=-.0001:return output[a]*w.x+output[b]*w.y+output[c]*w.z
	return p

func legacy_polygons(polygon: PackedVector2Array) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array]=[]
	# Split at affine boundaries so long path edges retain the exact silhouette.
	for i in range(0,triangles.size(),3):
		var triangle := PackedVector2Array([painted[triangles[i]],painted[triangles[i+1]],painted[triangles[i+2]]])
		for clipped in Geometry2D.intersect_polygons(polygon,triangle):
			var converted := PackedVector2Array()
			for p in clipped:converted.append(transform(p,true))
			result.append(converted)
	return result
