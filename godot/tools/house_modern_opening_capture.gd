extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
var campaign:Control
const OUT="res://../documentation/overworld/casa-kael-moderna/abertura/"
func _initialize() -> void:call_deferred("run")
func hold(seconds:float) -> void:
 var elapsed:=0.0
 while elapsed<seconds:await process_frame;elapsed+=minf(root.get_process_delta_time(),.05)
func shot(name:String) -> void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OUT+name+".png")
func show_step(step:int) -> void:
 campaign.session._snapshot.checkpoint={"kind":"opening","step":step};campaign._show_opening();await process_frame
func run() -> void:
 root.size=Vector2i(1280,720);DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
 campaign=Front.new();campaign.session._store=Store.new("user://house-preview-"+State.new_id());root.add_child(campaign)
 campaign.session._snapshot=State.fresh("slot-3")
 if "--only-home" in OS.get_cmdline_user_args():
  await show_step(12);await hold(3.5);await shot("09-sala")
  campaign.session.close_session();campaign.free();print("HOUSE OPENING: downstairs refreshed; isolated progress");quit();return
 await show_step(2);await hold(.4);await shot("01-apos-tv")
 await show_step(4);await hold(1.8);await shot("02-bancada")
 await show_step(5);await hold(.45);await shot("03-mae-na-escada");await hold(3.5);await shot("04-conversa")
 await show_step(7);await hold(.8);await shot("05-presente")
 await show_step(8);await hold(1.3)
 await show_step(9);await hold(1.4);await shot("06-rabbito")
 await show_step(10);await hold(.5);await shot("07-nome")
 await show_step(11);await hold(3.5);await shot("08-saida")
 await show_step(12);await hold(3.5);await shot("09-sala")
 campaign.session.close_session();campaign.free();print("HOUSE OPENING: 9 staged frames; isolated in-memory progress, no reward commits");quit()


