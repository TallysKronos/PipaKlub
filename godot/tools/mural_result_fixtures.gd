extends RefCounted
const Model=preload("res://scripts/campaign/encounter_model.gd")
static var content:Dictionary={}
static func create(mode:String,scale:float=1.0) -> Control:
	if content.is_empty():content=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	var player:Dictionary=preload("res://scripts/campaign/state.gd").fresh("slot-1").player
	player.name="Kael";player.partners=[{"id":"result","modelId":"rabbito","personalName":"Rabbito","xp":39,"condition":{"line":84,"structure":96}},{"id":"reserve","modelId":"basica","personalName":"Carcará das Correntes Douradas","xp":Model.xp_for_level(8),"condition":{"line":100,"structure":100}}];player.equippedPartnerId="result"
	var model:RefCounted=preload("res://scripts/campaign/morro_model.gd").new(player.partners[0],"morro-3") if mode=="morro" else Model.new(player.partners[0],{} if mode=="boss" else {"modelId":"mata","level":3})
	model.intro=0;model.outcome=mode if mode in ["lost","fled"] else "won"
	if model.outcome=="won":model.q.hp=0
	if model.outcome=="lost":model.p.hp=0
	var view:Control=preload("res://scripts/campaign/morro_battle_view.gd").new() if mode=="morro" else preload("res://scripts/campaign/encounter_view.gd").new()
	view.text_scale=scale;view.configure(content,model.snapshot());view.reward_player=player;view.reward_encounter={"kind":"morro" if mode=="morro" else "lacertubo" if mode=="boss" else "wild","dropRoll":0,"scene":"park-veredas"};view.reduced_motion=true;view.result_wipe_started=true
	return view
