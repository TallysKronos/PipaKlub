extends RefCounted
## Shared directional bases and authored walking frames; never grants rewards.
const Pixelgen = preload("res://scripts/pixelgen_sprites.gd")
const HEIGHTS := {"professor":90.0,"mae":88.0,"nina":83.0,"bia":78.0,"juninho":78.0,"lia":78.0,"zeca":78.0,"tiao":90.0,"iara":82.0,"nilo":82.0,"dora":76.0,"caue":82.0,"celina":82.0,"mikka":77.0}
const DIRECTIONS := ["s","sw","w","nw","n","ne","e","se"]
const Avatar = preload("res://scripts/kael_video_avatar.gd")
const RELATIVE_HEIGHTS := {"professor":1.12,"mae":1.08,"nina":1.0,"bia":1.0,"juninho":1.0,"lia":1.0,"zeca":1.0,"tiao":1.12,"iara":1.03,"nilo":1.08,"dora":.98,"caue":1.16,"celina":1.0,"mikka":1.0}
static var mother_walk:Texture2D
static var mother_walk_feet: Array[int] = []
const WALK_TIMES:=[150,120,150,120]

static func animate_walk(sprite:Sprite2D,moving:bool,seconds:float,stairs:bool=false) -> void:
	if sprite.get_meta("pixel_npc","")!="mae":return
	var facing:String=sprite.get_meta("pixel_facing","se")
	if not moving:
		if sprite.get_meta("walking",false):
			sprite.texture=Pixelgen.load_texture("res://assets/npc-ds/mae.png");face(sprite,facing)
			sprite.offset = sprite.get_meta("walk_rest_offset", Vector2(0, -46))
		sprite.set_meta("walking",false)
		return
	if mother_walk==null:
		mother_walk=Pixelgen.load_texture("res://assets/npc-ds/mae-walk.png")
		var image := mother_walk.get_image()
		for row in 8:
			for frame in 4:
				var bounds := image.get_region(Rect2i(frame * 64, row * 96, 64, 96)).get_used_rect()
				mother_walk_feet.append(bounds.end.y)
	var phase:=fmod(seconds*1000*(1.1 if stairs else 1.0),540.0)
	var frame:=0
	for duration in WALK_TIMES:
		if phase<float(duration):break
		phase-=duration;frame+=1
	var row:=maxi(0,DIRECTIONS.find(facing))
	if not sprite.get_meta("walking", false):
		sprite.set_meta("walk_rest_offset", sprite.offset)
	sprite.texture=mother_walk;sprite.region_rect=Rect2(mini(frame,3)*64,row*96,64,96)
	var rest_offset: Vector2 = sprite.get_meta("walk_rest_offset")
	sprite.offset = rest_offset + Vector2(0, 92 - mother_walk_feet[row * 4 + mini(frame, 3)])
	sprite.set_meta("walking",true);sprite.set_meta("walk_frame",mini(frame,3))

static func height_for(id: String,kael_scale: float) -> float:
	return Avatar.STANDING_HEIGHT*kael_scale*float(RELATIVE_HEIGHTS.get(id,1.0))

static func identity(display_name: String) -> String:
	return {"Prof. Assis":"professor","Professor Assis":"professor","Sr. Assis":"professor","Assis":"professor","Nina":"nina","Bia":"bia","Juninho":"juninho","Lia":"lia","Zeca":"zeca","Tião":"tiao","Iara":"iara","Nilo":"nilo","Dora":"dora","Cauê":"caue","Celina":"celina","Mikka":"mikka"}.get(display_name,"")

static func setup(sprite: Sprite2D,id: String,height_pixels: float,facing: String="se") -> void:
	assert(HEIGHTS.has(id),"Unknown NPC identity: "+id)
	sprite.texture=Pixelgen.load_texture("res://assets/npc-ds/"+id+".png")
	sprite.region_enabled=true
	sprite.centered=true
	sprite.offset=Vector2(0, -44 if id == "mae" else -46)
	sprite.scale=Vector2.ONE*height_pixels/float(HEIGHTS[id])
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.set_meta("pixel_npc",id)
	face(sprite,facing)

static func face(sprite: Sprite2D,facing: String) -> void:
	var index := DIRECTIONS.find(facing)
	if index<0:index=7
	sprite.region_rect=Rect2((index%4)*64,(index/4)*96,64,96)
	sprite.set_meta("pixel_facing",facing)
	if sprite.material is ShaderMaterial:sprite.material.set_shader_parameter("row",float(index/4))

static func face_motion(sprite: Sprite2D,direction: Vector2) -> void:
	face(sprite,Avatar.facing_for(direction,str(sprite.get_meta("pixel_facing","se"))))

static func reveal(sprite: Sprite2D,amount: float) -> void:
	if sprite.material==null:
		var shader:=Shader.new()
		shader.code="shader_type canvas_item; uniform float row=0.; uniform float rows=2.; uniform float reveal=1.; void fragment(){if(UV.y*rows-row>reveal){discard;}}"
		var material:=ShaderMaterial.new();material.shader=shader;sprite.material=material
	sprite.material.set_shader_parameter("row",float(int(sprite.region_rect.position.y)/96))
	sprite.material.set_shader_parameter("rows",float(sprite.texture.get_height())/96.0)
	sprite.material.set_shader_parameter("reveal",clampf(amount,0,1))
