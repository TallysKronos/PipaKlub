extends RefCounted
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
## Battle-only art direction: paper cuts, fixed ink ends and live data.
const Hud = preload("res://scripts/campaign/hud.gd")
const ROOT := "res://assets/campaign/battle-ink/"
const BLACK := Tokens.NANQUIM
const WHITE := Tokens.PAPEL
const COLORS := Tokens.ACTION_COLORS
static var brushes: Array[AtlasTexture] = []
static var portraits: Dictionary = {}
static var icons: Dictionary = {}
static var sprite_bounds: Dictionary = {}
static func brush(index: int) -> Texture2D:
	if brushes.is_empty():
		var source: Texture2D = load(ROOT + "brush-clusters-v2.png")
		for i in 4:
			var cut := AtlasTexture.new()
			cut.atlas = source
			cut.region = Rect2((i % 2) * source.get_width() / 2, (i / 2) * source.get_height() / 2, source.get_width() / 2, source.get_height() / 2)
			brushes.append(cut)
	return brushes[index % 4]
static func icon(id: String) -> Texture2D:
	return Hud.icon({"line":"guarda","energy":"foco","team":"pulo-do-elo"}.get(id,id))
static func shape(rect: Rect2, cut: float = 16) -> PackedVector2Array:
	# Slivers must remain convex when a meter approaches zero.
	var corner := minf(cut,maxf(0,rect.size.x*.45))
	return PackedVector2Array([rect.position + Vector2(corner,minf(4,rect.size.y*.45)), Vector2(rect.end.x, rect.position.y), rect.end - Vector2(corner,0), Vector2(rect.position.x,rect.end.y-minf(3,rect.size.y*.45))])
# Recorte card (approved unified HUD board): ink body with the upper-right corner cut, a solid
# offset shadow, a thin nanquim contour and, instead of a full coloured border, a short accent
# tab on the top edge (céu = player, rabiola = rival). Paper plates use the same cut.
static func card_shape(rect: Rect2, cut: float = 16) -> PackedVector2Array:
	var corner := minf(cut,minf(rect.size.x,rect.size.y)*.45)
	return PackedVector2Array([rect.position, Vector2(rect.end.x-corner, rect.position.y), Vector2(rect.end.x, rect.position.y+corner), rect.end, Vector2(rect.position.x, rect.end.y)])
static func plate(canvas: CanvasItem, rect: Rect2, fill: Color, stroke: Color = BLACK, cut: float = 16) -> void:
	canvas.draw_colored_polygon(card_shape(Rect2(rect.position + Vector2(5, 6), rect.size), cut), BLACK)
	var points := card_shape(rect, cut)
	canvas.draw_colored_polygon(points, fill)
	points.append(points[0])
	canvas.draw_polyline(points, BLACK, 2, true)
	if stroke != BLACK and stroke != fill and stroke != Tokens.TINTA:
		canvas.draw_rect(Rect2(rect.position + Vector2(14, -3), Vector2(minf(110, rect.size.x * .32), 5)), stroke)
# Menu print layer (approved board): the manga effect lives in the background only, an even
# halftone ramp plus faint concentration lines; cards, bars and text stay clean on top.
static var _ramp: Texture2D
static var _lines: Texture2D
static func menu_print(canvas: CanvasItem, size: Vector2, focus: Vector2, lines: float = .10, dots: float = .10) -> void:
	if _ramp == null:
		_ramp = load("res://assets/ui/recorte-v1/ink/halftone/dots-ramp.png")
		_lines = load("res://assets/ui/recorte-v1/ink/speedlines/concentration.png")
	for x in range(0, int(size.x)+1, 256):
		for y in range(0, int(size.y)+1, 256): canvas.draw_texture_rect(_ramp, Rect2(x, y, 256, 256), false, Tokens.alpha(Tokens.PAPEL, dots))
	var extent := maxf(size.x, size.y)*1.4
	if lines > 0: canvas.draw_texture_rect(_lines, Rect2(focus-Vector2.ONE*extent/2, Vector2.ONE*extent), false, Tokens.alpha(Tokens.PAPEL, lines))
static func ellipsis(text: String, font: Font, font_size: int, width: float) -> String:
	var result := text
	while not result.is_empty() and font.get_string_size(result + ("…" if result != text else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width: result = result.left(-1)
	return result + ("…" if result != text else "")
static func portrait(texture: Texture2D, art_id: String) -> AtlasTexture:
	if portraits.is_empty(): portraits = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "portrait-regions.json"))
	var region: Array = portraits.get(art_id, [0, 0, 256, 256])
	var result := AtlasTexture.new()
	result.atlas = texture
	result.region = Rect2(region[0], region[1], region[2], region[3])
	return result
static func status(canvas: CanvasItem, rect: Rect2, title: String, subtitle: String, actor: Dictionary, face: Texture2D, rival: bool, flip_face:bool=false) -> void:
	var accent := Tokens.RABIOLA if rival else Tokens.CEU
	canvas.draw_texture_rect(brush(1 if rival else 0), Hud.fit_texture(brush(1 if rival else 0), Rect2(rect.position - Vector2(15, 10), Vector2(rect.size.x + 30, 185))), false)
	var outline := PackedVector2Array([Vector2(13, 11), Vector2(rect.size.x + 8, 0), Vector2(rect.size.x - 12, 58), Vector2(rect.size.x + 1, 48), Vector2(rect.size.x - 18, 108), Vector2(rect.size.x - 4, 99), Vector2(rect.size.x - 30, 158), Vector2(0, 149)])
	for i in outline.size(): outline[i] += rect.position
	canvas.draw_colored_polygon(outline, WHITE)
	outline.append(outline[0])
	canvas.draw_polyline(outline, BLACK, 5, true)
	var portrait_width := 120.0
	var x: float = rect.position.x + (22 if rival else portrait_width)
	var content_width := rect.size.x - portrait_width - 32
	plate(canvas, Rect2(x - 18, rect.position.y + 51, content_width + 32, 94), BLACK, WHITE)
	var name := ellipsis(title.to_upper(), Hud.font(true), 28, content_width - 4)
	canvas.draw_string(Hud.font(true), Vector2(x + 2, rect.position.y + 35), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, BLACK)
	# Level / round count has a dedicated slot; never competes with the creature name.
	canvas.draw_string(Hud.font(true), Vector2(x + 2, rect.position.y + 51), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, BLACK)
	var values := [actor.hp / actor.stats.line, actor.hull / actor.stats.line, actor.energy / actor.stats.energy]
	var names := ["Linha", "Armação", "Energia"]
	var colors := [Tokens.FOLHA, Tokens.PAPEL_2, Tokens.CEU]
	for i in 3:
		var y: float = rect.position.y + 75 + i * 25
		canvas.draw_string(Hud.font(), Vector2(x, y), names[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, WHITE)
		var track := Rect2(x + 79, y - 13, maxf(20, content_width - 126), 13)
		canvas.draw_colored_polygon(shape(track, 3), Tokens.TINTA_2)
		var fraction := clampf(values[i], 0, 1)
		if track.size.x*fraction > .5: canvas.draw_colored_polygon(shape(Rect2(track.position, Vector2(track.size.x * fraction, track.size.y)),3),colors[i])
		canvas.draw_string(Hud.font(true), Vector2(track.end.x + 7, y), "%d%%" % roundi(fraction * 100), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, WHITE)
	var face_bounds := Rect2(rect.position + Vector2(rect.size.x - 112 if rival else -11, -5), Vector2(125, 167))
	canvas.draw_texture_rect(brush(2), Hud.fit_texture(brush(2), face_bounds.grow(8)), false, accent)
	var face_rect:=Hud.fit_texture(face, face_bounds)
	if flip_face:
		face_rect.size.x=-face_rect.size.x
	canvas.draw_texture_rect(face, face_rect, false)
	# Angular paper tears, kept at their own size rather than stretched with the plate.
	for i in 3:
		var point := rect.position + Vector2(12 + i * 13, rect.size.y - 6)
		canvas.draw_line(point, point + Vector2(15, -9), BLACK, 3, true)

static func strip(paper: bool = false) -> StyleBoxFlat:
	return Hud.make_theme().get_stylebox("panel", "RecortePaperPanel" if paper else "RecorteBattlePanel")
static func facing_flip(id:String, x:float, target_x:float) -> bool:
	# These sheets are authored facing right. Keep HUD portraits stable; arena faces its target.
	return id in ["rabbito","nozinho","lacertubo"] and x>target_x

static func live_sprite(canvas: CanvasItem, texture: Texture2D, id: String, frame: Dictionary, center: Vector2, extent: float, tint: Color = Tokens.UNTINTED, projection: Vector2 = Vector2.ONE, flip_horizontal:bool=false) -> void:
	if sprite_bounds.is_empty(): sprite_bounds = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "sprite-bounds.json"))
	var bounds: Array = sprite_bounds[id]
	var width: float = bounds[2]
	var height: float = bounds[3]
	var factor := extent / maxf(width, height)
	var extent_on_canvas := Vector2(width * projection.y / projection.x, height) * factor
	var target := Rect2(center - extent_on_canvas / 2, extent_on_canvas)
	if flip_horizontal:
		target.size.x=-target.size.x
	canvas.draw_texture_rect_region(texture, target, Rect2(frame.x + bounds[0], frame.y + bounds[1], width, height), tint)
