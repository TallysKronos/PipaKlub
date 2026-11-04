extends SceneTree
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures+=1;printerr("FAIL "+label)
func run() -> void:
	var source:=FileAccess.get_file_as_string("res://assets/mounts/doberman-c-v1/mount.json")
	var path:="user://mount-layout-test.json"
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(source);file.close()
	var parent:=Node2D.new();root.add_child(parent)
	var rig=load("res://scripts/mount_rig.gd").new();rig.definition_path=path;parent.add_child(rig)
	var before:Vector2=rig.seat.position
	var data:Dictionary=JSON.parse_string(source)
	data.directions.se.seat[0]+=7;data.directions.se.hip[1]+=5
	file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(data));file.close()
	rig._process(1.1)
	check(is_equal_approx(rig.seat.position.x,before.x+7*float(data.scale)),"socket reloads without restart")
	check(is_equal_approx(rig.rider.position.y,-float(data.directions.se.hip[1])*float(data.riderScale)),"hip reloads without restart")
	check(rig.rider.visible,"complete sprite remains active")
	check(not rig.has_node("ArticulatedKael"),"no cutout rig enabled")
	parent.free();DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Mount layout: 4 checks, ",failures," failures")
	quit(1 if failures else 0)
