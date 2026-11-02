extends SceneTree
## PIP-62: drift guard over every runtime script, with narrow art exceptions.
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Hud = preload("res://scripts/campaign/hud.gd")
const Ink = preload("res://scripts/campaign/battle_ink.gd")
const TOKEN_FILE := "res://scripts/campaign/ui_tokens.gd"
const ART_RENDERERS := {
	"res://scripts/region.gd": "Legacy terrain/material renderer, not interface ink.",
	"res://scripts/illustrated_tree.gd": "Tree ground shadow, not interface ink.",
	"res://scripts/campaign/lacertubo_cinematic.gd": "Boss cutscene grading and letterbox, not interface ink.",
	"res://scripts/campaign/lacertubo_movie.gd": "Cutscene film backdrop.",
	"res://scripts/campaign/neighborhood_view.gd": "Neighbourhood terrain map colours.",
	"res://scripts/campaign/opening_tv.gd": "Opening TV screen grading and bezel.",
	"res://scripts/campaign/workshop_birth_view.gd": "Partner birth light effect."
}
## World renderers (terrain, water, structures, showcases): materials, not interface ink.
const ART_DIRECTORIES := {"res://scripts/overworld/": "World material renderers."}
const ART_EXPRESSIONS := {
	"res://scripts/main.gd": {
		'chests[nearest].modulate=Color(.55,.65,.55)': "Desaturates an already opened world chest sprite.",
		'chests[id].modulate=Color(.55,.65,.55)': "Restores the opened chest art when loading the prototype."
	},
	"res://scripts/campaign/workshop_view.gd": {
		'draw_rect(Rect2(Vector2.ZERO,size),Color("101d29"))': "Workbench table surface.",
		'draw_colored_polygon(_shift(points,Vector2(3,5)),Color(0.02,0.08,0.1,.35))': "Paper sheet contact shadow.",
		'draw_colored_polygon(points, Color("f5e9cb"))': "Kite paper pigment.",
		'draw_colored_polygon(PackedVector2Array([Workshop.CENTER,p,q]),Color("f5e9cb") if i%2 else Color("e6d3a6"))': "Kite paper panels.",
		'draw_line(p,q,Color("26394d"),2,true)': "Paper seam ink.",
		'draw_dashed_line(Workshop.CENTER, point, Color("91b4ad"), 2, 7,true)': "Line guide on the paper.",
		'draw_circle(point,11,Color("203b40"))': "Bamboo socket.",
		'draw_circle(point,7,Color("e8bc58") if installed else Color("9abbb3"))': "Socket state on the physical frame.",
		'draw_line(point+Vector2(-6,-4+wrap*4),point+Vector2(6,-2+wrap*4),Color("f5e9cb"),2,true)': "Wrapped line on a rod.",
		'draw_circle(Workshop.CENTER,7,Color("e8bc58"))': "Kite centre knot.",
		'draw_line(Vector2(810,510),points[model.run.step.holding],Color("f5e9cb"),2,true)': "Line held from the spool.",
		'draw_arc(Workshop.CENTER,55+r*14,0,TAU,64,Color(.3,.85,.86,.18+pulse*.15),2,true)': "Glue glow on the frame.",
		'draw_circle(Workshop.CENTER,42,Color("26394d"))': "Centre hub.",
		'draw_polygon(PackedVector2Array([from-normal,from+normal,to+normal,to-normal]),PackedColorArray([Color.WHITE]),PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]),bamboo)': "Identity modulation of the bamboo texture.",
		'draw_polygon(corners,PackedColorArray([Color.WHITE]),PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]),texture)': "Identity modulation of the paper texture."
	},
	"res://scripts/campaign/partner_care_view.gd": {
		'stage.draw_rect(Rect2(Vector2.ZERO,stage.size),Color("202d36"))': "Care stage floor behind the creature.",
		'stage.draw_set_transform(center,0,Vector2(1,.27));stage.draw_circle(Vector2.ZERO,pet_height*.27,Color(0.1,.2,.2,.22));stage.draw_set_transform(Vector2.ZERO)': "Creature ground shadow.",
		'if state=="care" and progress>0:stage.draw_arc(center+Vector2(0,10),30,-PI/2,-PI/2+TAU*progress,40,Color("f6d48c"),4,true)': "Care progress ring on the stage.",
		'stage.draw_texture_rect(images.heart,Rect2(at,Vector2(28,28)),false,Color(1,1,1,1-mark.age/1.5))': "Heart sprite fade (identity tint)."
	},
	"res://scripts/overworld/view.gd": {
		'water.color = Color("77B3AF")': "World water material, not UI ink.",
		'ramp.color = Color("DAD7C5") if model.data.biome == "morro" else Color("C7A16D")': "World ramp material.",
		'stroke.default_color = Color("87918C")': "World ramp seam.",
		'wall.color = Color("B8A58D") if face.side == "u" else Color("8F7C6E")': "Cliff material shading.",
		'wall.color = Color.WHITE': "Identity modulation of cliff artwork.",
		'rim.default_color = Color("D5C9AD")': "World terrain rim.",
		'block.color = Color("26394D") if piece.blocks else Color("E8BC58")': "Review-only collision block overlay."
	}
}
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func scripts_at(directory: String) -> Array[String]:
	var files: Array[String] = []
	for child in DirAccess.get_directories_at(directory): files.append_array(scripts_at(directory.path_join(child)))
	for file in DirAccess.get_files_at(directory):
		if file.ends_with(".gd"): files.append(directory.path_join(file))
	files.sort()
	return files

func violations(path: String, source: String) -> Array[String]:
	var result: Array[String] = []
	if path == TOKEN_FILE or ART_RENDERERS.has(path): return result
	for directory in ART_DIRECTORIES:
		if path.begins_with(directory): return result
	var regex := RegEx.new()
	regex.compile("\\bColor\\s*\\(\\s*(?:[\"']|[-+.0-9])|\\bColor\\.[A-Z_]+")
	var lines := source.split("\n")
	for index in lines.size():
		var line := lines[index]
		# Comments never authorize runtime palette literals.
		if line.strip_edges().begins_with("#"): continue
		if ART_EXPRESSIONS.get(path, {}).has(line.strip_edges()): continue
		if regex.search(line) != null: result.append("%s:%d: %s" % [path, index + 1, lines[index].strip_edges()])
		if line.contains("fonts/") and (line.contains("load(") or line.contains("preload(")):
			result.append("%s:%d: font resource outside ui_tokens.gd" % [path, index + 1])
	return result

func _initialize() -> void:
	for sample in ['Color("ff0000")', 'Color(1, 0, 0)', 'Color.WHITE']:
		check(not violations("res://scripts/new_ui.gd", sample).is_empty(), "rejects new palette literal: " + sample)
	check(violations("res://scripts/new_ui.gd", "Tokens.alpha(Tokens.CEU, .2)").is_empty(), "allows alpha derived from approved ink")
	check(not violations("res://scripts/campaign/workshop_view.gd", 'Color("ff0000")').is_empty(), "art exception does not exempt the entire workbench")
	var files := scripts_at("res://scripts")
	check(not files.is_empty(), "runtime scripts discovered")
	for path in files: check(violations(path, FileAccess.get_file_as_string(path)).is_empty(), "no palette/font drift: " + "; ".join(violations(path, FileAccess.get_file_as_string(path)) + [path]))
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/ui-recorte/manifest.json"))
	for token in Tokens.COLORS:
		if token == "veu": continue
		check(manifest.tokens[token].to_lower() == "#" + Tokens.COLORS[token].to_html(false), "manifest matches runtime: " + token)
	check(is_equal_approx(Tokens.VEU.a, .72) and Tokens.VEU.to_html(false) == Tokens.TINTA.to_html(false), "veil uses ink at 72 percent")
	check(Hud.DANGER == Tokens.RABIOLA and Hud.TRACK == Tokens.NANQUIM, "semantic aliases retain approved danger/track colors")
	check(Ink.BLACK == Tokens.NANQUIM and Ink.WHITE == Tokens.PAPEL and Ink.COLORS == Tokens.ACTION_COLORS, "battle has no independent palette")
	check(Tokens.text() == Hud.font() and Tokens.label() == Hud.font(true), "shared font instances")
	var title_face := Tokens.display() as FontVariation
	var label_face := Tokens.label() as FontVariation
	check(title_face != null and title_face.base_font.resource_path == Tokens.DISPLAY_PATH, "Lilita title variation")
	check(title_face != null and is_equal_approx(title_face.variation_transform.y.x, -tan(deg_to_rad(8))), "titles slant exactly eight degrees, baseline unchanged")
	check(label_face != null and label_face.opentype_features.get("tnum") == 1, "Barlow uses tabular numerals")
	check(Tokens.lettering().resource_path == Tokens.LETTERING_PATH, "Bangers for onomatopoeia")
	for license_file in ["nunito-OFL.txt", "barlowcondensed-OFL.txt", "lilitaone-OFL.txt", "bangers-OFL.txt"]:
		check(FileAccess.file_exists("res://licenses/" + license_file), "local font license: " + license_file)
	print("PIP-62 TOKENS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
