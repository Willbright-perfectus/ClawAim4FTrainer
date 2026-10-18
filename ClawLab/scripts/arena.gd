extends Node3D

signal finished(result: Dictionary)
const Player = preload("res://scripts/player.gd")
const Target = preload("res://scripts/target.gd")
const Math = preload("res://scripts/trainer_math.gd")
const DRILLS = ["Free Range","Tracking","Flicks","Switching","Strafe & Track","Peek & Clear","Finger Flow","Movement Course","Recoil Board","Calibration"]
const DESCRIPTIONS = {
	"Free Range":"Explore the range. Test your weapon, HUD and movement.",
	"Tracking":"Follow a moving target. Build smooth thumb control.",
	"Flicks":"Acquire small targets quickly with a controlled stop.",
	"Switching":"Move between humanoid targets and recover your aim.",
	"Strafe & Track":"Keep moving left and right while tracking your target.",
	"Peek & Clear":"Lean around cover, acquire the target and fire.",
	"Finger Flow":"Follow action prompts while keeping the target in view.",
	"Movement Course":"Reach markers through vaults, low cover and a crawl tunnel.",
	"Recoil Board":"Inspect shot placement and practise recoil compensation.",
	"Calibration":"Measure swipe turning. Match your game with a 360° check."
}

var mode = "Free Range"
var drill_name = "FREE RANGE"
var player: Node
var hud: Node
var running = true
var elapsed = 0.0
var remaining = 60.0
var shots = 0
var hits = 0
var kills = 0
var headshots = 0
var damage_total = 0.0
var jumps = 0
var vaults = 0
var prompt = ""
var prompt_time = 0.0
var prompt_action = ""
var prompt_started = 0.0
var reaction_times: Array = []
var wrong_actions = 0
var actions = 0
var tracking_time = 0.0
var moving_time = 0.0
var frame_total = 0
var slow_frames = 0
var max_frame_ms = 0.0
var targets: Array = []
var bullets: Array = []
var bullet_cursor = 0
var impacts: Array = []
var impact_cursor = 0
var t_times: Array = []
var rng = RandomNumberGenerator.new()
var checkpoints: Array = []
var checkpoint_index = 0
var marker: MeshInstance3D
var last_flinch = 0.0
var equipment: Array = []
var sound: AudioStreamPlayer
var sample: AudioStreamWAV
var trace_material: StandardMaterial3D
var sign_material: StandardMaterial3D

func _ready() -> void:
	rng.seed = int(Profiles.data.drill.seed)
	remaining = Profiles.data.drill.duration
	drill_name = mode.to_upper()
	build_room()
	player = Player.new()
	player.arena = self
	player.hud = hud
	player.position = Vector3(0,0.03,10)
	add_child(player)
	if hud != null:
		hud.player = player
		hud.arena = self
		hud.action_event.connect(player.on_action)
		hud.look_motion.connect(player.on_look)
		hud.move_motion.connect(player.set_movement)
	build_targets()
	build_pools()
	build_sound()
	if mode=="Movement Course":
		setup_course()
	elif mode=="Finger Flow":
		next_prompt()
	elif mode=="Calibration":
		prompt = "Swipe a full turn • heading 0°"
	elif mode=="Strafe & Track":
		prompt = "Keep moving while you track"
	elif mode=="Recoil Board":
		prompt = "Fire at the board • impacts remain for inspection"

func material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	if glow:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func box(pos: Vector3, dimensions: Vector3, color: Color, solid: bool = true) -> Node3D:
	var node = StaticBody3D.new() if solid else Node3D.new()
	node.position = pos
	var mesh = MeshInstance3D.new()
	var b = BoxMesh.new()
	b.size = dimensions
	mesh.mesh = b
	mesh.material_override = material(color)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(mesh)
	if solid:
		node.collision_layer = 1
		node.collision_mask = 0
		var shape = CollisionShape3D.new()
		var s = BoxShape3D.new()
		s.size = dimensions
		shape.shape = s
		node.add_child(shape)
	add_child(node)
	return node

func label3(text: String, pos: Vector3, font_size: int = 80, tint: Color = Color("8ac5c4")) -> Label3D:
	var l = Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = font_size
	l.pixel_size = 0.008
	l.modulate = tint
	l.no_depth_test = false
	add_child(l)
	return l

func build_room() -> void:
	var env = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("172733")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("b9cbd7")
	env.environment.ambient_light_energy = 0.65
	add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-25,0)
	sun.light_energy = 1.15
	sun.shadow_enabled = false
	add_child(sun)
	box(Vector3(0,-0.25,-30),Vector3(60,0.5,110),Color("33434b"))
	box(Vector3(0,4,-85),Vector3(60,8,0.7),Color("22343e"))
	box(Vector3(-30,4,-30),Vector3(0.7,8,110),Color("243741"))
	box(Vector3(30,4,-30),Vector3(0.7,8,110),Color("243741"))
	box(Vector3(0,3,25),Vector3(60,6,0.7),Color("243741"))
	for x in range(-25,30,5):
		box(Vector3(x,0.006,-30),Vector3(0.025,0.01,109),Color("4b6068"),false)
	for z in range(-80,25,5):
		box(Vector3(0,0.008,z),Vector3(59,0.012,0.025),Color("4b6068"),false)
	for x in [-29.5,29.5]:
		box(Vector3(x,0.7,-30),Vector3(0.05,0.10,108),Color("4cc6b0"),false)
	for z in [-10,-25,-50,-75]:
		box(Vector3(0,0.01,z),Vector3(10,0.02,0.06),Color("d39b64"),false)
		label3("%d M" % (10-z),Vector3(7,0.7,z),55)
	label3("CLAWLAB  /  TRAINING HALL",Vector3(0,5,-84.5),160)
	label3("PRECISION    •    CONTROL    •    CONSISTENCY",Vector3(0,3.4,-84.4),70)
	# Obstacle bay: solid obstacles and a low tunnel for meaningful stance collision.
	for data in [[Vector3(-14,0.35,2),Vector3(4,0.7,2)], [Vector3(-14,0.55,-5),Vector3(4,1.1,2)], [Vector3(-14,0.35,-12),Vector3(4,0.7,2)]]:
		box(data[0],data[1],Color("746c60"))
	box(Vector3(-14,0.9,-19),Vector3(4.5,0.3,4),Color("566772"))
	for x in [-16,-12]:
		box(Vector3(x,0.35,-19),Vector3(0.4,0.7,4),Color("566772"))
	label3("MOVEMENT BAY",Vector3(-14,2.7,-26),80)
	if mode=="Peek & Clear":
		box(Vector3(-0.8,1.1,7.4),Vector3(1.7,2.2,0.6),Color("5a6971"))
	if mode=="Recoil Board":
		box(Vector3(0,2.2,-10),Vector3(6,4.4,0.2),Color("c5cbd0"))
		for n in range(-5,6):
			box(Vector3(n*0.5,2.2,-9.88),Vector3(0.015,4.2,0.015),Color("566673"),false)
		for n in range(1,9):
			box(Vector3(0,n*0.5,-9.88),Vector3(5.8,0.015,0.015),Color("566673"),false)

func build_targets() -> void:
	if mode in ["Movement Course","Recoil Board","Calibration"]:
		return
	var count = 4 if mode in ["Free Range","Switching","Flicks"] else 1
	for i in range(count):
		var t = Target.new()
		t.arena = self
		t.index = i
		t.sphere = mode=="Flicks"
		t.position = Vector3((i-(count-1)*0.5)*3.2,0,10-Profiles.data.drill.distance)
		if mode=="Free Range":
			t.position.z -= i*6
		t.origin = t.position
		targets.append(t)
		add_child(t)

func build_pools() -> void:
	trace_material = material(Color("ffe3a1"),true)
	var tracer_mesh = SphereMesh.new()
	tracer_mesh.radius = 0.025
	tracer_mesh.height = 0.05
	tracer_mesh.radial_segments = 6
	tracer_mesh.rings = 3
	for i in range(64):
		var mesh = MeshInstance3D.new()
		mesh.mesh = tracer_mesh
		mesh.material_override = trace_material
		mesh.visible = false
		add_child(mesh)
		bullets.append({"active":false,"pos":Vector3.ZERO,"velocity":Vector3.ZERO,"origin":Vector3.ZERO,"life":0.0,"mesh":mesh})
	var impact_mesh = SphereMesh.new()
	impact_mesh.radius = 0.022
	impact_mesh.height = 0.044
	impact_mesh.radial_segments = 6
	impact_mesh.rings = 3
	var im = material(Color("fd714f"),true)
	for i in range(160):
		var mesh = MeshInstance3D.new()
		mesh.mesh = impact_mesh
		mesh.material_override = im
		mesh.visible = false
		add_child(mesh)
		impacts.append(mesh)

func build_sound() -> void:
	sound = AudioStreamPlayer.new()
	sound.max_polyphony = 8
	sound.volume_db = -22
	add_child(sound)
	sample = AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = 22050
	var bytes = PackedByteArray()
	bytes.resize(2205*2)
	var audio_rng = RandomNumberGenerator.new()
	audio_rng.seed = 8
	for i in range(2205):
		var amp = exp(-float(i)/210.0)
		var value = int(clampf((audio_rng.randf_range(-1,1)*0.65+sin(i*0.14)*0.35)*amp,-1,1)*24000)
		bytes.encode_s16(i*2,value)
	sample.data = bytes
	sound.stream = sample

func spawn_bullet(origin: Vector3, direction: Vector3, speed: float) -> void:
	var b = bullets[bullet_cursor]
	bullet_cursor = (bullet_cursor+1)%bullets.size()
	b.active = true
	b.pos = origin
	b.origin = origin
	b.velocity = direction*speed
	b.life = 3.0
	b.mesh.position = origin
	b.mesh.visible = Profiles.data.performance.tracers
	shots += 1
	if Profiles.data.controls.sound:
		sound.play()

func step_bullets(dt: float) -> void:
	var state = get_world_3d().direct_space_state
	for b in bullets:
		if not b.active:
			continue
		b.life -= dt
		var next = b.pos+b.velocity*dt+Vector3.DOWN*Profiles.data.weapon.bullet_gravity*dt*dt*0.5
		b.velocity.y -= Profiles.data.weapon.bullet_gravity*dt
		var q = PhysicsRayQueryParameters3D.create(b.pos,next,3)
		q.collide_with_areas = true
		var hit = state.intersect_ray(q)
		if not hit.is_empty():
			b.active = false
			b.mesh.visible = false
			var body = hit.collider
			if body.has_meta("target"):
				var t = body.get_meta("target")
				var zone = body.get_meta("zone")
				if is_instance_valid(t) and t.alive:
					t.take_hit(Math.damage(Profiles.data.weapon,zone,b.origin.distance_to(hit.position),Profiles.data.drill.armor),zone)
			else:
				var mark = impacts[impact_cursor]
				impact_cursor = (impact_cursor+1)%impacts.size()
				mark.position = hit.position+hit.normal*0.012
				mark.visible = true
		elif b.life<=0 or next.y < -2:
			b.active = false
			b.mesh.visible = false
		else:
			b.pos = next
			b.mesh.position = next

func register_hit(amount: float, zone: String) -> void:
	hits += 1
	damage_total += amount
	if zone=="head":
		headshots += 1
	if hud != null:
		hud.hit_flash = 0.12

func register_kill(ttk: float) -> void:
	kills += 1
	t_times.append(ttk)

func accuracy() -> float:
	return 100.0*hits/maxi(shots,1)

func aim_near_target() -> bool:
	if player == null:
		return false
	var origin = player.camera.global_position
	var forward = -player.camera.global_basis.z
	for t in targets:
		if t.alive:
			var to_target = (t.global_position+Vector3.UP*1.3-origin).normalized()
			if forward.dot(to_target)>0.998:
				return true
	return false

func _physics_process(dt: float) -> void:
	if not running:
		return
	elapsed += dt
	remaining = maxf(0,Profiles.data.drill.duration-elapsed)
	for t in targets:
		t.step(dt)
	step_bullets(dt)
	step_equipment(dt)
	if aim_near_target():
		tracking_time += dt
	if Vector2(player.velocity.x,player.velocity.z).length()>0.5:
		moving_time += dt
	if mode=="Finger Flow":
		prompt_time -= dt
		if prompt_time<=0:
			next_prompt()
	elif mode=="Calibration":
		prompt = "Heading %03d°  •  Hip %.0f°/swipe  •  ADS %.0f°/swipe" % [posmod(int(rad_to_deg(-player.rotation.y)),360), Profiles.data.aim.hip_turn,Profiles.data.aim.ads_turn]
	elif mode=="Movement Course":
		step_course()
	var fi = Profiles.data.drill.flinch_interval
	if fi > 0 and elapsed-last_flinch >= fi:
		last_flinch = elapsed
		player.recoil.y += deg_to_rad(Profiles.data.weapon.flinch*0.6)
	if remaining<=0:
		finish()

func _process(dt: float) -> void:
	if not running:
		return
	frame_total += 1
	max_frame_ms = maxf(max_frame_ms,dt*1000)
	if dt>1.5/float(Profiles.data.performance.fps):
		slow_frames += 1

func next_prompt() -> void:
	var choices = ["lean_left","lean_right","jump","crouch","prone","reload","ads","flashlight","switch","gear"]
	prompt_action = choices[rng.randi_range(0,choices.size()-1)]
	prompt = "KEEP AIMING  →  " + prompt_action.replace("_"," ").to_upper()
	prompt_started = elapsed
	prompt_time = 4.0

func record_action(action: String) -> void:
	actions += 1
	if mode=="Finger Flow":
		if action==prompt_action:
			reaction_times.append(elapsed-prompt_started)
			prompt = "GOOD  •  Reacquire the target"
			prompt_action = ""
			prompt_time = 0.7
		elif action not in ["fire","ads","move"] and not prompt_action.is_empty():
			wrong_actions += 1

func setup_course() -> void:
	checkpoints = [Vector3(-14,0,5),Vector3(-14,0,-1),Vector3(-14,0,-8),Vector3(-14,0,-15),Vector3(-14,0,-19),Vector3(-14,0,-23),Vector3(-7,0,-29),Vector3(0,0,-29)]
	marker = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.75
	cylinder.bottom_radius = 0.75
	cylinder.height = 0.03
	cylinder.radial_segments = 24
	marker.mesh = cylinder
	marker.material_override = material(Color("66f1c3"),true)
	add_child(marker)
	step_course()

func step_course() -> void:
	if checkpoint_index >= checkpoints.size():
		prompt = "COURSE COMPLETE  •  %.1f seconds" % elapsed
		finish()
		return
	var cp = checkpoints[checkpoint_index]
	marker.position = cp+Vector3.UP*0.04
	var distance = Vector2(player.position.x-cp.x,player.position.z-cp.z).length()
	prompt = "CHECKPOINT %d / %d  •  %.0f m  •  jump / vault / crawl" % [checkpoint_index+1,checkpoints.size(),distance]
	if distance<1.0 and absf(player.position.y-cp.y)<0.6:
		checkpoint_index += 1

func throw_equipment(origin: Vector3, direction: Vector3) -> void:
	# Bounded to 8 reusable practice projectiles, independent of aim scoring.
	var item: Dictionary
	if equipment.size()<8:
		var mesh = MeshInstance3D.new()
		var ball = SphereMesh.new()
		ball.radius = 0.08
		ball.height = 0.16
		mesh.mesh = ball
		mesh.material_override = material(Color("5de7bc"),true)
		add_child(mesh)
		item = {"mesh":mesh,"p":origin,"v":direction*12+Vector3.UP*3,"life":3.0}
		equipment.append(item)
	else:
		item = equipment[0]
		equipment.pop_front()
		equipment.append(item)
		item.p = origin
		item.v = direction*12+Vector3.UP*3
		item.life = 3.0
	item.mesh.visible = true
	if hud != null:
		hud.notify("Practice equipment thrown")

func step_equipment(dt: float) -> void:
	for item in equipment:
		if item.life<=0:
			continue
		item.life -= dt
		var next = item.p+item.v*dt
		item.v.y -= 9.81*dt
		var hit = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(item.p,next,1))
		if not hit.is_empty():
			item.v = item.v.bounce(hit.normal)*0.4
			item.p = hit.position+hit.normal*0.08
		else:
			item.p = next
		item.mesh.position = item.p
		item.mesh.visible = item.life>0

func set_paused(value: bool) -> void:
	running = not value
	if value:
		player.freeze()
	else:
		player.active = true

func finish() -> void:
	if not running:
		return
	running = false
	player.freeze()
	var average_reaction = 0.0
	for n in reaction_times:
		average_reaction += n
	average_reaction /= maxi(reaction_times.size(),1)
	var average_ttk = 0.0
	for n in t_times:
		average_ttk += n
	average_ttk /= maxi(t_times.size(),1)
	finished.emit({"drill":mode,"seconds":snappedf(elapsed,0.01),"shots":shots,"hits":hits,"accuracy":snappedf(accuracy(),0.1),"kills":kills,"headshots":headshots,"damage":snappedf(damage_total,0.1),"tracking_percent":snappedf(100*tracking_time/maxf(elapsed,0.01),0.1),"moving_percent":snappedf(100*moving_time/maxf(elapsed,0.01),0.1),"reaction_ms":roundf(average_reaction*1000),"prompt_success":reaction_times.size(),"wrong_actions":wrong_actions,"jumps":jumps,"vaults":vaults,"checkpoints":checkpoint_index,"missed_taps":hud.total_misses if hud else 0,"peak_touches":hud.peak_touches if hud else 0,"slow_frames":slow_frames,"frame_count":frame_total,"max_frame_ms":snappedf(max_frame_ms,0.1),"ttk":snappedf(average_ttk,0.01)})
