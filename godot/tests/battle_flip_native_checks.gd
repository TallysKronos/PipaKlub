extends SceneTree
class Probe extends Node2D:
	var texture:Texture2D
	func _draw()->void:
		preload("res://scripts/campaign/battle_ink.gd").live_sprite(self,texture,"native-flip-probe",{"x":0,"y":0,"w":2,"h":1},Vector2(80,60),40,Color.WHITE,Vector2.ONE,true)
func _initialize()->void:call_deferred("run")
func run()->void:
	var viewport:=SubViewport.new();viewport.size=Vector2i(160,120);viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var source:=Image.create(2,1,false,Image.FORMAT_RGBA8);source.fill(Color.RED);source.set_pixel(1,0,Color.BLUE)
	var probe:=Probe.new();probe.texture=ImageTexture.create_from_image(source);probe.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;viewport.add_child(probe)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var result:=viewport.get_texture().get_image()
	var passed:bool=result.get_pixel(65,60).b>.9 and result.get_pixel(95,60).r>.9 and result.get_pixel(45,60).a<.1 and result.get_pixel(115,60).a<.1
	result.save_png("res://../documentation/qa/veskoro-battle-v1/flip-probe.png")
	print("BATTLE FLIP NATIVE: centered rectangle and swapped pixel colors ",passed)
	viewport.queue_free();await process_frame
	quit(0 if passed else 1)
