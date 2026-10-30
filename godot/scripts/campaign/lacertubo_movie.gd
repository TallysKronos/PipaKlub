extends "res://scripts/campaign/lacertubo_cinematic.gd"
## Rendered H3 footage; retain the tested introduction/save/skip contract.
const MOVIE_PATH="res://assets/campaign/cinematics/lacertubo-patio-h3-v1.ogv"
var movie:VideoStreamPlayer
var film_finished:=false
var playback_error:=false
var previous_mix:Dictionary={}
func _ready() -> void:
	super()
	movie=VideoStreamPlayer.new();movie.expand=true
	movie.stream=load(MOVIE_PATH);movie.bus="SFX";movie.volume_db=-6
	movie.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(movie);move_child(movie,0)
	movie.finished.connect(_film_finished)
	resized.connect(_layout_movie);_layout_movie()
	for bus in ["Music","Ambience"]:
		var index:=AudioServer.get_bus_index(bus)
		if index>=0:
			previous_mix[bus]=AudioServer.get_bus_volume_db(index)
			AudioServer.set_bus_volume_db(index,float(previous_mix[bus])-12)
	portrait_layer.hide();name_label.hide();subtitle.hide();caption.hide()
	movie.play()
func _layout_movie() -> void:
	if movie==null:return
	var native_size:=Vector2(864,480)
	var area:=native_size*minf(size.x/native_size.x,size.y/native_size.y)
	movie.position=(size-area)*.5;movie.size=area
func _film_finished() -> void:
	film_finished=true;movie.hide();caption.show()
	# Keep the return-to-Kael line readable even on a late decoder finish.
	elapsed=8.0
func _cue(_id:String,_event_id:String) -> void:
	# The footage carries its generated audio; avoid doubling the old stage cues.
	pass
func advance(delta:float) -> void:
	if done:return
	if movie==null:
		super.advance(delta);return
	if not film_finished:
		elapsed+=delta
		portrait_layer.hide();name_label.hide();subtitle.hide();caption.hide()
		if elapsed>1 and not movie.is_playing():
			playback_error=true;set_meta("playback_error",true);_film_finished()
		elif elapsed>16:
			playback_error=true;set_meta("playback_error",true);movie.stop();_film_finished()
		queue_redraw();return
	super.advance(delta)
	portrait_layer.hide();name_label.hide();subtitle.hide()
func _draw_frame() -> void:
	if not film_finished:
		draw_rect(Rect2(Vector2.ZERO,size),Color.BLACK)
	else:super._draw_frame()
func _restore() -> void:
	if is_instance_valid(movie):movie.stop()
	for bus in previous_mix:
		var index:=AudioServer.get_bus_index(bus)
		if index>=0:AudioServer.set_bus_volume_db(index,previous_mix[bus])
	previous_mix.clear()
	super._restore()
