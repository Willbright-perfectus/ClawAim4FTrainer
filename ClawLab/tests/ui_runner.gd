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

func touch(at: Vector2, down: bool) -> void:
	var event = InputEventScreenTouch.new()
	event.index = 0
	event.position = at
	event.pressed = down
	Input.parse_input_event(event)
	await frames(2)

func swipe(from: Vector2, to: Vector2) -> void:
	await touch(from,true)
	var last = from
	for i in range(1,7):
		var event = InputEventScreenDrag.new()
		event.index = 0
		event.position = from.lerp(to,i/6.0)
		event.relative = event.position-last
		last = event.position
		Input.parse_input_event(event)
		await frames(2)
	await touch(to,false)
	await frames(15)

func find_button(app: Node, text: String) -> Button:
	for candidate in app.find_children("*","Button",true,false):
		if candidate.text == text: return candidate
	return null

func run() -> void:
	Profiles.data = Schema.defaults()
	Profiles.data.controls.sound = false
	var app = Main.new()
	add_child(app)
	await frames(5)
	var controls_button = find_button(app,"Controls")
	await swipe(controls_button.get_global_rect().get_center(),controls_button.get_global_rect().get_center()-Vector2(0,180))
	check(app.page=="Train" and app.nav_scroll.scroll_vertical>60,"Sidebar swipe starting on a button scrolls without selecting that page")
	var old_offset = app.nav_scroll.scroll_vertical
	var history_button = find_button(app,"History")
	var history_at = history_button.get_global_rect().get_center()
	await frames(12)
	await touch(history_at,true)
	await touch(history_at,false)
	await frames(5)
	check(app.page=="History" and app.nav_scroll.scroll_vertical==old_offset,"Tap after swipe selects page and preserves sidebar scroll position")
	var nav_rect = app.nav_scroll.get_global_rect()
	await swipe(nav_rect.get_center(),nav_rect.get_center()+Vector2(0,180))
	check(app.page=="History" and app.nav_scroll.scroll_vertical==0,"Downward sidebar swipe returns to the top without accidental selection")
	app.show_page("Weapon")
	await frames(5)
	var content_scroll = app.find_child("ContentScroll",true,false)
	var start = content_scroll.get_global_rect().position+Vector2(160,320)
	await swipe(start,start-Vector2(0,200))
	check(content_scroll.scroll_vertical>120 and app.page=="Weapon","Settings content supports vertical touch scrolling")
	app.show_page("Aim")
	await frames(5)
	for category in ["Camera sensitivity","Fire sensitivity","Swipe sensitivity"]:
		var tab = find_button(app,category)
		await touch(tab.get_global_rect().get_center(),true)
		await touch(tab.get_global_rect().get_center(),false)
		await frames(4)
		check(app.sensitivity_category==category,"Sensitivity category is reachable by native touch: "+category)
	app.show_page("Weapon")
	await frames(5)
	var pistol = find_button(app,"Pistol")
	await touch(pistol.get_global_rect().get_center(),true)
	await touch(pistol.get_global_rect().get_center(),false)
	await frames(4)
	check(app.weapon_editor=="Pistol" and is_instance_valid(find_button(app,"Start with Pistol")),"Pistol settings and starting weapon selection are accessible")
	app.show_page("Train")
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
