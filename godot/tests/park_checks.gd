extends SceneTree
const Route = preload("res://scripts/campaign/park_route_view.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	var maps: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/park/maps.json"))
	var fixtures: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/park.json"))
	for fixture in fixtures:
		var route := Route.new()
		route.data = maps[fixture.id]
		for probe in fixture.probes:
			check(route.safe(Vector2(probe.point[0], probe.point[1])) == probe.safe, "%s collision parity %s" % [fixture.id, probe.point])
		for entry in fixture.paths:
			var clear := true
			for index in range(1, entry.path.size()):
				var a := Vector2(entry.path[index - 1][0], entry.path[index - 1][1])
				var b := Vector2(entry.path[index][0], entry.path[index][1])
				var steps := maxi(1, ceili(a.distance_to(b) / 2))
				for step in range(steps + 1):
					if not route.safe(a.lerp(b, float(step) / steps)): clear = false
			check(clear, fixture.id + " reachable interaction: " + entry.name)
		check(not route.in_grass(Vector2(route.data.spawn[0], route.data.spawn[1])), fixture.id + " safe entry")
		route.free()
	print("PARK CHECKS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
