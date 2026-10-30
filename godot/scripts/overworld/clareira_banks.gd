extends RefCounted
## Refinish existing measured polygons; never change their footprint or ordering.
static func _bank_surface(wall: Polygon2D, a: float, b: float, da: float, db: float, shade: float, wet: bool = false) -> void:
	wall.texture=load("res://assets/overworld/kits/parque/manga-terrain/barranco.png")
	wall.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	wall.color=Color.WHITE
	# Polygon2D takes UVs in texture pixels; the shader receives normalized UVs.
	var texels: Vector2=wall.texture.get_size()
	wall.uv=PackedVector2Array([Vector2(a/384.0,0)*texels,Vector2(b/384.0,0)*texels,Vector2(b/384.0,db)*texels,Vector2(a/384.0,da)*texels])
	var finish:=ShaderMaterial.new()
	finish.shader=load("res://scripts/overworld/clareira_bank.gdshader")
	finish.set_shader_parameter("face_shade",shade)
	finish.set_shader_parameter("wet",wet)
	wall.material=finish
	wall.set_meta("clareira_bank",true)

static func apply(view) -> void:
	var faces_by_endpoint: Dictionary={}
	for face: Dictionary in view.model.data.cliffs:
		var b:=Vector2(face.u+1,face.v+1)
		if face.side=="u-" or face.side=="v-": b=Vector2(face.u,face.v)
		var endpoint: Vector2=view.model.project(b,false)
		if not faces_by_endpoint.has(endpoint): faces_by_endpoint[endpoint]=[]
		faces_by_endpoint[endpoint].append(face)
	for node in view.actors.get_children():
		# Keep the measured shore's existing lip, recessed water and draw order.
		if node.z_index in [-3,-2]:
			for child in node.get_children():
				if not child is Polygon2D or child.texture==null or child.polygon.size()!=4: continue
				var p: PackedVector2Array=child.polygon
				if absf(p[2].x-p[1].x)>0.01 or absf(p[3].x-p[0].x)>0.01 or p[2].y<=p[1].y: continue
				# World y encodes u+v at the bank's zero-height upper edge.
				var a: float=(p[0].y+node.position.y)*2.0
				var b: float=(p[1].y+node.position.y)*2.0
				_bank_surface(child,a,b,1.0,1.0,0.94 if p[1].x>p[0].x else 0.82,true)
			continue
		for face: Dictionary in faces_by_endpoint.get(node.position,[]):
			var a:=Vector2(face.u+1,face.v) if face.side=="u" else Vector2(face.u,face.v+1)
			var b:=Vector2(face.u+1,face.v+1)
			if face.side=="u-": a=Vector2(face.u,face.v+1); b=Vector2(face.u,face.v)
			if face.side=="v-": a=Vector2(face.u+1,face.v); b=Vector2(face.u,face.v)
			if node.position.distance_squared_to(view.model.project(b,false))>0.01: continue
			for child in node.get_children():
				if not child is Polygon2D or child.polygon.size()!=4: continue
				var p: PackedVector2Array=child.polygon
				if absf(p[0].x-(view.model.project(a,false).x-node.position.x))>0.01: continue
				var da: float=absf(p[3].y-p[0].y)/64.0
				var db: float=absf(p[2].y-p[1].y)/64.0
				_bank_surface(child,(a.x+a.y)*32.0,(b.x+b.y)*32.0,da,db,1.0 if str(face.side).begins_with("u") else 0.85)
