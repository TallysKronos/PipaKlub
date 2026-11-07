extends Sprite2D
var clips: Dictionary
var playback: Dictionary
var age:=0.0
var clip:="idle"
var reduced_motion:=false

func configure(content: Dictionary, body_height: float=150.0) -> void:
	var atlas: Dictionary=content.combat.trovareta
	texture=load("res://assets/campaign/"+atlas.image)
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	clips=atlas.animations
	playback=atlas.playback
	region_enabled=true
	var image:=texture.get_image()
	var used:=Rect2i()
	for frame: Dictionary in clips.idle:
		var bounds: Rect2i=image.get_region(Rect2i(frame.x,frame.y,frame.w,frame.h)).get_used_rect()
		used=bounds if not used.has_area() else used.merge(bounds)
	# One fixed support anchor for the whole loop. Never recenter individual frames.
	offset=Vector2(128-used.get_center().x,128-used.end.y)
	scale=Vector2.ONE*body_height/used.size.y
	show_frame()

func _process(delta: float) -> void:
	if reduced_motion:return
	age+=delta
	show_frame()

func show_frame() -> void:
	var frames: Array=clips[clip]
	var index:=int(age*float(playback[clip].fps))%frames.size()
	var frame: Dictionary=frames[index]
	region_rect=Rect2(frame.x,frame.y,frame.w,frame.h)
