extends SceneTree
func _initialize():
 var frames = load("res://frames.tres") as SpriteFrames
 assert(frames != null)
 assert(frames.get_frame_count("walk-left") == 6)
 assert(is_equal_approx(frames.get_frame_duration("walk-left", 0), 0.14))
 assert(is_equal_approx(frames.get_frame_duration("walk-left", 1), 0.11))
 assert(frames.get_animation_loop("walk-left"))
 var texture = frames.get_frame_texture("walk-left", 0) as AtlasTexture
 assert(texture.region == Rect2(0, 0, 48, 64))
 print("PASS native Godot SpriteFrames load: 6 ping-pong poses, timing and atlas regions")
 quit(0)
