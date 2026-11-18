extends Node3D
var actor:Node3D
var player:AnimationPlayer
var camera:Camera3D
var anim_idle:StringName
var anim_proud:StringName
var anim_roar:StringName
var elapsed:float=0
var playing:bool=false
var orbit:float=0
var rings:Array[MeshInstance3D]=[]
var flare:OmniLight3D
var status:Label
var sound:AudioStreamPlayer
var fired:bool=false

func material(color:Color,emission:float=0.0)->StandardMaterial3D:
	var m=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=1
	if emission>0:
		m.emission_enabled=true;m.emission=color;m.emission_energy_multiplier=emission
	return m
func shape(mesh:Mesh,pos:Vector3,mat:Material)->MeshInstance3D:
	var o=MeshInstance3D.new();o.mesh=mesh;o.material_override=mat;o.position=pos;add_child(o);return o
func find_player(n:Node)->AnimationPlayer:
	if n is AnimationPlayer:return n
	for child in n.get_children():
		var p=find_player(child)
		if p:return p
	return null
func _ready()->void:
	var world=WorldEnvironment.new();var env=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("100d1c")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("c5b7db");env.ambient_light_energy=.6
	world.environment=env;add_child(world)
	var key=DirectionalLight3D.new();key.rotation_degrees=Vector3(-45,-32,0);key.light_energy=1.0;key.shadow_enabled=true;add_child(key)
	var rim=OmniLight3D.new();rim.position=Vector3(3,5,3);rim.light_color=Color("ff6032");rim.light_energy=.7;rim.omni_range=14;add_child(rim)
	flare=OmniLight3D.new();flare.position=Vector3(0,2,0);flare.light_color=Color("ffaf41");flare.omni_range=10;add_child(flare)
	var platform=CylinderMesh.new();platform.top_radius=5;platform.bottom_radius=5.3;platform.height=.65;platform.radial_segments=12
	shape(platform,Vector3(0,-.4,0),material(Color("302637")))
	var floor_mesh=PlaneMesh.new();floor_mesh.size=Vector2(100,100);var floor_mat=material(Color("100d1c"));floor_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;shape(floor_mesh,Vector3(0,-.76,0),floor_mat)
	for i in 12:
		var a=i*TAU/12
		var seam=BoxMesh.new();seam.size=Vector3(.035,.015,1.1)
		var o=shape(seam,Vector3(sin(a)*4.35,-.065,cos(a)*4.35),material(Color("ff642c"),2.0));o.rotation.y=a
	for i in 3:
		var tor=TorusMesh.new();tor.inner_radius=1.0;tor.outer_radius=1.045;tor.rings=48;tor.ring_segments=6
		var o=shape(tor,Vector3(0,.05,0),material(Color("ffa447"),3));o.visible=false;rings.append(o)
	actor=load("res://kirin-animado.glb").instantiate();add_child(actor)
	player=find_player(actor)
	assert(player!=null,"AnimationPlayer ausente")
	for a in player.get_animation_list():
		if "Idle" in a:anim_idle=a;player.get_animation(a).loop_mode=Animation.LOOP_LINEAR
		if "Despertar" in a:anim_roar=a
		if "Imponencia" in a:anim_proud=a
	print("KIRIN_CLIPS ",player.get_animation_list())
	assert(not anim_idle.is_empty() and not anim_roar.is_empty(),"Clipes faltantes")
	camera=Camera3D.new();camera.fov=37;add_child(camera)
	var embers=CPUParticles3D.new();embers.amount=65;embers.lifetime=5;embers.emission_shape=CPUParticles3D.EMISSION_SHAPE_SPHERE;embers.emission_sphere_radius=4
	embers.position=Vector3(0,.2,0);embers.direction=Vector3(0,1,0);embers.gravity=Vector3(0,.1,0);embers.initial_velocity_min=.3;embers.initial_velocity_max=1
	embers.scale_amount_min=.025;embers.scale_amount_max=.06
	var spark=SphereMesh.new();spark.radius=.5;spark.height=1;spark.radial_segments=4;spark.rings=2;spark.material=material(Color("ff8a35"),2);embers.mesh=spark;add_child(embers)
	build_ui();build_sound()
	player.animation_finished.connect(_on_clip_finished)
	play_idle()
	if "--poses" in OS.get_cmdline_user_args():
		assert(player.current_animation==anim_idle)
		await get_tree().create_timer(5.3).timeout
		assert(player.current_animation==anim_idle)
		play_proud()
		assert(player.current_animation==anim_proud)
		await get_tree().create_timer(6.5).timeout
		assert(player.current_animation==anim_idle)
		print("KIRIN_IDLE_LOOP_IMPONENCIA_RETORNO_OK")
		get_tree().quit()
	if "--test" in OS.get_cmdline_user_args():
		player.play(anim_roar);player.seek(2.8,true);player.advance(0)
		print("KIRIN_TEST_OK duration=",player.get_animation(anim_roar).length)
		get_tree().quit()
	if "--smoke" in OS.get_cmdline_user_args():
		play_intro()
		await get_tree().create_timer(9.0).timeout
		assert(not playing and player.current_animation==anim_idle)
		play_intro()
		assert(playing and player.current_animation==anim_roar)
		print("KIRIN_FULL_SEQUENCE_AND_REPLAY_OK")
		get_tree().quit()
	if "--capture" in OS.get_cmdline_user_args():
		for t in [0.0,1.2,2.8,4.0,6.4,8.2]:
			elapsed=t;player.play(anim_roar);player.seek(minf(t,7.99),true);player.advance(0);update_stage(0)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://capture-%.1f.png"%t))
		get_tree().quit()
func build_ui()->void:
	var layer=CanvasLayer.new();add_child(layer)
	var title=Label.new();title.text="SOULMONSTERS   /   KIRIN";title.position=Vector2(36,25);title.add_theme_font_size_override("font_size",25);layer.add_child(title)
	status=Label.new();status.position=Vector2(38,62);status.add_theme_color_override("font_color",Color("f4b878"));layer.add_child(status)
	var controls=Label.new();controls.text="P  Imponência     •     I  Repouso     •     Espaço  Despertar     •     ← →  Câmera";controls.position=Vector2(36,667);layer.add_child(controls)
	var pose_button=Button.new();pose_button.text="Imponência";pose_button.position=Vector2(880,655);pose_button.size=Vector2(150,38);pose_button.pressed.connect(play_proud);layer.add_child(pose_button)
	var replay=Button.new();replay.text="Repetir despertar";replay.position=Vector2(1050,655);replay.size=Vector2(195,38);replay.pressed.connect(play_intro);layer.add_child(replay)
func play_idle()->void:
	playing=false
	if sound:sound.stop()
	player.play(anim_idle,.3)
func play_proud()->void:
	playing=false
	sound.stop()
	player.stop()
	player.play(anim_proud,.18)
func _on_clip_finished(clip:StringName)->void:
	if clip==anim_proud:play_idle()
func build_sound()->void:
	# Original synthesized low growl; no external recording.
	var wave=AudioStreamWAV.new();wave.format=AudioStreamWAV.FORMAT_16_BITS;wave.mix_rate=22050
	var data=PackedByteArray();data.resize(22050*2*2)
	var rng=RandomNumberGenerator.new();rng.seed=74;var filtered=0.0
	for i in 44100:
		var t=float(i)/22050;var envelope=sin(PI*t/2)*exp(-t*.8)
		filtered=lerpf(filtered,rng.randf_range(-1,1),.10)
		var value=(sin(TAU*(64*t-6*t*t))*.30+sin(TAU*103*t)*.12+filtered*.8)*envelope
		data.encode_s16(i*2,int(clampf(value,-1,1)*20000))
	wave.data=data;sound=AudioStreamPlayer.new();sound.stream=wave;sound.volume_db=-10;add_child(sound)
func play_intro()->void:
	elapsed=0;playing=true;fired=false;player.play(anim_roar,.22)
func _unhandled_key_input(e:InputEvent)->void:
	if not e.is_pressed() or e.is_echo():return
	if e.physical_keycode==KEY_SPACE:play_intro()
	if e.physical_keycode==KEY_I:play_idle()
	if e.physical_keycode==KEY_P:play_proud()
func _process(dt:float)->void:
	if Input.is_key_pressed(KEY_LEFT):orbit-=dt
	if Input.is_key_pressed(KEY_RIGHT):orbit+=dt
	if playing:
		elapsed+=dt
		if elapsed>=2.3 and not fired:fired=true;sound.play()
		if elapsed>=8:playing=false;player.play(anim_idle,.35)
	update_stage(dt)
func update_stage(_dt:float)->void:
	var pulse=maxf(0,1-absf(elapsed-2.7)/1.0) if playing else 0.0
	flare.light_energy=pulse*.65
	var a=2.25+orbit+(.055*sin(elapsed*.6) if playing else 0)
	var distance=15.4-pulse*.65
	camera.position=Vector3(cos(a)*distance,7.5,sin(a)*distance)
	if pulse>0:camera.position+=Vector3(sin(elapsed*51),sin(elapsed*63),0)*.025*pulse
	camera.look_at(Vector3(0,2.8,0))
	for i in rings.size():
		var progress=(elapsed-2.25-i*.22)/1.35
		rings[i].visible=playing and progress>0 and progress<1
		if rings[i].visible:rings[i].scale=Vector3.ONE*(.5+progress*5)
	status.text=("DESPERTAR  /  " + ("Preparação" if elapsed<1.6 else ("Rugido" if elapsed<4.5 else "Recuperação"))) if playing else ("IMPONÊNCIA" if player.current_animation==anim_proud else "REPOUSO")
