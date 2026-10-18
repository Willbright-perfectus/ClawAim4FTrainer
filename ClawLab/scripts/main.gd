extends Node

const Schema = preload("res://scripts/config_schema.gd")
const Arena = preload("res://scripts/arena.gd")
const Hud = preload("res://scripts/touch_hud.gd")
const BG = Color("0c151e")
const PANEL = Color("14232e")
const BORDER = Color("2b414d")
const TEXT = Color("e6f0f1")
const MUTED = Color("90a9b6")
const MINT = Color("57dfbc")
const AMBER = Color("f1bb79")
var ui: Control
var hud: Control
var world: Node3D
var content: VBoxContainer
var page = "Train"
var state = "menu"
var last_drill = "Free Range"
var dirty = false
var save_timer = 0.0
var status: Label
var hud_backup: Dictionary
var editor_size: HSlider
var editor_alpha: HSlider
var editor_visible: CheckButton
var editor_name: Label
var editor_sync = false
var desktop_capture = false
var keys: Dictionary = {}
var app_theme: Theme
var test_mode = false

func _ready() -> void:
	test_mode = "--test-ui" in OS.get_cmdline_user_args()
	app_theme = make_theme()
	var canvas = CanvasLayer.new()
	add_child(canvas)
	hud = Hud.new()
	hud.visible = false
	canvas.add_child(hud)
	hud.pause_requested.connect(pause_session)
	hud.editor_selected.connect(sync_editor)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = app_theme
	canvas.add_child(ui)
	show_page("Train")
	if test_mode:
		run_ui_capture.call_deferred()

func style(color: Color, edge: Color = Color.TRANSPARENT, radius: int = 12) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = edge
	s.set_border_width_all(1 if edge.a > 0 else 0)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func make_theme() -> Theme:
	var t = Theme.new()
	t.default_font_size = 19
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_stylebox("normal", "Button", style(Color("203441"), BORDER))
	t.set_stylebox("hover", "Button", style(Color("294956"), MINT))
	t.set_stylebox("pressed", "Button", style(Color("28594f"), MINT))
	t.set_stylebox("focus", "Button", style(Color(0,0,0,0), MINT))
	t.set_stylebox("normal", "LineEdit", style(Color("0c1922"), BORDER, 8))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_stylebox("normal", "TextEdit", style(Color("0c1922"), BORDER, 8))
	t.set_color("font_color", "TextEdit", TEXT)
	t.set_stylebox("panel", "PopupMenu", style(PANEL, BORDER))
	t.set_constant("separation", "VBoxContainer", 12)
	t.set_constant("separation", "HBoxContainer", 12)
	t.set_constant("h_separation", "GridContainer", 16)
	t.set_constant("v_separation", "GridContainer", 16)
	return t

func label(text: String, size_px: int = 20, color: Color = TEXT) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func button(text: String, action: Callable, accent: bool = false) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size.y = 48
	b.focus_mode = Control.FOCUS_NONE
	# Change screens after the current GUI input traversal has completed.
	b.pressed.connect(action, CONNECT_DEFERRED)
	if accent:
		b.add_theme_stylebox_override("normal", style(MINT, MINT))
		b.add_theme_color_override("font_color", BG)
	return b

func panel(parent: Node, color: Color = PANEL) -> PanelContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(color, BORDER))
	parent.add_child(p)
	return p

func clear_ui() -> void:
	for c in ui.get_children():
		ui.remove_child(c)
		c.queue_free()
	status = null

func fill(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func save_settings() -> void:
	if dirty:
		var ok = Profiles.save()
		if is_instance_valid(status):
			status.text = "Saved on this device" if ok else Profiles.status_message
			status.modulate = MUTED if ok else AMBER
		dirty = not ok
		Profiles.apply_performance()

func mark_dirty() -> void:
	dirty = true
	save_timer = 0.7
	if is_instance_valid(status):
		status.text = "Saving…"

func show_page(next_page: String) -> void:
	save_settings()
	page = next_page
	state = "menu"
	clear_ui()
	ui.visible = true
	var bg = ColorRect.new()
	bg.color = BG
	fill(bg)
	ui.add_child(bg)
	var outer = MarginContainer.new()
	fill(outer)
	for side in ["left","right","top","bottom"]:
		outer.add_theme_constant_override("margin_"+side, 22)
	ui.add_child(outer)
	var layout = HBoxContainer.new()
	layout.add_theme_constant_override("separation", 26)
	outer.add_child(layout)
	var nav = VBoxContainer.new()
	nav.custom_minimum_size.x = 205
	layout.add_child(nav)
	var brand = HBoxContainer.new()
	nav.add_child(brand)
	var icon = TextureRect.new()
	icon.texture = preload("res://assets/icon.svg")
	icon.custom_minimum_size = Vector2(48,48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brand.add_child(icon)
	var brand_name = label("CLAWLAB",25,MINT)
	brand_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	brand.add_child(brand_name)
	nav.add_child(label("MOBILE AIM STUDIO", 12, MUTED))
	nav.add_child(HSeparator.new())
	var nav_scroll = ScrollContainer.new()
	nav_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	nav.add_child(nav_scroll)
	var nav_items = VBoxContainer.new()
	nav_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_items.add_theme_constant_override("separation", 5)
	nav_scroll.add_child(nav_items)
	for item in ["Train","Weapon","Aim","Controls","Movement","HUD editor","Drill setup","Performance","Profiles","History","About"]:
		var callback = edit_hud if item == "HUD editor" else show_page.bind(item)
		var b = button(item, callback, item == page)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 42
		b.add_theme_font_size_override("font_size", 18)
		nav_items.add_child(b)
	nav.add_child(label("v0.1.0  •  OFFLINE", 12, MUTED))
	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(right)
	var header = HBoxContainer.new()
	right.add_child(header)
	var title = label(page, 32)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var profile_tag = label(Profiles.data.profile_name + "  /  " + Profiles.data.controls.mode, 16, MINT)
	profile_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	profile_tag.custom_minimum_size.x = 300
	header.add_child(profile_tag)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	scroll.add_child(content)
	status = label("Saved on this device" if Profiles.status_message.is_empty() else Profiles.status_message, 13, MUTED)
	right.add_child(status)
	match page:
		"Train": build_home()
		"HUD editor": pass
		"Profiles": build_profiles()
		"History": build_history()
		"About": build_about()
		_: build_settings({"Weapon":"weapon", "Aim":"aim", "Controls":"controls", "Movement":"movement", "Drill setup":"drill", "Performance":"performance"}.get(page,"aim"))

func build_home() -> void:
	var hero = panel(content,Color("18372f"))
	var row = HBoxContainer.new()
	hero.add_child(row)
	var copy = VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(label("Build aim that fits your fingers.", 29))
	copy.add_child(label("Four-finger controls. Your weapon. Your rhythm.", 19, Color("bbd8cf")))
	copy.add_child(label("Start with Free Range, then tune your HUD and swipe sensitivity.", 16, MUTED))
	var start = button("ENTER RANGE  →", start_session.bind("Free Range"), true)
	start.custom_minimum_size.x = 235
	start.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(start)
	var stats_row = HBoxContainer.new()
	content.add_child(stats_row)
	for text in ["M14  /  727 RPM", "94° FOV  /  NO GYRO", "18 HUD CONTROLS", "10 TRAINING MODES"]:
		var p = panel(stats_row)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.add_child(label(text,14,MUTED))
	# The first two cards reflect the current editable profile.
	stats_row.get_child(0).get_child(0).text = "%s  /  %d RPM" % [Profiles.data.weapon.name.split(" • ")[0],Profiles.data.weapon.rpm]
	stats_row.get_child(1).get_child(0).text = "%d° FOV  /  GYRO %s" % [Profiles.data.aim.fov,Profiles.data.aim.gyro.to_upper()]
	content.add_child(label("CHOOSE YOUR FOCUS", 14, MINT))
	var grid = GridContainer.new()
	grid.columns = 3
	content.add_child(grid)
	for i in range(Arena.DRILLS.size()):
		var name_drill = Arena.DRILLS[i]
		var card = panel(grid)
		card.custom_minimum_size = Vector2(290,180)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var col = VBoxContainer.new()
		card.add_child(col)
		col.add_child(label("%02d  /  %s" % [i+1,name_drill.to_upper()],18,MINT if i<5 else AMBER))
		var desc = label(Arena.DESCRIPTIONS[name_drill],17,MUTED)
		desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.add_child(desc)
		col.add_child(button("Start  →",start_session.bind(name_drill)))

func build_settings(group: String) -> void:
	var notes = {
		"weapon":"The M14 preset uses values from your screenshots. Recoil curves, spread growth and the armor model are adjustable trainer approximations.",
		"aim":"Sensitivity uses degrees per full-width swipe. Delta Force sensitivity numbers are not interchangeable: use Calibration to match a measured 360° turn.",
		"controls":"Hold = active while pressed. Press = tap to toggle. Hybrid = tap to toggle, hold momentarily. A separate aiming finger has priority over button camera turning.",
		"movement":"Walk, sprint and ADS speeds come from the M14 screenshots. Other physics are editable approximations; exact Delta Force movement constants are not public.",
		"drill":"Use the same seed, target settings and weapon profile to compare sessions. Armor is a simplified trainer model; it does not reproduce Delta Force armor classes.",
		"performance":"Start at 60 FPS. Higher limits require device testing. Lower rendering resolution reduces GPU load. The overlay reports actual frame time, not just the selected limit."
	}
	content.add_child(label(notes[group],18,MUTED))
	for f in Schema.GROUPS[group]:
		var row = HBoxContainer.new()
		row.custom_minimum_size.y = 52
		content.add_child(row)
		var name_label = label(f[1],19)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(name_label)
		var value = Profiles.data[group][f[0]]
		var key = f[0]
		var field: Control
		if f[2] is bool:
			var check = CheckButton.new()
			check.button_pressed = value
			check.toggled.connect(func(v): Profiles.data[group][key] = v; mark_dirty())
			field = check
		elif f.size()==6:
			var spin = SpinBox.new()
			spin.min_value = f[3]
			spin.max_value = f[4]
			spin.step = f[5]
			spin.value = value
			spin.value_changed.connect(func(v): Profiles.data[group][key] = v; mark_dirty())
			field = spin
		elif f.size()==4:
			var options = OptionButton.new()
			var choices = f[3]
			for choice in choices:
				options.add_item(choice)
			options.select(maxi(0,choices.find(value)))
			options.item_selected.connect(func(n): Profiles.data[group][key] = choices[n]; mark_dirty())
			field = options
		else:
			var edit = LineEdit.new()
			edit.text = str(value)
			edit.max_length = 64
			edit.text_changed.connect(func(v): Profiles.data[group][key] = v; mark_dirty())
			field = edit
		field.custom_minimum_size = Vector2(275,48)
		row.add_child(field)
		content.add_child(HSeparator.new())
	content.add_child(button("Test in Free Range  →",start_session.bind("Free Range"),true))

func build_profiles() -> void:
	content.add_child(label("Profiles save your complete HUD, weapon, controls and physics. Export JSON to move a setup between devices.",19,MUTED))
	var row = HBoxContainer.new()
	content.add_child(row)
	var name_input = LineEdit.new()
	name_input.text = Profiles.data.profile_name
	name_input.max_length = 64
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_input)
	row.add_child(button("Save named profile",func():
		if Profiles.save_slot(name_input.text): show_page("Profiles")
		else: status.text = "Enter a profile name, and check free storage."
	,true))
	row.add_child(button("Import / export JSON",open_transfer))
	for slot in Profiles.slots:
		var card = panel(content)
		var line = HBoxContainer.new()
		card.add_child(line)
		var l = label(slot,20)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(l)
		line.add_child(button("Load",func():
			Profiles.data = Schema.sanitize(Profiles.slots[slot]); dirty = true; show_page("Profiles")
		))
		line.add_child(button("Delete",func():
			confirm_action("Delete saved profile “%s”?" % slot,func(): Profiles.slots.erase(slot); Profiles.save(); show_page("Profiles"))
		))
	if Profiles.slots.is_empty():
		content.add_child(label("No named profiles yet. Your current setup is already saved automatically.",18,MUTED))
	content.add_child(button("Restore screenshot-based M14 defaults",func():
		confirm_action("Replace the active setup with the M14 defaults? Named profiles stay saved.",func(): Profiles.data = Schema.defaults(); dirty = true; show_page("Profiles"))
	))

func open_transfer() -> void:
	var box = modal("Profile JSON", Vector2(1060,550))
	box.add_child(label("Copy to export. Paste a ClawLab profile below and choose Import. Numeric values are checked before saving.",17,MUTED))
	var edit = TextEdit.new()
	edit.text = Profiles.export_text()
	edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	edit.custom_minimum_size.y = 300
	edit.add_theme_font_size_override("font_size",16)
	box.add_child(edit)
	var feedback = label("",16,AMBER)
	box.add_child(feedback)
	var row = HBoxContainer.new()
	box.add_child(row)
	row.add_child(button("Copy JSON",func(): DisplayServer.clipboard_set(edit.text); feedback.text = "Copied to clipboard."))
	row.add_child(button("Paste",func(): edit.text = DisplayServer.clipboard_get()))
	row.add_child(button("Import",func():
		var error = Profiles.import_text(edit.text)
		if error.is_empty(): show_page("Profiles")
		else: feedback.text = error
	,true))
	row.add_child(button("Close",show_page.bind("Profiles")))

func modal(title: String, dimensions: Vector2 = Vector2(650,300)) -> VBoxContainer:
	var shade = ColorRect.new()
	shade.color = Color(0.02,0.05,0.08,0.92)
	fill(shade)
	ui.add_child(shade)
	var center = CenterContainer.new()
	fill(center)
	ui.add_child(center)
	var p = panel(center)
	p.custom_minimum_size = dimensions
	var box = VBoxContainer.new()
	p.add_child(box)
	box.add_child(label(title,27))
	return box

func confirm_action(message: String, action: Callable) -> void:
	var box = modal("Confirm",Vector2(800,260))
	box.add_child(label(message,20,MUTED))
	var row = HBoxContainer.new()
	box.add_child(row)
	row.add_child(button("Continue",action,true))
	row.add_child(button("Cancel",show_page.bind(page)))

func build_history() -> void:
	content.add_child(label("The most recent 100 sessions are stored locally with the exact configuration used. Compare sessions with the same configuration signature.",18,MUTED))
	if Profiles.history.is_empty():
		content.add_child(label("Your first session starts here.",28))
		content.add_child(button("Enter Free Range",start_session.bind("Free Range"),true))
	for result in Profiles.history:
		var card = panel(content)
		var box = VBoxContainer.new()
		card.add_child(box)
		box.add_child(label("%s  /  %s" % [result.get("drill","Session"),result.get("date","")],21))
		box.add_child(label("%.1f%% accuracy  •  %d hits / %d shots  •  %d kills  •  %.1f s" % [float(result.get("accuracy",0)),int(result.get("hits",0)),int(result.get("shots",0)),int(result.get("kills",0)),float(result.get("seconds",0))],18,MINT))
		box.add_child(label("%s  •  Configuration %s" % [result.get("profile",""),result.get("signature","")],14,MUTED))
		if result.get("configuration") is Dictionary:
			box.add_child(button("Load this session’s setup",func():
				Profiles.data = Schema.sanitize(result.configuration); dirty = true; show_page("Train")
			))

func build_about() -> void:
	content.add_child(label("Made for the way you play.",32,MINT))
	content.add_child(label("ClawLab is an independent, offline mobile aim trainer. It combines tracking, flicks, recoil practice and four-finger action drills with an editable HUD and weapon model.",21))
	content.add_child(label("Your starting profile",23,AMBER))
	content.add_child(label("M14 values and control choices were transcribed from your screenshots. The HUD is an approximate four-finger layout; adjust its placement on your phone before training. Aim sensitivity must be calibrated separately.",19,MUTED))
	content.add_child(label("Physics and fidelity",23,AMBER))
	content.add_child(label("Jumping, crouching, prone, leaning, sprinting, stamina, mantling and a Warfare dive are implemented with collision. Unpublished constants, recoil patterns, armor and aim slowdown use editable trainer approximations. Exact game equivalence has not been measured. Inventory, parachuting, swimming and operator abilities are outside this build.",19,MUTED))
	content.add_child(label("Before a serious session",23,AMBER))
	content.add_child(label("Use Calibration to match your 360° swipe and FOV. Set the same FPS and sensitivity modes as your game. Run the Movement Course and adjust jump height, gravity, stance timing and lean distance. Check sustained frame times on your own phone.",19,MUTED))
	content.add_child(label("Desktop testing",23,AMBER))
	content.add_child(label("F1 captures/releases the mouse. WASD moves; Shift toggles sprint; Space jumps; C crouches; Z goes prone; Q/E lean; R reloads; right mouse aims; left mouse fires; Esc pauses. Touch controls remain the primary input.",19,MUTED))
	content.add_child(label("Version 0.1.0 • Godot 4.5.1 • Original procedural assets • No accounts, ads or network access. Not affiliated with Delta Force, Team Jade, TiMi, Garena or Aimlabs. See the repository for research, tests and third-party notices.",16,MUTED))
	content.add_child(button("Engine and third-party licenses",func():
		var box = modal("Engine and third-party licenses",Vector2(1050,550))
		var licenses = TextEdit.new()
		licenses.text = FileAccess.get_file_as_string("res://THIRD_PARTY_NOTICES.txt")
		licenses.editable = false
		licenses.custom_minimum_size.y = 390
		licenses.add_theme_font_size_override("font_size",16)
		box.add_child(licenses)
		box.add_child(button("Close",show_page.bind("About")))
	))

func start_session(drill: String) -> void:
	save_settings()
	cleanup_world()
	clear_ui()
	ui.visible = false
	state = "playing"
	last_drill = drill
	hud.enabled = true
	hud.editing = false
	hud.visible = true
	hud.total_misses = 0
	hud.peak_touches = 0
	hud.trails.clear()
	world = Arena.new()
	world.mode = drill
	world.hud = hud
	world.finished.connect(on_finished)
	add_child(world)
	hud.notify("Drag empty space to aim • Pause at top right")

func cleanup_world() -> void:
	hud.release_all()
	hud.enabled = false
	hud.visible = false
	hud.player = null
	hud.arena = null
	keys.clear()
	desktop_capture = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(world):
		for connection in hud.action_event.get_connections(): hud.action_event.disconnect(connection.callable)
		for connection in hud.look_motion.get_connections(): hud.look_motion.disconnect(connection.callable)
		for connection in hud.move_motion.get_connections(): hud.move_motion.disconnect(connection.callable)
		remove_child(world)
		world.queue_free()
	world = null

func pause_session() -> void:
	if state != "playing" or not is_instance_valid(world): return
	state = "paused"
	hud.release_all()
	hud.enabled = false
	world.set_paused(true)
	keys.clear()
	desktop_capture = false
	ui.visible = true
	clear_ui()
	var box = modal("Session paused",Vector2(650,380))
	box.add_child(label("%s  •  %.1f seconds  •  %d shots" % [last_drill,world.elapsed,world.shots],19,MUTED))
	box.add_child(button("Resume",resume_session,true))
	box.add_child(button("Finish and save result",func(): world.running = true; world.finish()))
	box.add_child(button("Discard and return",func(): cleanup_world(); show_page("Train")))

func resume_session() -> void:
	if state != "paused": return
	clear_ui()
	ui.visible = false
	state = "playing"
	hud.enabled = true
	world.set_paused(false)

func on_finished(result: Dictionary) -> void:
	# Physics callbacks must not remove collision objects during query flushing.
	state = "results"
	hud.release_all()
	hud.enabled = false
	complete_session.call_deferred(result)

func complete_session(result: Dictionary) -> void:
	Profiles.add_result(result)
	cleanup_world()
	show_page("Train")
	state = "results"
	clear_ui()
	var bg = ColorRect.new()
	bg.color = BG
	fill(bg)
	ui.add_child(bg)
	var box = modal("%s  /  SESSION COMPLETE" % result.drill.to_upper(),Vector2(1080,550))
	box.add_child(label("%.1f seconds  •  %s" % [result.seconds,Profiles.data.profile_name],19,MUTED))
	var grid = GridContainer.new()
	grid.columns = 4
	box.add_child(grid)
	var values = [["ACCURACY","%.1f%%" % result.accuracy],["HITS / SHOTS","%d / %d" % [result.hits,result.shots]],["TARGETS CLEARED",str(result.kills)],["HEADSHOTS",str(result.headshots)], ["NEAR-TARGET AIM","%.1f%%" % result.tracking_percent],["TIME MOVING","%.1f%%" % result.moving_percent],["PROMPTS / REACTION","%d / %d ms" % [result.prompt_success,result.reaction_ms]],["PEAK TOUCHES",str(result.peak_touches)]]
	for item in values:
		var p = panel(grid)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.custom_minimum_size = Vector2(235,95)
		var col = VBoxContainer.new()
		p.add_child(col)
		col.add_child(label(item[0],13,MUTED))
		col.add_child(label(item[1],27,MINT))
	box.add_child(label("%d jump / %d vault  •  %d checkpoints  •  %d wrong prompts  •  %d empty-space taps" % [result.jumps,result.vaults,result.checkpoints,result.wrong_actions,result.missed_taps],17,MUTED))
	box.add_child(label("Frames above 1.5× budget: %d / %d  •  Worst frame: %.1f ms" % [result.slow_frames,result.frame_count,result.max_frame_ms],17,AMBER))
	box.add_child(label("Near-target aim uses an angular threshold; empty-space taps can be intentional. Scores depend on the full saved configuration.",15,MUTED))
	var row = HBoxContainer.new()
	box.add_child(row)
	row.add_child(button("Train again",start_session.bind(last_drill),true))
	row.add_child(button("Training menu",show_page.bind("Train")))
	row.add_child(button("Session history",show_page.bind("History")))

func edit_hud() -> void:
	save_settings()
	cleanup_world()
	clear_ui()
	state = "editing"
	ui.visible = true
	hud_backup = Profiles.data.hud.duplicate(true)
	world = Arena.new()
	world.mode = "Free Range"
	add_child(world)
	world.set_paused(true)
	hud.player = world.player
	hud.arena = world
	hud.enabled = true
	hud.editing = true
	hud.visible = true
	var top = PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 70
	top.add_theme_stylebox_override("panel",style(BG,BORDER,0))
	ui.add_child(top)
	var row = HBoxContainer.new()
	top.add_child(row)
	var title = label("HUD EDITOR  /  Drag a control to reposition it",20)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	row.add_child(button("Reset layout",func(): Profiles.data.hud = Schema.default_hud(); sync_editor(hud.selected)))
	row.add_child(button("Cancel",finish_editor.bind(false)))
	row.add_child(button("Save layout",finish_editor.bind(true),true))
	var bottom = PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -88
	bottom.add_theme_stylebox_override("panel",style(BG,BORDER,0))
	ui.add_child(bottom)
	var controls = HBoxContainer.new()
	bottom.add_child(controls)
	editor_name = label("FIRE",20,MINT)
	editor_name.custom_minimum_size.x = 160
	controls.add_child(editor_name)
	var size_label = label("Size",18,MUTED)
	size_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	controls.add_child(size_label)
	editor_size = HSlider.new()
	editor_size.min_value = 0.055
	editor_size.max_value = 0.35
	editor_size.step = 0.005
	editor_size.custom_minimum_size.x = 260
	editor_size.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	controls.add_child(editor_size)
	var alpha_label = label("Opacity",18,MUTED)
	alpha_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	controls.add_child(alpha_label)
	editor_alpha = HSlider.new()
	editor_alpha.min_value = 0.1
	editor_alpha.max_value = 1
	editor_alpha.step = 0.05
	editor_alpha.custom_minimum_size.x = 220
	editor_alpha.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	controls.add_child(editor_alpha)
	editor_visible = CheckButton.new()
	editor_visible.text = "Visible"
	controls.add_child(editor_visible)
	var select = OptionButton.new()
	for k in Profiles.data.hud: select.add_item(Hud.LABELS[k])
	select.custom_minimum_size.x = 190
	select.item_selected.connect(func(i): hud.selected = Profiles.data.hud.keys()[i]; sync_editor(hud.selected))
	controls.add_child(select)
	editor_size.value_changed.connect(func(v): if not editor_sync: Profiles.data.hud[hud.selected].size = v)
	editor_alpha.value_changed.connect(func(v): if not editor_sync: Profiles.data.hud[hud.selected].opacity = v)
	editor_visible.toggled.connect(func(v): if not editor_sync: Profiles.data.hud[hud.selected].visible = v)
	sync_editor(hud.selected)

func sync_editor(key: String) -> void:
	if state != "editing" or not is_instance_valid(editor_size): return
	editor_sync = true
	editor_name.text = Hud.LABELS[key]
	editor_size.value = Profiles.data.hud[key].size
	editor_alpha.value = Profiles.data.hud[key].opacity
	editor_visible.button_pressed = Profiles.data.hud[key].visible
	editor_sync = false

func finish_editor(keep: bool) -> void:
	if not keep: Profiles.data.hud = hud_backup.duplicate(true)
	hud.editing = false
	dirty = true
	cleanup_world()
	show_page("Train")

func _process(dt: float) -> void:
	if dirty:
		save_timer -= dt
		if save_timer<=0: save_settings()
	if state == "playing" and is_instance_valid(world):
		world.player.keyboard = Vector2(float(keys.get(KEY_D,false))-float(keys.get(KEY_A,false)),float(keys.get(KEY_S,false))-float(keys.get(KEY_W,false)))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		if event.pressed and event.keycode == KEY_ESCAPE:
			if state == "playing": pause_session()
			elif state == "paused": resume_session()
			elif state == "editing": finish_editor(false)
			else: show_page("Train")
			get_viewport().set_input_as_handled()
			return
		if state != "playing": return
		if event.pressed and event.keycode == KEY_F1:
			desktop_capture = not desktop_capture
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if desktop_capture else Input.MOUSE_MODE_VISIBLE
			hud.release_all()
			hud.enabled = not desktop_capture
			return
		keys[event.keycode] = event.pressed
		var map = {KEY_SPACE:"jump",KEY_C:"crouch",KEY_Z:"prone",KEY_Q:"lean_left",KEY_E:"lean_right",KEY_R:"reload",KEY_SHIFT:"sprint",KEY_F:"gear",KEY_V:"mantle",KEY_T:"scope",KEY_B:"breath",KEY_1:"switch",KEY_L:"flashlight"}
		if map.has(event.keycode): world.player.on_action(map[event.keycode],event.pressed)
	if state == "playing" and desktop_capture:
		if event is InputEventMouseMotion:
			world.player.on_look(event.relative / get_viewport().get_visible_rect().size.x,0)
		elif event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT: world.player.on_action("fire",event.pressed)
			if event.button_index == MOUSE_BUTTON_RIGHT: world.player.on_action("ads",event.pressed)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		pause_session()
		if is_instance_valid(ui): save_settings()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if state == "playing": pause_session()
		elif state == "paused": resume_session()
		elif state == "editing": finish_editor(false)
		else: show_page("Train")

func run_ui_capture() -> void:
	# Manual QA harness: only enabled by the explicit desktop argument.
	var destination = OS.get_environment("CLAWLAB_CAPTURE_DIR")
	if destination.is_empty(): destination = "/tmp/clawlab-captures"
	DirAccess.make_dir_recursive_absolute(destination)
	for item in ["Train","Weapon","Controls","Movement","Profiles"]:
		show_page(item)
		await get_tree().create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(destination+"/"+item.to_lower()+".png")
	start_session("Free Range")
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(destination+"/range.png")
	edit_hud()
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(destination+"/hud.png")
	finish_editor(false)
	print("UI_CAPTURE_OK")
	get_tree().quit()
