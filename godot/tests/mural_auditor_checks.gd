extends SceneTree
const Audit=preload("res://tools/ui_margin_audit.gd")
var checks:=0
var failures:Array=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures.append(message);printerr("FAIL ",message)
func run()->void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	var label:=Label.new();label.text="Texto curto";label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.position=Vector2(24,24);label.size=Vector2(500,1000);root.add_child(label)
	await process_frame
	var screen:=Rect2(Vector2.ZERO,Vector2(root.size))
	check(Audit._check(label,screen).is_empty(),"unused wrapped-label box is not mistaken for painted text")
	label.position.x=-100
	check("texto sai da tela" in Audit._check(label,screen),"actual out-of-screen glyphs still fail")
	label.free()
	var clip:=Control.new();clip.clip_contents=true;clip.position=Vector2(100,100);clip.size=Vector2(300,100);root.add_child(clip)
	var option:=Button.new();option.text="Item abaixo da rolagem";option.position=Vector2(24,400);option.size=Vector2(250,60);clip.add_child(option)
	await process_frame
	check(Audit._check(option,screen).is_empty(),"unpainted scroll content is not an overflow")
	option.grab_focus()
	check("texto com foco cortado pelo scroll" in Audit._check(option,screen),"focused target hidden by clip remains a failure")
	clip.free();print("MURAL AUDITOR ",checks," checks; ",failures.size()," failures");quit(0 if failures.is_empty() else 1)
