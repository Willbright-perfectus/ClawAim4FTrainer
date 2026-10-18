extends Node3D

var arena: Node
var health = 100.0
var alive = true
var respawn_left = 0.0
var origin = Vector3.ZERO
var index = 0
var age = 0.0
var direction = 1.0
var change_timer = 0.0
var shapes: Array = []
var sphere = false
var first_hit_time = -1.0

func _ready() -> void:
	health = Profiles.data.drill.health
	scale = Vector3.ONE * Profiles.data.drill.size
	var orange = StandardMaterial3D.new()
	orange.albedo_color = Color("ed9b60")
	orange.roughness = 0.8
	var dark = StandardMaterial3D.new()
	dark.albedo_color = Color("34444c")
	dark.roughness = 0.8
	var mint = StandardMaterial3D.new()
	mint.albedo_color = Color("5ae6c4")
	mint.emission_enabled = true
	mint.emission = Color("174c43")
	if sphere:
		part("chest",Vector3(0,1.6,0),Vector3(0.46,0.46,0.46),mint,true)
	else:
		part("head",Vector3(0,1.65,0),Vector3(0.28,0.28,0.28),orange,true)
		part("chest",Vector3(0,1.27,0),Vector3(0.48,0.44,0.25),orange,false)
		part("abdomen",Vector3(0,0.92,0),Vector3(0.40,0.25,0.23),dark,false)
		for side in [-1,1]:
			part("limb",Vector3(side*0.14,0.4,0),Vector3(0.18,0.75,0.20),dark,false)
			part("limb",Vector3(side*0.36,1.15,0),Vector3(0.17,0.55,0.18),orange,false)
	var base = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.4
	cylinder.bottom_radius = 0.4
	cylinder.height = 0.05
	cylinder.radial_segments = 16
	base.mesh = cylinder
	base.material_override = dark
	base.position.y = 0.025
	add_child(base)

func part(zone: String, offset: Vector3, dimensions: Vector3, mat: Material, ball: bool) -> void:
	var body = Area3D.new()
	body.position = offset
	body.collision_layer = 2
	body.collision_mask = 0
	body.monitoring = false
	body.set_meta("target",self)
	body.set_meta("zone",zone)
	var mesh = MeshInstance3D.new()
	var shape = CollisionShape3D.new()
	if ball:
		var s = SphereMesh.new()
		s.radius = dimensions.x/2
		s.height = dimensions.y
		s.radial_segments = 16
		s.rings = 8
		mesh.mesh = s
		var sh = SphereShape3D.new()
		sh.radius = dimensions.x/2
		shape.shape = sh
	else:
		var b = BoxMesh.new()
		b.size = dimensions
		mesh.mesh = b
		var sh = BoxShape3D.new()
		sh.size = dimensions
		shape.shape = sh
	mesh.material_override = mat
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(mesh)
	body.add_child(shape)
	shapes.append(shape)
	add_child(body)

func take_hit(amount: float, zone: String) -> void:
	if not alive:
		return
	if first_hit_time < 0:
		first_hit_time = arena.elapsed
	health -= amount
	arena.register_hit(amount,zone)
	if health <= 0 or sphere:
		alive = false
		visible = false
		respawn_left = 0.35
		for s in shapes:
			s.set_deferred("disabled",true)
		arena.register_kill(arena.elapsed-first_hit_time)

func step(dt: float) -> void:
	age += dt
	if not alive:
		respawn_left -= dt
		if respawn_left <= 0:
			respawn()
		return
	var moving = arena.mode in ["Tracking", "Strafe & Track", "Peek & Clear"]
	if moving:
		var pattern = Profiles.data.drill.target_pattern
		var speed = Profiles.data.drill.speed
		if pattern == "Sine":
			position.x = origin.x + sin(age*speed*0.35+index)*3.2
		else:
			change_timer -= dt
			if change_timer <= 0:
				direction = -direction
				change_timer = arena.rng.randf_range(0.4,1.8) if pattern=="Unpredictable" else 1.7
			position.x = clampf(position.x+direction*speed*dt,origin.x-3.5,origin.x+3.5)
		if arena.mode=="Peek & Clear":
			position.x = origin.x+sin(age*0.9)*3.0

func respawn() -> void:
	alive = true
	visible = true
	health = Profiles.data.drill.health
	first_hit_time = -1
	if sphere or arena.mode=="Switching":
		position = origin + Vector3(arena.rng.randf_range(-4,4),arena.rng.randf_range(0,2.5) if sphere else 0,arena.rng.randf_range(-2,2))
	else:
		position = origin
	for s in shapes:
		s.set_deferred("disabled",false)
