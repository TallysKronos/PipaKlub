extends SceneTree
## Render fixed corner slices at three widths, without campaign or save access.
const Mural=preload("res://scripts/ui_mural/mural_theme.gd")
const T=preload("res://scripts/campaign/ui_tokens.gd")
func _initialize() -> void:call_deferred("capture")
func capture() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1280,650)
	var surface:=Control.new()
	root.add_child(surface);surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Mural.install(surface)
	var background:=ColorRect.new();background.color=T.MURAL_GROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);surface.add_child(background)
	var index:=0
	for width in [400,760,1200]:
		var panel:=PanelContainer.new();panel.theme_type_variation="MuralTitlePanel"
		surface.add_child(panel);panel.position=Vector2(24,24+index*198);panel.size=Vector2(width,170)
		var column:=VBoxContainer.new();panel.add_child(column)
		var title:=Label.new();title.text="Mural de Kronasta";title.theme_type_variation="MuralTitle";column.add_child(title)
		var caption:=Label.new();caption.text="%d px · cantos fixos"%width;caption.theme_type_variation="MuralCaption";column.add_child(caption)
		index+=1
	for frame in 5:await process_frame
	await RenderingServer.frame_post_draw
	var output:=ProjectSettings.globalize_path("res://../documentation/hud-v2/pip-130/capturas/faixa-larguras.png")
	var error:=root.get_texture().get_image().save_png(output)
	print("MURAL TITLE CAPTURE: ",error)
	surface.free();quit(error)
