extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const Fixtures=preload("res://tools/player_audit_fixtures.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const State=preload("res://scripts/campaign/state.gd")
const Field=preload("res://scripts/campaign/battle_field.gd")
const Corners=preload("res://scripts/campaign/battle_corner_hud.gd")
var count:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value:bool,label:String) -> void:
	count+=1
	if not value:failures+=1;printerr("FAIL "+label)
func settle() -> void:
	for frame in 6:await process_frame
func run() -> void:
	var capture:bool="--capture" in OS.get_cmdline_user_args()
	var output:=ProjectSettings.globalize_path("res://../mockups/revisao/pip71")
	if capture:DirAccess.make_dir_recursive_absolute(output)
	var front:=Front.new()
	front.session._store=Store.new("user://lesson-hud-"+State.new_id())
	front.preferences.storage_path="user://lesson-hud-"+State.new_id()+".cfg"
	root.add_child(front)
	for viewport in [Vector2i(1280,720),Vector2i(1280,800),Vector2i(1920,1080),Vector2i(2560,1080)]:
		root.size=viewport
		for reduced in [false,true]:
			front.preferences.reduced_motion=reduced
			for index in 5:
				Fixtures.show(front,"lesson-%d"%index);await settle()
				var view:Control=front._practice_view()
				view._process(0);await settle()
				check(view._field_scale()==Field.scale_for(view.size) and view._field_offset()==Field.origin(view.size),"lesson uses shared combat projection")
				for point in [Vector2(55,70),Vector2(945,480)]:
					check(view._project(point)==Field.origin(view.size)+point*Field.scale_for(view.size),"world limits project identically to battle")
				check(not view.save_button.visible,"save stays outside active gameplay")
				check(view.next_button.disabled and view.next_button.icon!=null,"locked advance has lock symbol")
				var partner:Rect2=Corners.regions(view.size).partner
				check(not view.next_button.get_global_rect().intersects(partner),"advance never covers partner status")
				check(not view.coach.get_global_rect().grow(4).intersects(view.next_button.get_global_rect()),"coach and advance have breathing room")
				var initial_height:float=view.coach.size.y
				view.activity_age=0;view._layout_lesson();await settle()
				check(view.coach.compact and view.coach.size.y<initial_height,"coach shrinks during action")
				view.coach.pinned=true;view._layout_lesson();await settle()
				check(not view.coach.compact and view.hint.visible,"player can keep full instruction")
				view.coach.pinned=false;view.activity_age=0;view._layout_lesson();await settle()
				if capture:
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(output.path_join("licao-%d-acao-%s-%dx%d.png"%[index,"reduzido" if reduced else "normal",viewport.x,viewport.y]))
				view.model.complete=true;view._process(0);await settle()
				check(not view.next_button.disabled and not view.coach.compact,"success expands coach and unlocks primary")
				check(view.get_global_rect().encloses(view.coach.get_global_rect()),"success instruction stays on screen")
				if capture and not reduced:
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(output.path_join("licao-%d-concluida-%dx%d.png"%[index,viewport.x,viewport.y]))
				view.suspend_actions();view._layout_lesson();await settle()
				check(view.save_button.visible and view.resume_button.visible,"local pause exposes resume and secondary save")
				check(not view.command_row.visible and not view.coach.visible,"pause hides gameplay interactions")
	front.free()
	print("LESSON HUD: ",count," checks; ",failures," failures")
	quit(0 if failures==0 else 1)
