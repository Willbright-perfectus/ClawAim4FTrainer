extends Node
const Main = preload("res://scripts/main.gd")
const Schema = preload("res://scripts/config_schema.gd")
var checks = 0
var failures: Array = []
var results: Array = []

func _ready() -> void:
	run.call_deferred()

func frames(n: int) -> void:
	for i in range(n): await get_tree().process_frame

func check(ok: bool, description: String) -> void:
	checks += 1
	results.append({"check":description,"passed":ok})
	print("PASS " if ok else "FAIL ", description)
	if not ok: failures.append(description)

func run() -> void:
	Profiles.data = Schema.defaults()
	Profiles.data.controls.sound = false
	var app = Main.new()
	add_child(app)
	await frames(5)
	var enter: Button
	for candidate in app.find_children("*","Button",true,false):
		if candidate.text.begins_with("ENTER RANGE"): enter = candidate; break
	check(is_instance_valid(enter),"Main menu exposes an actionable range button")
	if is_instance_valid(enter):
		var tap = InputEventScreenTouch.new()
		tap.index = 0
		tap.position = enter.get_global_rect().get_center()
		tap.pressed = true
		Input.parse_input_event(tap)
		await frames(2)
		var release = InputEventScreenTouch.new()
		release.index = 0
		release.position = tap.position
		release.pressed = false
		Input.parse_input_event(release)
		await frames(4)
		check(app.state=="playing","A real screen-touch tap activates native menu controls")
		if app.state=="playing":
			var finger = InputEventScreenTouch.new()
			finger.index = 1
			finger.position = app.hud.button_center("fire")
			finger.pressed = true
			Input.parse_input_event(finger)
			await frames(2)
			check(app.hud.contacts.size()==1 and int(app.hud.held.get("fire",0))==1,"Emulated mouse does not duplicate a real HUD touch")
			app.pause_session()
			check(app.hud.contacts.is_empty() and not app.world.player.active,"Application pause clears real touch input before freezing")
			app.resume_session()
			await frames(2)
			check(not app.world.player.pressed.get("fire",false),"Resume never restores a previously held fire input")
	app.cleanup_world()
	app.queue_free()
	await get_tree().process_frame
	var report_path = OS.get_environment("CLAWLAB_UI_REPORT")
	if not report_path.is_empty():
		var file = FileAccess.open(report_path,FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"results":results},"\t"))
		file.close()
	print("UI TESTS COMPLETE: ",checks-failures.size(),"/",checks," passed")
	get_tree().quit(0 if failures.is_empty() else 1)
