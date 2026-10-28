extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const Fixtures=preload("res://tools/player_audit_fixtures.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const State=preload("res://scripts/campaign/state.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL "+message)
func settle() -> void:
	for frame in 8:await process_frame
func run() -> void:
	var front:=Front.new()
	front.session._store=Store.new("user://exploration-hud-"+State.new_id())
	front.preferences.storage_path="user://exploration-hud-"+State.new_id()+".cfg"
	root.add_child(front)
	front.preferences.reduced_motion=true
	var capture:bool="--capture" in OS.get_cmdline_user_args()
	var output:=ProjectSettings.globalize_path("res://../mockups/revisao/pip73")
	if capture:DirAccess.make_dir_recursive_absolute(output)
	for viewport in [Vector2i(1280,720),Vector2i(1280,800),Vector2i(1920,1080),Vector2i(2560,1080)]:
		if "--quick" in OS.get_cmdline_user_args() and viewport!=Vector2i(1280,720):continue
		root.size=viewport
		for scene in ["street","professor","trail","clearing","park","morro","morro-area-2","morro-area-3","morro-area-4","morro-area-5"]:
			Fixtures.show(front,scene)
			await settle()
			var overlays:=get_nodes_in_group("exploration_hud")
			check(overlays.size()==1,"one shared HUD: "+scene)
			if overlays.is_empty():continue
			var hud:Control=overlays[0]
			if is_instance_valid(front.park):front.park.set_physics_process(false)
			if is_instance_valid(front.room):front.room.set_physics_process(false)
			hud._process(0)
			hud._process(4.2)
			hud._layout()
			await settle()
			check(not hud.objective_panel.visible,"objective retracts: "+scene)
			check(not hud.tools.visible,"idle hides mouse buttons: "+scene)
			check(hud.occupied_fraction()<.1,"idle HUD below ten percent: %s %.3f"%[scene,hud.occupied_fraction()])
			if hud.occupied_fraction()>=.1:
				for widget in [hud.area_panel,hud.partner_panel,hud.prompt_panel,hud.map]:print(scene," ",widget.get_rect()," ",widget.visible)
			for widget in [hud.area_panel,hud.partner_panel,hud.prompt_panel,hud.map]:
				if is_instance_valid(widget) and widget.visible:check(Rect2(Vector2.ZERO,hud.size).encloses(widget.get_rect()),"safe viewport: "+scene)
			if capture:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output.path_join("%s-idle-%dx%d.png"%[scene,viewport.x,viewport.y]))
			var pointer:=InputEventMouseMotion.new()
			hud._input(pointer);hud._layout()
			check(hud.tools.visible,"pointer exposes tools")
			var key:=InputEventKey.new()
			key.pressed=true;key.physical_keycode=KEY_W
			hud._input(key);hud._layout()
			check(not hud.tools.visible,"keyboard hides mouse tools")
			var pad:=InputEventJoypadButton.new()
			pad.pressed=true;pad.button_index=JOY_BUTTON_A
			hud._input(pad);hud._layout()
			check(not hud.tools.visible,"gamepad hides mouse tools")
			hud.objective.text="Um objetivo atualizado, sem revelar os lugares da área."
			hud._process(0);hud._layout()
			check(hud.objective_panel.visible,"new objective returns")
			hud._process(4.2);hud._layout()
			hud.reveal_objective();hud._layout()
			check(hud.objective_panel.visible,"pause reveals objective")
			var updated:Dictionary=hud.player_data.duplicate(true)
			updated.coins=int(updated.get("coins",0))+25
			hud.refresh(updated);hud._layout()
			check(hud.coins.visible,"coin change reveals chip")
			for index in 4:hud.push_notice("Item obtido · %d"%index,"item")
			await settle()
			check(hud.notices.size()==3,"maximum three notices")
			check(hud.notice_stack.get_rect().end.y<hud.prompt_panel.position.y,"notices stay above interaction")
			if capture and scene=="park" and viewport==Vector2i(1280,720):
				hud.prompt.text="ABRIR · Baú"
				hud._input(pointer);hud._process(0);hud._layout()
				await create_timer(.2).timeout
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output.path_join("park-interacao-1280x720.png"))
			hud._process(3.1);await settle()
			check(hud.notices.is_empty(),"notices expire")
	front.free()
	print("EXPLORATION HUD: ",checks," checks; ",failures," failures")
	quit(0 if failures==0 else 1)
