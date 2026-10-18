extends CharacterBody3D

const Math = preload("res://scripts/trainer_math.gd")
const Schema = preload("res://scripts/config_schema.gd")
var arena: Node
var hud: Node
var camera: Camera3D
var pivot: Node3D
var collider: CollisionShape3D
var flashlight: SpotLight3D
var viewgun: Node3D
var optic: Node3D
var weapon_slot = "M14"
var pending_weapon = ""
var rifle_ammo = 30
var active = true
var movement = Vector2.ZERO
var keyboard = Vector2.ZERO
var pressed: Dictionary = {}
var press_times: Dictionary = {}
var stance = "stand"
var ads = 0.0
var ads_toggle = false
var ads_suppressed = false
var lean_toggle = 0
var last_lean = 0
var lean = 0.0
var stamina = 1.0
var breath = 1.0
var breathing = false
var ammo = 30
var reload_left = 0.0
var reload_total = 0.0
var switch_left = 0.0
var sprint_delay = 0.0
var sprinting = false
var sprint_toggle = false
var silent = false
var pitch = 0.0
var recoil = Vector2.ZERO
var spread_extra = 0.0
var shot_clock = 0.0
var since_shot = 100.0
var shot_number = 0
var shot_queue = 0
var eye_height = 1.62
var jump_timer = 0.0
var jump_fatigue = 0.0
var landing_kick = 0.0
var elapsed = 0.0
var mantle_timer = 0.0
var mantle_start = Vector3.ZERO
var mantle_end = Vector3.ZERO
var dive_timer = 0.0
var gear_timer = 0.0
var gear_ready = false
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	collision_layer = 4
	collision_mask = 9 # World + player-only range barrier. Bullets use layers 1/2.
	floor_snap_length = 0.16
	floor_stop_on_slope = true
	collider = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.24
	shape.height = 1.75
	collider.shape = shape
	collider.position.y = 0.875
	add_child(collider)
	pivot = Node3D.new()
	add_child(pivot)
	camera = Camera3D.new()
	camera.near = 0.04
	camera.far = 180
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	pivot.add_child(camera)
	camera.current = true
	flashlight = SpotLight3D.new()
	flashlight.spot_range = 30
	flashlight.spot_angle = 25
	flashlight.light_energy = 2.0
	flashlight.shadow_enabled = false
	flashlight.visible = false
	camera.add_child(flashlight)
	weapon_slot = Profiles.data.selected_weapon
	rifle_ammo = int(Profiles.data.weapon.magazine)
	ammo = rifle_ammo if weapon_slot == "M14" else 1
	build_viewgun()
	rng.seed = int(Profiles.data.drill.seed)
	update_camera(0.016)

func build_viewgun() -> void:
	if is_instance_valid(viewgun):
		camera.remove_child(viewgun)
		viewgun.queue_free()
	viewgun = Node3D.new()
	camera.add_child(viewgun)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("243641")
	mat.roughness = 0.75
	var parts = [[Vector3(0,0,0),Vector3(0.075,0.08,0.30)], [Vector3(0,0.025,-0.25),Vector3(0.025,0.025,0.25)], [Vector3(0,-0.08,0),Vector3(0.05,0.13,0.08)], [Vector3(0,0.075,-0.04),Vector3(0.035,0.035,0.06)]]
	if weapon_slot == "Pistol":
		parts = [[Vector3(0,0,0),Vector3(0.065,0.07,0.18)], [Vector3(0,-0.07,0.05),Vector3(0.055,0.14,0.065)], [Vector3(0,0.05,-0.06),Vector3(0.02,0.02,0.02)]]
	for part in parts:
		var mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = part[1]
		mesh.mesh = box
		mesh.material_override = mat
		mesh.position = part[0]
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		viewgun.add_child(mesh)
	optic = Node3D.new()
	viewgun.add_child(optic)
	for ends in [false, true]:
		var tube = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		cylinder.top_radius = 0.045 if not ends else 0.037
		cylinder.bottom_radius = cylinder.top_radius
		cylinder.height = 0.15 if not ends else 0.003
		cylinder.radial_segments = 24
		tube.mesh = cylinder
		tube.rotation.x = PI / 2
		tube.position = Vector3(0,0.095,-0.08 if not ends else -0.003)
		var surface = StandardMaterial3D.new()
		surface.albedo_color = Color("21343e") if not ends else Color("60b6b1")
		surface.metallic = 0.3
		tube.material_override = surface
		optic.add_child(tube)

func weapon() -> Dictionary:
	return Profiles.data.pistol if weapon_slot == "Pistol" else Profiles.data.weapon

func unlimited_ammo() -> bool:
	return weapon_slot == "Pistol" or Profiles.data.drill.infinite_ammo

func fire_mode() -> String:
	return "Single" if weapon_slot == "Pistol" else str(weapon().mode)

func magnification() -> int:
	return 1 if weapon_slot == "Pistol" else int(str(Profiles.data.aim.scope).trim_suffix("×"))

func firing_sensitivity() -> bool:
	return bool(pressed.get("fire",false)) or shot_queue > 0 or since_shot < 0.12

func switch_weapon() -> void:
	if switch_left > 0: return
	pending_weapon = "M14" if weapon_slot == "Pistol" else "Pistol"
	var next = Profiles.data.weapon if pending_weapon == "M14" else Profiles.data.pistol
	switch_left = weapon().holster + next.switch_time
	reload_left = 0
	shot_queue = 0
	gear_ready = false
	if switch_left <= 0: complete_switch()

func complete_switch() -> void:
	if pending_weapon.is_empty(): return
	if weapon_slot == "M14": rifle_ammo = ammo
	weapon_slot = pending_weapon
	pending_weapon = ""
	ammo = rifle_ammo if weapon_slot == "M14" else 1
	shot_queue = 0
	shot_clock = 0
	recoil = Vector2.ZERO
	spread_extra = 0
	build_viewgun()
	if hud != null: hud.notify(weapon().name + (" • single tap / unlimited ammo" if weapon_slot == "Pistol" else " • " + Profiles.data.aim.scope))

func freeze() -> void:
	active = false
	pressed.clear()
	press_times.clear()
	movement = Vector2.ZERO
	keyboard = Vector2.ZERO
	ads_toggle = false
	lean_toggle = 0
	sprint_toggle = false
	shot_queue = 0
	velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func on_look(delta: Vector2, speed: float) -> void:
	if not active:
		return
	var a = Profiles.data.aim
	var gain = Math.turn_gain(a, ads, ads_requested(), firing_sensitivity(), magnification())
	if a.acceleration:
		gain *= 1.0 + a.accel_strength * clampf(speed, 0, 4)
	if a.assist and arena != null and arena.aim_near_target():
		gain *= 1.0 - a.assist_strength
	rotation.y -= deg_to_rad(delta.x * gain)
	pitch = clampf(pitch - deg_to_rad(delta.y * gain * a.vertical), deg_to_rad(-85),deg_to_rad(85))

func set_movement(v: Vector2) -> void:
	movement = v

func on_action(action: String, down: bool) -> void:
	if not active:
		return
	var cfg = Profiles.data.controls
	var was = bool(pressed.get(action,false))
	if down == was:
		return
	pressed[action] = down
	if arena != null and down:
		arena.record_action(action)
	if down:
		press_times[action] = elapsed
	else:
		var held_time = elapsed - float(press_times.get(action,elapsed))
		if action == "ads" and cfg.ads_mode == "Hybrid" and held_time < cfg.hybrid_ms / 1000.0:
			ads_toggle = not ads_toggle
		elif action.begins_with("lean_") and cfg.lean_mode == "Hybrid" and held_time < cfg.hybrid_ms / 1000.0:
			var dir = -1 if action == "lean_left" else 1
			lean_toggle = 0 if lean_toggle == dir else dir
		if action == "fire" and cfg.release_fire and fire_mode() != "Auto" and switch_left <= 0:
			shot_queue = int(weapon().burst_count) if fire_mode() == "Burst" else 1
		if action == "ads":
			ads_suppressed = false
		return
	match action:
		"ads":
			ads_suppressed = false
			if cfg.ads_mode == "Press":
				ads_toggle = not ads_toggle
		"lean_left", "lean_right":
			last_lean = -1 if action == "lean_left" else 1
			ads_suppressed = false
			if cfg.lean_mode == "Press":
				lean_toggle = 0 if lean_toggle == last_lean else last_lean
		"fire":
			if switch_left > 0: return
			ads_suppressed = false
			if gear_ready:
				use_gear()
				return
			if reload_left > 0 and cfg.reload_cancel in ["Fire","Hybrid"]:
				reload_left = 0
			if not cfg.release_fire:
				shot_queue = int(weapon().burst_count) if fire_mode() == "Burst" else 1
		"reload":
			if reload_left > 0 and cfg.reload_cancel in ["Reload","Hybrid"]:
				reload_left = 0
			else:
				start_reload()
		"jump":
			if not try_mantle():
				jump()
		"mantle":
			if not try_mantle() and hud != null:
				hud.notify("Face a low obstacle to vault")
		"crouch":
			set_stance("stand" if stance == "crouch" else "crouch")
		"prone":
			if sprinting and cfg.mode == "Warfare" and Profiles.data.movement.dive and is_on_floor():
				set_stance("prone")
				dive_timer = 0.45
				velocity.y = 2.0
				velocity.x *= Profiles.data.movement.dive_speed
				velocity.z *= Profiles.data.movement.dive_speed
			else:
				set_stance("stand" if stance == "prone" else "prone")
		"sprint":
			sprint_toggle = not sprint_toggle
			if cfg.cancel_ads_sprint and sprint_toggle:
				ads_toggle = false
				ads_suppressed = true
			if cfg.stance_sprint and sprint_toggle:
				set_stance("stand")
		"silent":
			silent = not silent
			sprint_toggle = false
		"breath":
			pass
		"scope":
			if weapon_slot == "Pistol":
				if hud != null: hud.notify("Pistol uses 1× iron sights • SWITCH for M14 optics")
				return
			var scopes = Schema.SCOPES
			Profiles.data.aim.scope = scopes[(scopes.find(Profiles.data.aim.scope)+1)%scopes.size()]
			if hud != null:
				hud.notify("Scope " + Profiles.data.aim.scope)
		"switch":
			switch_weapon()
		"flashlight":
			flashlight.visible = not flashlight.visible
		"gear", "gadget":
			if cfg.quick_throw == "Handheld":
				gear_ready = true
				if hud != null:
					hud.notify("Equipment ready • press FIRE to throw")
			else:
				use_gear()

func use_gear() -> void:
	if switch_left > 0: return
	if gear_timer > 0:
		if hud != null:
			hud.notify("Equipment cooldown %.1fs" % gear_timer)
		return
	gear_ready = false
	gear_timer = 3.0
	switch_left = 0.55
	if arena != null:
		arena.throw_equipment(camera.global_position,-camera.global_basis.z)

func lean_requested() -> int:
	if not Profiles.data.controls.lean_enabled:
		return 0
	var direct = 0
	if Profiles.data.controls.lean_mode != "Press":
		direct = int(bool(pressed.get("lean_right",false))) - int(bool(pressed.get("lean_left",false)))
	if direct != 0:
		return direct
	if lean_toggle != 0:
		return lean_toggle
	if Profiles.data.controls.ads_lean and explicit_ads():
		return last_lean
	return 0

func explicit_ads() -> bool:
	return ads_toggle or (Profiles.data.controls.ads_mode != "Press" and bool(pressed.get("ads",false)))

func ads_requested() -> bool:
	var c = Profiles.data.controls
	if ads_suppressed or (reload_left > 0 and c.cancel_ads_reload):
		return false
	var quick = c.quick_ads_ops if c.mode == "Operations" else c.quick_ads_war
	return explicit_ads() or (c.lean_ads and lean_requested()!=0) or (quick and (bool(pressed.get("fire",false)) or shot_queue>0))

func start_reload() -> void:
	if reload_left > 0 or switch_left > 0 or ammo >= int(weapon().magazine) or unlimited_ammo():
		return
	reload_total = weapon().empty_reload if ammo == 0 else weapon().reload
	reload_left = reload_total
	shot_queue = 0

func can_stand(height: float, at_position: Vector3) -> bool:
	var shape = CapsuleShape3D.new()
	shape.radius = 0.24
	shape.height = height
	var q = PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis.IDENTITY,at_position+Vector3(0,height/2+0.025,0))
	q.collision_mask = 9
	q.exclude = [get_rid()]
	q.margin = 0.005
	return get_world_3d().direct_space_state.intersect_shape(q,1).is_empty()

func set_stance(value: String) -> bool:
	var heights = {"stand":1.75,"crouch":1.12,"prone":0.52}
	var h = heights[value]
	if h > collider.shape.height and not can_stand(h,global_position):
		if hud != null:
			hud.notify("Not enough clearance to stand")
		return false
	stance = value
	collider.shape.height = h
	collider.position.y = h/2
	if value != "stand":
		sprint_toggle = false
	return true

func jump() -> void:
	var m = Profiles.data.movement
	if not is_on_floor() or jump_timer > 0 or (m.stamina and stamina < m.jump_cost):
		return
	if stance != "stand" and not set_stance("stand"):
		return
	var height = m.jump_height * (1.0 - minf(jump_fatigue,0.55))
	velocity.y = Math.jump_speed(m.gravity,height)
	jump_timer = m.jump_cooldown
	jump_fatigue = minf(0.55,jump_fatigue + m.repeat_jump_penalty)
	if m.stamina:
		stamina = maxf(0,stamina-m.jump_cost)
	if arena != null:
		arena.jumps += 1

func try_mantle() -> bool:
	var m = Profiles.data.movement
	if not m.mantle or mantle_timer > 0 or stance == "prone":
		return false
	var forward = -global_basis.z
	var origin = global_position+Vector3(0,0.45,0)
	var q = PhysicsRayQueryParameters3D.create(origin,origin+forward*0.95,9,[get_rid()])
	var hit = get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty() or hit.collider.has_meta("range_barrier"):
		return false
	var top_origin = hit.position + forward*0.45 + Vector3.UP*m.mantle_height
	var top = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(top_origin,top_origin-Vector3.UP*(m.mantle_height+0.2),1,[get_rid()]))
	if top.is_empty() or top.normal.y < 0.8:
		return false
	var height = top.position.y-global_position.y
	var destination = top.position+Vector3.UP*0.035
	if height < 0.25 or height > m.mantle_height or not can_stand(1.75,destination):
		return false
	if not set_stance("stand"):
		return false
	mantle_start = global_position
	mantle_end = destination
	mantle_timer = m.mantle_time
	velocity = Vector3.ZERO
	if arena != null:
		arena.vaults += 1
	return true

func _physics_process(dt: float) -> void:
	if not active:
		return
	elapsed += dt
	var m = Profiles.data.movement
	var w = weapon()
	var c = Profiles.data.controls
	jump_timer = maxf(0,jump_timer-dt)
	jump_fatigue = maxf(0,jump_fatigue-dt*0.08)
	switch_left = maxf(0,switch_left-dt)
	if switch_left == 0 and not pending_weapon.is_empty():
		complete_switch()
		w = weapon()
	gear_timer = maxf(0,gear_timer-dt)
	dive_timer = maxf(0,dive_timer-dt)
	if reload_left > 0:
		reload_left = maxf(0,reload_left-dt)
		if reload_left == 0:
			ammo = int(w.magazine)
	if c.combined_stance and bool(pressed.get("crouch",false)) and elapsed - float(press_times.get("crouch",elapsed)) >= c.hybrid_ms/1000.0 and stance != "prone":
		set_stance("prone")
	var requested = ads_requested()
	ads = move_toward(ads,1.0 if requested else 0.0,dt/maxf(w.ads_ms/1000.0,0.001))
	var move = (movement+keyboard).limit_length(1.0)
	var wants_sprint = sprint_toggle or (c.mode=="Warfare" and c.tactical_stick and move.y < -0.95)
	# Firing interrupts sprint; keep the intent so it can resume on release.
	if bool(pressed.get("fire",false)) or shot_queue > 0:
		wants_sprint = false
	var prior_sprint = sprinting
	sprinting = wants_sprint and move.y < -0.25 and ads < 0.05 and stance=="stand" and not silent and (not m.stamina or stamina > 0.03)
	if prior_sprint and not sprinting:
		sprint_delay = w.sprint_fire_ms/1000.0
	sprint_delay = maxf(0,sprint_delay-dt)
	if m.stamina:
		stamina = clampf(stamina + dt*(-m.stamina_drain if sprinting else m.stamina_recovery),0,1)
	else:
		stamina = 1.0
	var speed = m.walk
	if stance=="crouch":
		speed = m.crouch
	elif stance=="prone":
		speed = m.prone
	elif sprinting:
		speed = m.sprint * (m.tactical if c.mode=="Warfare" else 1.0)
	elif silent:
		speed = m.silent
	if ads > 0.01:
		speed = lerpf(speed,minf(speed,m.ads_walk),ads)
	speed *= m.pace
	if mantle_timer > 0:
		mantle_timer = maxf(0,mantle_timer-dt)
		var t = 1.0-mantle_timer/m.mantle_time
		var lift = Vector3(mantle_start.x,mantle_end.y+0.08,mantle_start.z)
		var destination = mantle_start.lerp(lift,minf(t/0.5,1)) if t<0.5 else lift.lerp(mantle_end,(t-0.5)*2)
		var collision = move_and_collide(destination-global_position)
		if collision != null:
			mantle_timer = 0
	else:
		var grounded = is_on_floor()
		if not grounded:
			velocity.y -= m.gravity * dt
		elif velocity.y < 0:
			velocity.y = -0.5
		var wanted = global_basis * Vector3(move.x,0,move.y) * speed
		var acceleration = m.acceleration * m.pace * (1.0 if grounded else m.air_control)
		if dive_timer <= 0:
			velocity.x = move_toward(velocity.x,wanted.x,acceleration*dt)
			velocity.z = move_toward(velocity.z,wanted.z,acceleration*dt)
		move_and_slide()
		if not grounded and is_on_floor():
			landing_kick = 0.06
		if m.auto_mantle and move.y < -0.8 and is_on_wall():
			try_mantle()
	breathing = ads > 0.9 and (c.auto_breath or bool(pressed.get("breath",false))) and breath > 0.001
	breath = clampf(breath + dt*(-1.0/w.breath_duration if breathing else 0.22),0,1)
	since_shot += dt
	spread_extra = maxf(0,spread_extra-w.spread_recovery*dt)
	if since_shot > w.recovery_delay:
		recoil = recoil.move_toward(Vector2.ZERO,deg_to_rad(w.recovery)*dt)
	var fire = bool(pressed.get("fire",false)) and fire_mode()=="Auto"
	var quick = c.quick_ads_ops if c.mode=="Operations" else c.quick_ads_war
	var allowed = reload_left<=0 and switch_left<=0 and not sprinting and sprint_delay<=0 and mantle_timer<=0 and not gear_ready and (not quick or ads>=0.99)
	shot_clock -= dt
	if allowed and (fire or shot_queue>0):
		var loops = 0
		while shot_clock <= 0 and loops<4 and (fire or shot_queue>0):
			if ammo <= 0 and not unlimited_ammo():
				if c.auto_reload:
					start_reload()
				break
			shoot()
			shot_queue = maxi(0,shot_queue-1)
			shot_clock += 60.0 / w.rpm
			loops += 1
		if not allowed or reload_left>0:
			shot_clock = maxf(shot_clock,0)
	else:
		shot_clock = maxf(shot_clock,0)
	if global_position.y < -8 or not Math.finite_vector(global_position):
		global_position = Vector3(0,0.05,10)
		velocity = Vector3.ZERO
	update_camera(dt)

func _process(dt: float) -> void:
	if not active:
		return
	var a = Profiles.data.aim
	if a.gyro != "Off" and (a.gyro=="Always" or ads>0.1):
		var gyro = Input.get_gyroscope()
		var horizontal = gyro.y
		var vertical = gyro.x
		if a.gyro_swap:
			horizontal = gyro.x
			vertical = gyro.y
		rotation.y += horizontal*dt*a.gyro_gain*(-1 if a.gyro_invert_x else 1)
		pitch = clampf(pitch+vertical*dt*a.gyro_gain*(-1 if a.gyro_invert_y else 1),deg_to_rad(-85),deg_to_rad(85))

func update_camera(dt: float) -> void:
	var m = Profiles.data.movement
	var w = weapon()
	var target_eye = {"stand":1.62,"crouch":1.0,"prone":0.40}[stance]
	var transition = m.prone_time if stance=="prone" or eye_height<0.8 else m.stance_time
	eye_height = move_toward(eye_height,target_eye,1.3*dt/transition)
	lean = move_toward(lean,float(lean_requested()),dt/maxf(m.lean_time,0.01))
	var eye = global_position+Vector3.UP*eye_height
	var offset = global_basis.x*lean*m.lean_distance
	var q = PhysicsRayQueryParameters3D.create(eye,eye+offset,9,[get_rid()])
	var hit = get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		offset *= clampf(eye.distance_to(hit.position)/maxf(offset.length(),0.001)-0.12,0,1)
	landing_kick = move_toward(landing_kick,0,dt*0.35)
	pivot.position = Vector3(0,eye_height-landing_kick,0)+global_basis.inverse()*offset
	var sway_amount = w.sway*(0.1 if breathing else 1.0)*ads
	var sway = Vector2(sin(elapsed*w.sway_hz*TAU),cos(elapsed*w.sway_hz*TAU*0.73))*deg_to_rad(sway_amount)
	if velocity.length()>0.3:
		sway *= 1.0+w.movement_stability*0.25
	pivot.rotation = Vector3(clampf(pitch+recoil.y+sway.y,deg_to_rad(-88),deg_to_rad(88)),recoil.x+sway.x,-deg_to_rad(m.lean_angle)*lean)
	var mag = magnification()
	var fov = float(Profiles.data.aim.fov)
	var zoomed = rad_to_deg(2*atan(tan(deg_to_rad(fov)*0.5)/(float(mag)*1.15)))
	var aspect = get_viewport().get_visible_rect().size.x/maxf(get_viewport().get_visible_rect().size.y,1)
	camera.fov = Math.vertical_fov(lerpf(fov,zoomed,ads),aspect)
	viewgun.position = Vector3(lerpf(0.22,0.0,ads),-0.20-absf(sin(elapsed*2))*0.002,-0.43)
	# Sight shake is cosmetic and distinct from the camera's recoil angle.
	var shake = exp(-since_shot*25.0)*w.sight_stability*0.006
	viewgun.position += Vector3(sin(elapsed*77.0)*shake,cos(elapsed*93.0)*shake,shake)
	viewgun.rotation.x = -0.4 if reload_left>0 else 0.0
	viewgun.visible = switch_left<=0 and not gear_ready and not (mag >= 2 and ads > 0.85)
	optic.visible = weapon_slot == "M14" and mag >= 2

func shoot() -> void:
	var w = weapon()
	if not unlimited_ammo():
		ammo -= 1
	shot_number += 1
	since_shot = 0
	var spread = lerpf(minf(w.max_spread,w.hip_spread+spread_extra),w.ads_spread,ads)
	if not is_on_floor():
		spread *= w.air_spread
	elif stance == "crouch":
		spread *= w.crouch_spread
	elif stance == "prone":
		spread *= w.prone_spread
	var angle = rng.randf()*TAU
	# Spread field is treated as cone half-angle; screenshot convention is unverified.
	var radius = tan(deg_to_rad(spread))*sqrt(rng.randf())
	var dir = (Vector3(cos(angle)*radius,sin(angle)*radius,-1)).normalized()
	dir = camera.global_basis*dir
	if arena != null:
		arena.spawn_bullet(camera.global_position,dir,w.velocity,w)
	var vm = w.vertical_recoil if w.mode=="Auto" else w.single_vertical
	var hm = w.horizontal_recoil if w.mode=="Auto" else w.single_horizontal
	var breath_scale = w.breath_recoil if breathing else 1.0
	var horizontal_pattern = sin(shot_number*0.48)*w.horizontal_kick
	var randomness = rng.randf_range(-w.recoil_random,w.recoil_random)
	recoil.y = minf(deg_to_rad(35),recoil.y+deg_to_rad(w.base_kick*vm*breath_scale))
	recoil.x = clampf(recoil.x+deg_to_rad((horizontal_pattern+randomness)*hm*w.firing_stability*breath_scale),deg_to_rad(-15),deg_to_rad(15))
	spread_extra = minf(w.max_spread-w.hip_spread,spread_extra+w.spread_growth)
	if hud != null:
		hud.hit_flash = maxf(hud.hit_flash,0)

func state_label() -> String:
	if reload_left>0:
		return "RELOADING"
	if switch_left > 0: return "SWITCHING"
	if mantle_timer>0:
		return "VAULTING"
	if sprinting:
		return "SPRINT"
	if gear_ready:
		return "EQUIPMENT READY"
	if ads>0.9:
		return "ADS %d×" % magnification()
	return "HIP FIRE"
