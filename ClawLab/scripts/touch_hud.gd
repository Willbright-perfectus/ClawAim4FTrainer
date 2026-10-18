extends Control

signal action_event(action: String, down: bool)
signal look_motion(delta: Vector2, speed: float)
signal move_motion(value: Vector2)
signal pause_requested
signal editor_selected(action: String)

const MINT = Color("57dfbc")
const WHITE = Color("e2edf0")
const LABELS = {"fire":"FIRE", "move":"MOVE", "ads":"ADS", "jump":"JUMP", "crouch":"CROUCH", "prone":"PRONE", "reload":"RELOAD", "scope":"SCOPE", "breath":"BREATH", "lean_left":"LEFT", "lean_right":"RIGHT", "sprint":"SPRINT", "gear":"GEAR", "gadget":"GADGET", "switch":"SWITCH", "flashlight":"LIGHT", "silent":"SILENT", "mantle":"VAULT"}

var enabled = false
var editing = false
var selected = "fire"
var contacts: Dictionary = {}
var held: Dictionary = {}
var trails: Array = []
var look_id = -999
var move_id = -999
var joystick = Vector2.ZERO
var player: Node = null
var arena: Node = null
var hit_flash = 0.0
var toast = ""
var toast_time = 0.0
var total_misses = 0
var peak_touches = 0
var frame_ms = 16.7
var font: Font
var pause_style: StyleBoxFlat

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font
	pause_style = panel_style()

func release_all() -> void:
	for k in held:
		if held[k] > 0:
			action_event.emit(k, false)
	held.clear()
	contacts.clear()
	look_id = -999
	move_id = -999
	joystick = Vector2.ZERO
	move_motion.emit(joystick)

func layout_rect() -> Rect2:
	if editing:
		var factor = (size.y-178.0)/maxf(size.y,1.0)
		var extent = size*factor
		return Rect2(Vector2((size.x-extent.x)*0.5,82),extent)
	return Rect2(Vector2.ZERO,size)

func button_center(k: String) -> Vector2:
	var h = Profiles.data.hud[k]
	var area = layout_rect()
	return area.position + Vector2(h.x * area.size.x, h.y * area.size.y)

func button_radius(k: String) -> float:
	return Profiles.data.hud[k].size * layout_rect().size.y * 0.5

func hit_button(p: Vector2) -> String:
	var best = ""
	var nearest = INF
	for k in Profiles.data.hud:
		var h = Profiles.data.hud[k]
		if not h.visible and not editing:
			continue
		var d = p.distance_to(button_center(k)) / button_radius(k)
		if d <= 1.0 and d < nearest:
			best = k
			nearest = d
	return best

func _input(event: InputEvent) -> void:
	if not enabled:
		return
	# Built-in menu widgets need touch-to-mouse emulation. The game HUD handles
	# real touch IDs itself, so ignore that synthetic mouse duplicate (device -1).
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device == -1:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			pointer_down(event.index, event.position)
		else:
			pointer_up(event.index)
	elif event is InputEventScreenDrag:
		pointer_move(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pointer_down(1000, event.position)
		else:
			pointer_up(1000)
	elif event is InputEventMouseMotion and contacts.has(1000):
		pointer_move(1000, event.position)

func pointer_down(id: int, p: Vector2) -> void:
	if contacts.has(id):
		pointer_up(id)
	if editing and (p.y < 70 or p.y > size.y - 88):
		return
	if not editing and Rect2(size.x - 105, 10, 90, 40).has_point(p):
		release_all()
		pause_requested.emit()
		return
	var key = hit_button(p)
	var now = Time.get_ticks_usec()
	contacts[id] = {"key":key, "start":p, "last":p, "time":now, "at":now}
	peak_touches = maxi(peak_touches, contacts.size())
	if editing:
		if not key.is_empty():
			selected = key
			editor_selected.emit(key)
		return
	if key.is_empty():
		# A dedicated aiming contact takes priority over action-button camera turning.
		look_id = id
	elif key == "move":
		if move_id == -999:
			move_id = id
			update_joystick(p)
	else:
		held[key] = int(held.get(key,0)) + 1
		if held[key] == 1:
			action_event.emit(key, true)
		if look_id == -999 and allows_turn(key):
			look_id = id
	add_trail(p, key)
	queue_redraw()

func pointer_move(id: int, p: Vector2) -> void:
	if not contacts.has(id):
		return
	var c = contacts[id]
	var key = str(c.key)
	if editing:
		if not key.is_empty():
			var h = Profiles.data.hud[key]
			var area = layout_rect()
			var margin = h.size * area.size.y * 0.5
			var local = p-area.position
			h.x = clampf(local.x,margin,area.size.x-margin)/area.size.x
			h.y = clampf(local.y,margin,area.size.y-margin)/area.size.y
	elif key == "move":
		if move_id == id:
			update_joystick(p)
	elif look_id == id:
		var delta = (p - c.last) / maxf(size.x,1.0)
		var dt = maxf((Time.get_ticks_usec() - int(c.time)) / 1000000.0, 0.001)
		look_motion.emit(delta, minf(delta.length() / dt, 8.0))
	c.last = p
	c.time = Time.get_ticks_usec()
	queue_redraw()

func pointer_up(id: int) -> void:
	if not contacts.has(id):
		return
	var c = contacts[id]
	var key = str(c.key)
	if not editing:
		if key == "move":
			if move_id == id:
				move_id = -999
				joystick = Vector2.ZERO
				move_motion.emit(joystick)
		elif not key.is_empty():
			held[key] = maxi(0, int(held.get(key,0))-1)
			if held[key] == 0:
				action_event.emit(key, false)
		elif c.start.distance_to(c.last) < 8 and Time.get_ticks_usec() - int(c.at) < 250000:
			total_misses += 1
	contacts.erase(id)
	if move_id == -999 and not editing:
		for other in contacts:
			if contacts[other].key == "move":
				move_id = other
				update_joystick(contacts[other].last)
				break
	if look_id == id:
		look_id = -999
		for other in contacts:
			if contacts[other].key == "" or allows_turn(contacts[other].key):
				look_id = other
				break
	queue_redraw()

func allows_turn(key: String) -> bool:
	var k = key
	if key in ["lean_left", "lean_right"]:
		k = "lean"
	if key == "gadget":
		k = "gear"
	return bool(Profiles.data.controls.get("turn_" + k, false))

func update_joystick(p: Vector2) -> void:
	joystick = ((p - button_center("move")) / maxf(button_radius("move") * Profiles.data.controls.joystick_reach,1.0)).limit_length(1.0)
	if joystick.length() < 0.08:
		joystick = Vector2.ZERO
	move_motion.emit(joystick)

func add_trail(p: Vector2, key: String) -> void:
	trails.append({"p":p,"key":key,"life":1.2})
	if trails.size() > 64:
		trails.pop_front()

func notify(text: String) -> void:
	toast = text
	toast_time = 2.2

func _process(dt: float) -> void:
	if not visible:
		return
	frame_ms = lerpf(frame_ms, dt*1000.0, 0.06)
	hit_flash = maxf(0, hit_flash - dt)
	toast_time = maxf(0, toast_time - dt)
	for t in trails:
		t.life -= dt
	while not trails.is_empty() and trails[0].life <= 0:
		trails.pop_front()
	queue_redraw()

func text_at(p: Vector2, text: String, color: Color = WHITE, fs: int = 16, centered: bool = false) -> void:
	if centered:
		p.x -= font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x * 0.5
	draw_string(font,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,color)

func _draw() -> void:
	if font == null:
		return
	if not editing and player != null and player.ads > 0.85 and player.magnification() >= 2:
		draw_scope()
	if editing:
		draw_rect(Rect2(Vector2.ZERO,size), Color(0.02,0.04,0.06,0.8))
		var area = layout_rect()
		draw_rect(area,Color("344f5b"),false,1)
		for i in range(1,10):
			draw_line(area.position+Vector2(i*area.size.x/10,0),area.position+Vector2(i*area.size.x/10,area.size.y),Color(0.3,0.5,0.6,0.12))
		for j in range(1,7):
			draw_line(area.position+Vector2(0,j*area.size.y/7),area.position+Vector2(area.size.x,j*area.size.y/7),Color(0.3,0.5,0.6,0.12))
	for k in Profiles.data.hud:
		var h = Profiles.data.hud[k]
		if not h.visible and not editing:
			continue
		var p = button_center(k)
		var r = button_radius(k)
		var active = int(held.get(k,0)) > 0 or (editing and selected == k)
		var alpha = h.opacity if h.visible else 0.23
		draw_circle(p,r,Color(0.025,0.06,0.08,alpha * 0.75))
		draw_arc(p,r,0,TAU,40,Color(MINT if active else Color("839ba5"),alpha),2 if active else 1,true)
		if k == "move":
			draw_circle(p + joystick * r * 0.6, r * 0.28, Color(MINT,alpha*0.8))
			draw_arc(p,r*0.65,0,TAU,32,Color(WHITE,0.1),1,true)
		elif k == "reload" and not editing and player != null and player.reload_left > 0:
			var progress = 1.0 - player.reload_left / maxf(player.reload_total,0.001)
			draw_arc(p,r*0.84,-PI/2,-PI/2+TAU*progress,48,MINT,3,true)
			text_at(p+Vector2(0,r*0.08),"%.1fs" % player.reload_left,WHITE,int(clampf(r*0.46,12,25)),true)
			text_at(p+Vector2(0,r*0.57),"RELOAD",MINT,int(clampf(r*0.24,9,13)),true)
		else:
			draw_icon(k,p+Vector2(0,-r*0.12),r*0.38,Color(WHITE,alpha))
			var caption = LABELS[k]
			if not editing and player != null:
				if k == "scope": caption = "%d×" % player.magnification()
				elif k == "switch": caption = "M14" if player.weapon_slot == "Pistol" else "PISTOL"
				elif k == "reload" and player.weapon_slot == "Pistol": caption = "∞"
			text_at(p+Vector2(0,r*0.56), caption, Color(WHITE,alpha), int(clampf(r*0.27,10,15)),true)
	if editing:
		text_at(size*0.5, "Drag any control • Select a button to adjust it", Color("7e9ba5"),19,true)
		return
	var center = size * 0.5
	var a = Profiles.data.aim
	var color = {"Mint":MINT,"White":WHITE,"Amber":Color("ffb46d"),"Pink":Color("f28fbd")}[a.reticle_color]
	var cr = float(a.reticle_size)
	if a.reticle == "Dot":
		draw_circle(center,maxf(cr*0.22,2),color)
	elif a.reticle == "Circle":
		draw_arc(center,cr,0,TAU,48,color,1.5,true)
	else:
		for dir in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
			draw_line(center+dir*4,center+dir*cr,color,1.6,true)
	if hit_flash > 0:
		for dir in [Vector2(1,1),Vector2(-1,1),Vector2(1,-1),Vector2(-1,-1)]:
			draw_line(center+dir*8,center+dir*15,Color("ffbd79"),2,true)
	var pause_rect = Rect2(size.x-105,10,90,40)
	draw_style_box(pause_style,pause_rect)
	text_at(pause_rect.position+Vector2(45,26),"PAUSE",WHITE,15,true)
	if player != null:
		text_at(Vector2(size.x*0.5,27),"%s   /   %s" % [player.weapon().name,Profiles.data.controls.mode],WHITE,17,true)
		var ammo = "∞  SINGLE / NO RELOAD" if player.weapon_slot == "Pistol" else "%s / %d" % ["∞" if player.unlimited_ammo() else str(player.ammo),player.weapon().magazine]
		text_at(Vector2(size.x*0.5,size.y-22),"%s    %s    %s" % [ammo,player.stance.to_upper(),player.state_label()],WHITE,16,true)
		var bw = 150.0
		draw_rect(Rect2(size.x*0.5-bw/2,size.y-48,bw,4),Color(0.2,0.3,0.34,0.7))
		draw_rect(Rect2(size.x*0.5-bw/2,size.y-48,bw*player.stamina,4),MINT)
	if arena != null:
		var remaining = maxi(0,int(ceil(arena.remaining)))
		text_at(Vector2(size.x*0.5,51),"%s    %02d:%02d    %d HITS    %.1f%%" % [arena.drill_name, remaining/60,remaining%60,arena.hits,arena.accuracy()],MINT,16,true)
		if not arena.prompt.is_empty():
			text_at(Vector2(size.x*0.5,size.y*0.20),arena.prompt,Color("ffc285"),21,true)
	if Profiles.data.performance.show_fps:
		text_at(Vector2(16,27),"%d FPS  ·  %.1f ms" % [Engine.get_frames_per_second(),frame_ms],Color("aec4cc"),14)
	if Profiles.data.controls.touch_trails:
		for t in trails:
			draw_circle(t.p,8,Color(MINT,clampf(t.life,0,0.8)))
		for id in contacts:
			draw_arc(contacts[id].last,20,0,TAU,24,MINT,1.5)
	if toast_time > 0:
		text_at(Vector2(size.x*0.5,size.y*0.70),toast,Color("ffcb91"),18,true)

func draw_scope() -> void:
	var c = size*0.5
	var radius = size.y*0.36
	# Shade outside the optic with a single bounded triangle strip, then draw
	# the rim and fine reticle. HUD buttons render afterward and stay readable.
	for i in range(64):
		var a = TAU*i/64.0
		var b = TAU*(i+1)/64.0
		var va = Vector2(cos(a),sin(a))
		var vb = Vector2(cos(b),sin(b))
		draw_colored_polygon(PackedVector2Array([c+va*radius,c+va*size.length(),c+vb*size.length(),c+vb*radius]),Color(0.015,0.025,0.035,0.88))
	draw_arc(c,radius,0,TAU,96,Color("39535e"),8,true)
	draw_arc(c,radius-6,0,TAU,96,Color("8cc7c0"),1,true)
	for dir in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		draw_line(c+dir*18,c+dir*(radius-10),Color(0.03,0.06,0.07,0.85),1.5,true)
		for tick in range(1,5):
			var at = c+dir*(radius*tick/6.0)
			var side = Vector2(-dir.y,dir.x)*4
			draw_line(at-side,at+side,Color("364a50"),1,true)
	text_at(c+Vector2(0,radius-22),"M14  •  %d×" % player.magnification(),MINT,16,true)

func panel_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.03,0.07,0.1,0.88)
	s.set_corner_radius_all(8)
	return s

func draw_icon(key: String, p: Vector2, r: float, col: Color) -> void:
	match key:
		"fire":
			draw_line(p+Vector2(-r,r),p+Vector2(r,-r),col,5,true)
			draw_circle(p+Vector2(r,-r),r*0.25,col)
		"ads", "scope":
			draw_arc(p,r,0,TAU,24,col,2,true)
			draw_line(p+Vector2(-r*1.4,0),p+Vector2(r*1.4,0),col,1.5,true)
			draw_line(p+Vector2(0,-r*1.4),p+Vector2(0,r*1.4),col,1.5,true)
		"lean_left", "lean_right":
			var side = -1 if key == "lean_left" else 1
			draw_circle(p+Vector2(side*r*0.4,-r*0.65),r*0.25,col)
			draw_line(p+Vector2(side*r*0.3,-r*0.3),p+Vector2(-side*r*0.2,r*0.7),col,4,true)
			draw_line(p+Vector2(-side*r*0.2,r*0.7),p+Vector2(side*r*0.6,r*0.7),col,3,true)
		"prone":
			draw_circle(p+Vector2(r*0.8,-r*0.2),r*0.23,col)
			draw_line(p+Vector2(-r,r*0.3),p+Vector2(r*0.6,0),col,4,true)
		"crouch":
			draw_circle(p+Vector2(0,-r*0.7),r*0.25,col)
			draw_polyline(PackedVector2Array([p+Vector2(0,-r*0.4),p+Vector2(-r*0.3,r*0.1),p+Vector2(r*0.5,r*0.4),p+Vector2(r*0.15,r)]),col,3,true)
		"jump", "mantle", "sprint":
			draw_polyline(PackedVector2Array([p+Vector2(-r,0),p+Vector2(0,-r),p+Vector2(r,0)]),col,3,true)
			draw_line(p+Vector2(0,-r),p+Vector2(0,r),col,3,true)
		"reload", "switch":
			draw_arc(p,r,0.2,TAU-0.6,24,col,2.5,true)
			draw_line(p+Vector2(r,0),p+Vector2(r*0.5,-r*0.3),col,3,true)
		"flashlight":
			draw_rect(Rect2(p-Vector2(r*0.5,r*0.4),Vector2(r,r*0.8)),col)
			for i in [-1,0,1]:
				draw_line(p+Vector2(r*0.7,i*r*0.35),p+Vector2(r*1.3,i*r*0.6),col,1.5,true)
		"breath":
			draw_arc(p+Vector2(-r*0.4,0),r*0.55,0,TAU,20,col,2,true)
			draw_arc(p+Vector2(r*0.4,0),r*0.55,0,TAU,20,col,2,true)
		_:
			draw_arc(p,r*0.8,0,TAU,6,col,2,true)
			draw_circle(p,r*0.2,col)
