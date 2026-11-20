extends RefCounted
const Autotile=preload("res://studio-generated/verification-1793991837046/autotile.gd")
static func is_tree(asset: String) -> bool:
	return asset.begins_with("arvore-")
static func cell(a: Dictionary,p: Vector2) -> int:
	return int(floor(p.y/32))*int(a.width)+int(floor(p.x/32))
static func mask(a: Dictionary,p: Vector2,asset: String = "arvore-kronasta") -> int:
	var cells: Dictionary={}
	var level := Autotile.support(a,p)
	for o: Dictionary in a.objects:
		if o.asset==asset:
			var q := Vector2(float(o.x),float(o.y))
			if absf(Autotile.support(a,q)-level)<0.01:
				cells[cell(a,q)]=true
	var x := int(floor(p.x/32))
	var y := int(floor(p.y/32))
	var result := 0
	for e: Array in [[0,-1,1],[1,0,2],[0,1,4],[-1,0,8],[1,-1,16],[1,1,32],[-1,1,64],[-1,-1,128]]:
		var xx := x+int(e[0])
		var yy := y+int(e[1])
		if xx>=0 and yy>=0 and xx<int(a.width) and yy<int(a.height) and cells.has(yy*int(a.width)+xx):
			result |= int(e[2])
	return Autotile.normalized(result)
static func region(a: Dictionary,p: Vector2,asset: String = "arvore-kronasta") -> Rect2:
	Autotile.init_assets()
	var i: int=Autotile.mask_indices[mask(a,p,asset)]
	var x := int(floor(p.x/32))
	var y := int(floor(p.y/32))
	var variant := 0
	return Rect2(i%8*64,(int(i/8)+variant*6)*96,64,96)
