extends SceneTree
## Campaign walker: standing between the Tatutrama and the soft earth after the lesson,
## the interact button pointed to the tatu and the dig could not be reached.
const View=preload("res://scripts/campaign/park_overworld_view.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const QA=preload("res://scripts/campaign/qa_jump.gd")
const Serra=preload("res://scripts/campaign/tufanocorte_story.gd")
var checks:=0
var failures:=0
func check(value: bool, message: String) -> void:
	checks+=1
	if not value: failures+=1; printerr("FAIL ",message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var player: Dictionary=QA.build("serra").player
	player.flags.tufanocorteLiberto=true
	player.flags.canCavar=true
	var view=View.new()
	view.campaign_mode=true
	var between: Vector2=(Serra.TATU+Serra.DIG)*.5
	view.saved_checkpoint=CP.make("kronasta-montanha-c",between,CP.SPACE)
	view.saved_player=player
	view.content=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	root.add_child(view)
	view.reduced_motion=true
	for i in 4: await process_frame
	view.player=between
	view._physics_process(0.016)
	var names:=PackedStringArray()
	for e in view.interaction_events: names.append(e.name)
	check("Terra fofa" in names and "Tatutrama" in names,"both the tatu and the soft earth are on the map")
	check(view.nearby.get("name","")=="Terra fofa","between the tatu and the soft earth, the button points to the earth (got %s)"%view.nearby.get("name",""))
	# Coming from the tatu: 1.45 from the earth and 0.9 from the tatu still reaches the earth.
	var approach: Vector2=Serra.DIG+(Serra.TATU-Serra.DIG).normalized()*1.45
	view.player=approach
	view._physics_process(0.016)
	check(view.nearby.get("name","")=="Terra fofa","walking over from the tatu, the earth is reached first (got %s)"%view.nearby.get("name",""))
	# The far side of the tatu, away from the earth (whichever neighbour is walkable).
	for side in [Vector2(1,0),Vector2(0,-1),Vector2(1,-1),Vector2(0,1)]:
		if view.model.point_walkable(Serra.TATU+side) and (Serra.TATU+side).distance_to(Serra.DIG)>1.8:
			view.player=Serra.TATU+side
			break
	view._physics_process(0.016)
	check(view.nearby.get("name","")=="Tatutrama","next to the tatu, the tatu can still be spoken to (got %s)"%view.nearby.get("name",""))
	print("SERRA DIG REACH: %d checks; %d failures"%[checks,failures])
	quit(1 if failures else 0)
