extends Node
## Run in isolated user data: XDG_DATA_HOME=/tmp/clawlab-tests godot --headless
## --path . --fixed-fps 120 res://tests/test_runner.tscn
const Schema = preload("res://scripts/config_schema.gd")
const Arena = preload("res://scripts/arena.gd")
const Hud = preload("res://scripts/touch_hud.gd")
const Math = preload("res://scripts/trainer_math.gd")
var checks = 0
var failures: Array = []
var results: Array = []
var arena: Node3D
var hud: Control

func _ready() -> void:
	Engine.max_fps = 0
	run.call_deferred()

func check(ok: bool, description: String) -> void:
	checks += 1
	results.append({"check":description,"passed":ok})
	print("PASS " if ok else "FAIL ", description)
	if not ok: failures.append(description)

func ticks(n: int) -> void:
	for i in range(n): await get_tree().physics_frame

func create_arena(mode: String = "Free Range") -> void:
	if is_instance_valid(arena):
		hud.release_all()
		arena.queue_free()
		hud.queue_free()
		await get_tree().process_frame
	Profiles.data = Schema.defaults()
	Profiles.data.controls.sound = false
	Profiles.data.controls.ads_lean = false
	hud = Hud.new()
	add_child(hud)
	hud.enabled = true
	arena = Arena.new()
	arena.mode = mode
	arena.hud = hud
	add_child(arena)
	await ticks(10)

func run() -> void:
	print("CLAWLAB INTEGRATION TESTS / Godot ",Engine.get_version_info().string)
	var bad = Schema.defaults()
	bad.weapon.rpm = -10000
	bad.weapon.reload = INF
	bad.weapon.magazine = "NaN"
	bad.aim.gyro = "broken"
	bad.movement.gravity = 0
	bad.hud.fire.x = 40
	bad.hud.fire.visible = "false"
	var clean = Schema.sanitize(bad)
	check(clean.weapon.rpm==30 and clean.weapon.reload==2.7 and clean.weapon.magazine==30,"Malformed numeric inputs cannot reach simulation")
	check(clean.aim.gyro=="Off" and clean.movement.gravity==5,"Unknown modes and invalid gravity are sanitized")
	check(clean.hud.fire.x==0.97 and clean.hud.fire.visible,"HUD bounds and strict booleans are validated")
	check(Schema.sanitize(null)==Schema.defaults(),"Non-object profile falls back safely")
	var legacy = Schema.defaults()
	legacy.schema_version = 1
	legacy.erase("pistol")
	legacy.aim.hip_turn = 333
	legacy.aim.scope_2 = 0.77
	legacy.movement.acceleration = 22
	legacy.movement.prone_time = 0.61
	legacy.hud.reload.x = 0.42
	legacy.movement.erase("pace")
	var migrated = Schema.sanitize(legacy)
	check(migrated.aim.fire_hip_turn==333 and migrated.aim.fire_scope_2==0.77 and migrated.hud.reload.x==0.42,"Version 1 migration preserves sensitivity and HUD, seeds matching fire sensitivity")
	check(migrated.movement.pace==1.25 and migrated.movement.acceleration==36 and migrated.movement.prone_time==0.61,"Movement migration improves untouched defaults and preserves custom stance timing")
	var a = Schema.defaults().aim
	a.swipe_gain = 1.5
	a.fire_hip_turn = 120
	a.fire_ads_turn = 90
	a.fire_scope_2 = 0.4
	check(is_equal_approx(Math.turn_gain(a,0,false),360) and is_equal_approx(Math.turn_gain(a,0,false,true),180),"Swipe multiplier composes with independent camera and fire sensitivities")
	check(is_equal_approx(Math.turn_gain(a,1,true,true,2),54) and is_equal_approx(Math.turn_gain(a,1,true,true,1),135),"Fire sensitivity selects correct scope, with separate 1× pistol response")
	Profiles.data = Schema.defaults()
	var before = Profiles.export_text()
	check(not Profiles.import_text("{").is_empty() and Profiles.export_text()==before,"Invalid JSON leaves active configuration unchanged")
	check(not Profiles.import_text('{"schema_version":999,"weapon":{}}').is_empty(),"Unsupported profile versions are rejected")
	check(Profiles.import_text(before).is_empty(),"Profile JSON round-trip succeeds")
	check(Profiles.import_text(JSON.stringify(legacy)).is_empty() and Profiles.data.schema_version==2,"Version 1 JSON imports through compatible migration")
	Profiles.data = Schema.defaults()
	Profiles.save()
	Profiles.data.weapon.damage = 51
	check(Profiles.save(),"Atomic profile save succeeds")
	var f = FileAccess.open(Profiles.PATH,FileAccess.WRITE)
	f.store_string("corrupted"); f.close()
	Profiles.load_store()
	check(Profiles.data.weapon.damage==39 and "Recovered" in Profiles.status_message,"Corrupt active file recovers previous settings from backup")
	Profiles.data = Schema.defaults()
	Profiles.save()
	check(absf(Math.damage(Profiles.data.weapon,"head",20,0)-74)<0.001,"Zone-specific head damage uses screenshot preset")
	check(Math.damage(Profiles.data.weapon,"chest",150,0)<Math.damage(Profiles.data.weapon,"chest",20,0),"Projectile damage falls off over configured distance")
	await create_arena()
	var p = arena.player
	check(p.is_on_floor(),"Player settles on the solid range floor")
	var base_y = p.position.y
	p.jump()
	var apex = p.position.y
	for i in range(120):
		await ticks(1)
		apex = maxf(apex,p.position.y)
	check(absf(apex-base_y-Profiles.data.movement.jump_height)<0.07,"Jump apex matches configured 0.75 m within integration tolerance")
	check(p.is_on_floor() and absf(p.position.y-base_y)<0.03,"Jump lands without sinking through floor")
	p.set_stance("prone")
	p.position = Vector3(-14,0.02,-19)
	await ticks(20)
	check(p.stance=="prone" and p.collider.shape.height<0.6,"Prone lowers the physical collision shape")
	check(not p.set_stance("stand"),"Low tunnel prevents standing through geometry")
	p.position = Vector3(-14,0.02,3.8)
	p.set_stance("stand")
	await ticks(15)
	check(p.try_mantle(),"Mantle finds a low obstacle with free standing clearance")
	await ticks(100)
	check(p.position.y>0.65 and p.position.z<3.0,"Mantle traverses obstacle using collision-aware motion")
	await create_arena()
	p = arena.player
	p.position = Vector3(0,0.03,15)
	p.set_movement(Vector2.RIGHT)
	await ticks(40)
	check(absf(p.velocity.x-3.32*1.25)<0.05,"Default full-stick walk reaches 25 percent faster movement pace")
	p.set_movement(Vector2.ZERO)
	p.position = Vector3(0,0.03,8)
	p.velocity = Vector3.ZERO
	await ticks(10)
	p.jump()
	p.set_movement(Vector2.UP)
	await ticks(150)
	check(p.position.z>7.1,"Firing-line barrier stops walking and jumping into dummy bay")
	check(not p.try_mantle(),"Firing-line barrier cannot be vaulted")
	p.set_stance("prone")
	await ticks(120)
	check(p.position.z>7.1,"Prone player cannot crawl through the range barrier")
	p.set_movement(Vector2.ZERO)
	p.position = Vector3(-8.5,0.03,-10)
	p.velocity = Vector3.ZERO
	p.set_movement(Vector2.RIGHT)
	await ticks(150)
	check(p.position.x < -7.8,"Side partition prevents entering dummy bay through movement area")
	await create_arena()
	p = arena.player
	hud.pointer_down(0,hud.button_center("move"))
	hud.pointer_move(0,hud.button_center("move")+Vector2(0,-50))
	hud.pointer_down(1,hud.button_center("fire"))
	hud.pointer_down(2,hud.button_center("ads"))
	hud.pointer_down(3,Vector2(720,320))
	var yaw = p.rotation.y
	hud.pointer_move(3,Vector2(760,320))
	await ticks(12)
	check(hud.peak_touches==4 and p.movement.y<0 and p.pressed.get("fire",false) and p.explicit_ads(),"Four simultaneous contacts independently move, fire, ADS and aim")
	check(p.rotation.y<yaw,"Aiming contact rotates camera while other fingers remain held")
	var stable_yaw = p.rotation.y
	hud.pointer_move(1,hud.button_center("fire")+Vector2(45,0))
	check(is_equal_approx(p.rotation.y,stable_yaw),"Fire button with camera turning disabled does not hijack aim")
	hud.pointer_up(1)
	check(not p.pressed.get("fire",false) and p.explicit_ads(),"Releasing fire leaves the independent ADS contact active")
	hud.release_all()
	check(hud.contacts.is_empty() and p.movement==Vector2.ZERO and not p.pressed.get("ads",false),"Cancel/pause releases every held contact")
	hud.pointer_down(4,hud.button_center("fire"))
	hud.pointer_down(5,hud.button_center("fire"))
	hud.pointer_up(4)
	check(p.pressed.get("fire",false),"Two contacts on one action do not release each other prematurely")
	hud.pointer_up(5)
	check(not p.pressed.get("fire",false),"Final action contact releases cleanly")
	hud.pointer_down(6,hud.button_center("move"))
	hud.pointer_down(7,hud.button_center("move")+Vector2(0,-40))
	hud.pointer_up(6)
	check(hud.move_id==7 and p.movement.y<0,"Joystick ownership transfers safely after a duplicate contact")
	hud.release_all()
	await create_arena("Recoil Board")
	p = arena.player
	Profiles.data.weapon.rpm = 600
	Profiles.data.weapon.magazine = 100
	p.ammo = 100
	p.on_action("fire",true)
	await ticks(120)
	p.on_action("fire",false)
	check(arena.shots>=10 and arena.shots<=11,"600 RPM fires 10–11 shots across a one-second tick boundary")
	check(p.ammo==100-arena.shots,"Ammunition consumption agrees with emitted projectiles")
	p.ammo = 0
	Profiles.data.weapon.empty_reload = 0.25
	p.start_reload()
	await ticks(40)
	check(p.ammo==100 and p.reload_left==0,"Empty reload replenishes configured capacity after its duration")
	p.ammo = 1
	p.start_reload()
	p.on_action("fire",true)
	check(p.reload_left==0,"Hybrid cancellation interrupts reload on fire input")
	p.on_action("fire",false)
	Profiles.data.weapon.mode = "Single"
	Profiles.data.controls.release_fire = true
	p.ammo = 100
	p.reload_left = 0
	p.shot_queue = 0
	await ticks(20)
	var shots_before = arena.shots
	p.on_action("fire",true)
	await ticks(20)
	check(arena.shots==shots_before,"Release-fire single shot waits while button is held")
	p.on_action("fire",false)
	await ticks(5)
	check(arena.shots==shots_before+1,"Release-fire emits exactly one shot on release")
	Profiles.data.controls.mode = "Warfare"
	p.ads = 0
	shots_before = arena.shots
	p.on_action("fire",true)
	await ticks(2)
	p.on_action("fire",false)
	await ticks(60)
	check(arena.shots==shots_before+1,"Quick ADS retains a released single shot until ADS is ready")
	await create_arena()
	p = arena.player
	p.ammo = 19
	p.start_reload()
	check(p.reload_left>0 and p.reload_total==Profiles.data.weapon.reload,"M14 exposes reload countdown and duration for button overlay")
	p.on_action("switch",true)
	p.on_action("switch",false)
	await ticks(100)
	check(p.weapon_slot=="Pistol" and p.reload_left==0,"Switch equips real pistol and cancels M14 reload")
	shots_before = arena.shots
	p.on_action("fire",true)
	await ticks(120)
	check(arena.shots==shots_before+1,"Holding pistol FIRE produces exactly one bullet")
	p.on_action("fire",false)
	for i in range(40):
		p.on_action("fire",true)
		await ticks(24)
		p.on_action("fire",false)
	check(arena.shots==shots_before+41 and p.ammo==1 and p.reload_left==0,"Repeated pistol taps have unlimited ammo without automatic reload")
	p.start_reload()
	check(p.reload_left==0,"Pistol ignores manual reload")
	Profiles.data.pistol.mode = "Auto"
	p.on_action("fire",true)
	await ticks(100)
	p.on_action("fire",false)
	check(arena.shots==shots_before+42,"Pistol remains single-shot even if a runtime config requests auto")
	p.on_action("switch",true)
	p.on_action("switch",false)
	await ticks(100)
	check(p.weapon_slot=="M14" and p.ammo==19,"Switch back restores M14 ammunition without granting a free reload")
	Profiles.data.aim.scope = "2×"
	p.on_action("ads",true)
	await ticks(45)
	var fov2 = p.camera.fov
	for i in range(4):
		p.on_action("scope",true)
		p.on_action("scope",false)
		await ticks(2)
	check(p.magnification()==8 and p.camera.fov<fov2*0.4,"M14 scope button cycles through 2× to 8× with real optical zoom")
	p.switch_weapon()
	await ticks(100)
	check(p.magnification()==1 and p.camera.fov>fov2,"Pistol uses iron sights instead of inheriting M14 magnification")
	await create_arena("Tracking")
	p = arena.player
	var target = arena.targets[0]
	Profiles.data.drill.speed = 0
	var start = p.camera.global_position
	var aim = target.global_position+Vector3.UP*1.27
	arena.spawn_bullet(start,(aim-start).normalized(),2000)
	await ticks(4)
	check(arena.hits==1,"Segment collision detects a high-speed projectile crossing a thin target")
	check(target.health<100,"Projectile collision applies damage to the target")
	target.health = 100
	var shot_weapon = Profiles.data.weapon.duplicate(true)
	shot_weapon.damage = 17
	shot_weapon.bullet_gravity = 0
	arena.spawn_bullet(start,(aim-start).normalized(),30,shot_weapon)
	shot_weapon.damage = 99
	p.switch_weapon()
	await ticks(100)
	check(is_equal_approx(target.health,83),"In-flight bullet retains launch damage after weapon changes, and passes barrier")
	var elapsed_before = arena.elapsed
	arena.set_paused(true)
	await ticks(30)
	check(is_equal_approx(elapsed_before,arena.elapsed) and not p.active,"Paused sessions stop simulation time and player input")
	arena.set_paused(false)
	await ticks(2)
	check(arena.elapsed>elapsed_before,"Resume restarts simulation without losing the session")
	for mode in Arena.DRILLS:
		await create_arena(mode)
		await ticks(8)
		check(is_instance_valid(arena.player) and Math.finite_vector(arena.player.position),"Drill starts and simulates: "+mode)
	await create_arena("Recoil Board")
	Profiles.data.drill.infinite_ammo = true
	Profiles.data.weapon.rpm = 1800
	arena.player.on_action("fire",true)
	await ticks(720)
	check(arena.shots>=170 and arena.bullets.size()==64 and arena.impacts.size()==160,"Sustained 1800 RPM keeps projectile and impact pools bounded")
	hud.release_all()
	arena.player.on_action("fire",false)
	arena.set_paused(true)
	arena.queue_free()
	hud.queue_free()
	await get_tree().process_frame
	Profiles.data = Schema.defaults()
	Profiles.data.controls.sound = false
	var report = {"engine":Engine.get_version_info().string,"checks":checks,"failures":failures,"results":results}
	var report_path = OS.get_environment("CLAWLAB_TEST_REPORT")
	if not report_path.is_empty():
		var report_file = FileAccess.open(report_path,FileAccess.WRITE)
		if report_file: report_file.store_string(JSON.stringify(report,"\t")); report_file.close()
	print("TESTS COMPLETE: ",checks-failures.size(),"/",checks," passed")
	get_tree().quit(0 if failures.is_empty() else 1)
