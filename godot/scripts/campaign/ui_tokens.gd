extends RefCounted
## PIP-62: the only source of interface colors and font resources.
## Source contract: art/ui/hud-recorte-v1/ESPECIFICACAO.md, section 2.
const NANQUIM := Color("0b1017")
const TINTA := Color("141e29")
const TINTA_2 := Color("22303f")
const TINTA_3 := Color("33475a")
const PAPEL := Color("f4e9d2")
const PAPEL_2 := Color("d8c9ac")
const RABIOLA := Color("ff5a36")
const CEU := Color("2ec8e3")
const SOL := Color("ffc23d")
const FOLHA := Color("6fd08c")
const VEU := Color(TINTA, .72)
# Identity modulation is not white interface ink: preserve the original sprite.
const UNTINTED := Color.WHITE
const COLORS := {"nanquim": NANQUIM, "tinta": TINTA, "tinta-2": TINTA_2,
	"tinta-3": TINTA_3, "papel": PAPEL, "papel-2": PAPEL_2,
	"rabiola": RABIOLA, "ceu": CEU, "sol": SOL, "folha": FOLHA, "veu": VEU}
const ACTION_COLORS := {"attack": RABIOLA, "energy": FOLHA, "dodge": CEU,
	"puxao": SOL, "line": PAPEL, "team": SOL}
const FONT_ROOT := "res://assets/campaign/ui-modern/fonts/"
const TEXT_PATH := FONT_ROOT + "Nunito.ttf"
const LABEL_PATH := FONT_ROOT + "BarlowCondensed-Bold.ttf"
const DISPLAY_PATH := FONT_ROOT + "LilitaOne-Regular.ttf"
const LETTERING_PATH := FONT_ROOT + "Bangers-Regular.ttf"
const TITLE_SLANT_DEGREES := 8.0
static var _fonts: Dictionary = {}

static func alpha(color: Color, opacity: float) -> Color:
	return Color(color, clampf(opacity, 0, 1))

static func text(bold: bool = false) -> Font:
	var key := "text-bold" if bold else "text"
	if not _fonts.has(key):
		var face := FontVariation.new()
		face.base_font = load(TEXT_PATH)
		face.variation_opentype = {0x77676874: 800.0 if bold else 600.0}
		_fonts[key] = face
	return _fonts[key]

static func label() -> Font:
	if not _fonts.has("label"):
		var face := FontVariation.new()
		face.base_font = load(LABEL_PATH)
		face.opentype_features = {"tnum": 1}
		_fonts.label = face
	return _fonts.label

static func display() -> Font:
	if not _fonts.has("display"):
		var face := FontVariation.new()
		face.base_font = load(DISPLAY_PATH)
		# Shear glyphs 8 degrees without rotating the baseline or the Control.
		face.variation_transform = Transform2D(Vector2(1, 0), Vector2(-tan(deg_to_rad(TITLE_SLANT_DEGREES)), 1), Vector2.ZERO)
		_fonts.display = face
	return _fonts.display

static func lettering() -> Font:
	if not _fonts.has("lettering"): _fonts.lettering = load(LETTERING_PATH)
	return _fonts.lettering
