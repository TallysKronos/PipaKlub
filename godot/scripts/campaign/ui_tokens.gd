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
## Secondary palettes of screens drawn after PIP-62 (same values, now named here).
## Pause lobby ("LOBBY DO PIPEIRO"): navy tiles and their accents.
const LOBBY_SHADOW := Color("071322")
const LOBBY_TILE := Color("102139")
const LOBBY_TILE_ACTIVE := Color("102944")
const LOBBY_INSET := Color("142d48")
const LOBBY_INSET_EDGE := Color("416686")
const LOBBY_DOTS := Color("355371")
const LOBBY_DISABLED := Color("536980")
const LOBBY_DISABLED_ART := Color("8892a4")
const LOBBY_STRIP := Color("092136")
const LOBBY_STRIP_LINE := Color("358ba2")
const LOBBY_BACKDROP := Color(.015, .04, .085, .94)
const LOBBY_GRID := Color(.1, .35, .55, .13)
const LOBBY_ACCENTS := [Color("efa44e"), Color("8cd7f0"), Color("c285ed"), Color("69bce3"), Color("bd8bf0"), Color("b687ee"), Color("81bfcf")]
## Region map and guides.
const MAP_MUTED := Color("697478")
const MAP_MUTED_TEXT := Color("b3b4ae")
const GUIDE_CYAN := Color("43c5df")
const GUIDE_CYAN_LINE := Color("4acbe5")
const GUIDE_FIELD := Color("111f2e")
const GUIDE_TARGET := Color(.15, .7, .85, .2)
const GUIDE_TRACE := Color("eadbb8")
## Story accents: Bando cord, result highlight, night room, possessed notice, mute.
const CORD := Color("653b84")
const HIGHLIGHT := Color("ffd78e")
const NIGHT_ROOM := Color("9aabc7")
const POSSESSED := Color("b978dd")
const MIST := Color(.76, .65, .79, .55)
const MUTED_ICON := Color(.45, .45, .45)
## Torre do Vento: one ribbon per Wind (Tufanocorte, Rabiolava, Trovareta, Mormaço) and dawn.
const WIND_RIBBONS := [Color("bce9e3"), Color("f4c27d"), Color("d2c6f1"), Color("d5e6a8")]
const DAWN := Color("eadbb0")
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
## Act 4-6 story scenes (Codex refino): speaker ring and name tag of the champions'
## meeting, light motes of the restored city, Navalha's black strand, the cherry
## blossom of Tyler's epilogue and the core of a released Wind.
const MEETING_RING := Color("86d7de")
const MEETING_NAME := Color("fff2d1")
const MEETING_NAME_OUTLINE := Color("172b37")
const MEETING_LISTENER := Color(.72, .72, .72, 1)
const CITY_MOTE := Color("fff0b0")
const CAROL_STRAND := Color("24202b")
const CHERRY_BLOSSOM := Color("edb1cf")
const WIND_CORE := Color("fff3c4")
