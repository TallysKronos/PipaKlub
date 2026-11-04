extends "res://tools/park_flow_refinement_review.gd"
var PixelNPC: GDScript
func run() -> void:
    PixelNPC=load("res://scripts/npc_pixel_sprite.gd")
    root.size=Vector2i(1280,720)
    output=ProjectSettings.globalize_path("res://../documentation/campaign/park-new-cast")
    DirAccess.make_dir_recursive_absolute(output)
    front=load("res://scripts/campaign/front_end.gd").new()
    var temporary=ProjectSettings.globalize_path("res://../tmp/cast-review-"+State.new_id())
    front.session._store=load("res://scripts/campaign/save_store.gd").new(temporary)
    front.preferences.storage_path=temporary+"-settings.cfg"
    front.preferences.reduced_motion=true
    root.add_child(front)
    check(front.session.start("slot-1").status=="ok","isolated session starts")
    var cases=[["bia","iara","Iara","park-trail"],["juninho","nilo","Nilo","park-clearing"],["lia","dora","Dora","park-clearing"],["zeca","caue","Cauê","park-veredas"],["tiao","celina","Celina","park-veredas"]]
    for entry in cases:
        var map=Checkpoint.model_for(entry[3])
        await place(entry[3],Training.point(entry[0],map),650)
        var npc_sprites=find_sprites(front.park,entry[1])
        check(npc_sprites.size()==1,entry[1]+" has exactly one unique runtime sprite")
        check(PixelNPC.identity(entry[2])==entry[1],entry[1]+" display identity")
        await shot(entry[1]+"-map")
        front._park_training(entry[0])
        check(dialog()!=null and front.park.paused,entry[1]+" opens actual conversation")
        check(dialog()!=null and dialog().dialog_text.contains(Training.duel(entry[0]).intro),entry[1]+" personalized dialogue")
        await shot(entry[1]+"-dialog")
        await close_dialog()
        var legacy={"completedOperations":[Training.receipt(entry[0])]}
        check(Training.completed(legacy,entry[0]),entry[1]+" old victory receipt still recognized")
    var report={"checks":checks,"failures":failures,"isolatedSave":true,"nativeResolution":[1280,720],"characters":cases}
    var file=FileAccess.open(output.path_join("ui-report.json"),FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    print("PARK CAST UI: ",JSON.stringify(report))
    quit(1 if failures else 0)
func find_sprites(node: Node,identity: String) -> Array:
    var found=[]
    if node is Sprite2D and node.get_meta("pixel_npc","")==identity: found.append(node)
    for child in node.get_children(): found.append_array(find_sprites(child,identity))
    return found
