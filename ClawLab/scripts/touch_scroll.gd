extends ScrollContainer
## Own vertical touch gestures before child buttons consume them. Taps still
## use native controls; a recognized drag cancels the button and its release.
const DEADZONE = 12.0
var finger = -1
var start = Vector2.ZERO
var last = Vector2.ZERO
var origin_scroll = 0.0
var dragging = false
var speed = 0.0
var last_time = 0
var suppress_mouse_until = 0

func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_deadzone = int(DEADZONE)
	get_v_scroll_bar().custom_minimum_size.x = 16

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		reset_gesture()
		return
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1 and get_global_rect().has_point(event.position):
			var bar = get_v_scroll_bar()
			if bar.visible and bar.get_global_rect().has_point(event.position): return
			finger = event.index
			start = event.position
			last = start
			origin_scroll = scroll_vertical
			last_time = Time.get_ticks_usec()
			speed = 0
			dragging = false
		elif not event.pressed and event.index == finger:
			if dragging:
				get_viewport().set_input_as_handled()
				suppress_mouse_until = Time.get_ticks_msec() + 80
				propagate_notification(Control.NOTIFICATION_SCROLL_END)
				if Time.get_ticks_usec()-last_time > 100000: speed = 0
			finger = -1
			dragging = false
	elif event is InputEventScreenDrag and event.index == finger:
		var displacement = event.position-start
		if not dragging and absf(displacement.y) >= DEADZONE and absf(displacement.y) > absf(displacement.x)*0.7:
			dragging = true
			propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
		if dragging:
			get_viewport().set_input_as_handled()
			var now = Time.get_ticks_usec()
			var dt = clampf((now-last_time)/1000000.0,0.008,0.1)
			speed = clampf((last.y-event.position.y)/dt,-1600,1600)
			scroll_vertical = int(origin_scroll-displacement.y)
			last_time = now
			last = event.position
	elif (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device == -1:
		if dragging or Time.get_ticks_msec() < suppress_mouse_until:
			get_viewport().set_input_as_handled()

func _process(dt: float) -> void:
	if finger >= 0 or absf(speed) < 5 or not is_visible_in_tree(): return
	var before = scroll_vertical
	scroll_vertical += int(speed*minf(dt,0.05))
	speed = move_toward(speed,0,3600*dt)
	if scroll_vertical == before: speed = 0

func reset_gesture() -> void:
	finger = -1
	dragging = false
	speed = 0

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		reset_gesture()
