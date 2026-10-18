extends RefCounted
## All unsourced physical constants are editable trainer approximations.
## Each field is [key, label, default, min, max, step] or [key, label, default, choices].

const VERSION = 1
const GROUPS = {
	"weapon": [
		["name", "Weapon / loadout name", "M14 • Willbright"],
		["damage", "Unarmored chest damage", 39.0, 1, 300, 0.1],
		["head_damage", "Head damage", 74.0, 1, 600, 0.1],
		["abdomen_damage", "Abdomen damage", 35.0, 1, 400, 0.1],
		["limb_damage", "Limb damage", 15.0, 1, 400, 0.1],
		["penetration", "Armor penetration rating (trainer model)", 41.0, 0, 100, 1],
		["range", "First damage falloff distance · m", 52.0, 1, 250, 1],
		["far_range", "Second falloff distance · m", 100.0, 2, 500, 1],
		["falloff_mid", "Middle-distance damage multiplier", 0.8, 0.01, 1, 0.01],
		["falloff_far", "Long-distance damage multiplier", 0.7, 0.01, 1, 0.01],
		["rpm", "Fire rate · rounds/min", 727.0, 30, 1800, 1],
		["magazine", "Magazine capacity", 30.0, 1, 200, 1],
		["mode", "Fire selector", "Auto", ["Auto", "Single", "Burst"]],
		["burst_count", "Shots per burst", 3.0, 2, 10, 1],
		["velocity", "Muzzle velocity · m/s", 680.0, 30, 2000, 1],
		["bullet_gravity", "Projectile gravity · m/s² (approximation)", 9.81, 0, 30, 0.01],
		["ads_ms", "ADS transition · ms", 308.0, 0, 1500, 1],
		["sprint_fire_ms", "Sprint-to-fire delay · ms", 184.0, 0, 1500, 1],
		["reload", "Tactical reload · seconds", 2.7, 0.1, 15, 0.01],
		["empty_reload", "Empty reload · seconds", 3.11, 0.1, 15, 0.01],
		["holster", "Holster time · seconds", 0.43, 0, 3, 0.01],
		["switch_time", "Weapon draw time · seconds", 0.5, 0, 3, 0.01],
		["vertical_recoil", "Full-auto vertical recoil multiplier", 0.52, 0, 3, 0.01],
		["horizontal_recoil", "Full-auto horizontal recoil multiplier", 0.68, 0, 3, 0.01],
		["single_vertical", "Single / burst vertical multiplier", 0.52, 0, 3, 0.01],
		["single_horizontal", "Single / burst horizontal multiplier", 0.68, 0, 3, 0.01],
		["base_kick", "Base vertical recoil · degrees/shot (approx.)", 0.58, 0, 5, 0.01],
		["horizontal_kick", "Base horizontal recoil · degrees/shot (approx.)", 0.24, 0, 4, 0.01],
		["recoil_random", "Recoil randomness · degrees (approx.)", 0.08, 0, 2, 0.01],
		["recovery", "Recoil recovery · degrees/second (approx.)", 2.2, 0, 20, 0.1],
		["recovery_delay", "Recoil recovery delay · seconds (approx.)", 0.16, 0, 2, 0.01],
		["firing_stability", "Firing stability multiplier", 0.82, 0, 3, 0.01],
		["sway", "Breath sway range · degrees", 0.33, 0, 5, 0.01],
		["sway_hz", "Sway frequency · Hz (approx.)", 0.65, 0.05, 3, 0.05],
		["breath_duration", "Breath-hold duration · seconds", 24.17, 0.1, 120, 0.01],
		["breath_recoil", "Breath-hold recoil multiplier", 0.91, 0, 2, 0.01],
		["flinch", "Hit flinch multiplier", 0.8, 0, 3, 0.01],
		["movement_stability", "Movement stability multiplier", 0.93, 0, 3, 0.01],
		["sight_stability", "Sight stability while firing", 0.74, 0, 3, 0.01],
		["hip_spread", "Standing hip-fire spread · degrees", 3.46, 0, 20, 0.01],
		["max_spread", "Maximum hip-fire spread · degrees", 8.58, 0, 35, 0.01],
		["ads_spread", "ADS spread · degrees (approx.)", 0.07, 0, 5, 0.01],
		["spread_growth", "Spread growth per shot · degrees (approx.)", 0.32, 0, 4, 0.01],
		["spread_recovery", "Spread recovery · degrees/sec (approx.)", 3.0, 0, 20, 0.1],
		["air_spread", "Airborne spread multiplier (approx.)", 1.8, 1, 5, 0.05],
		["crouch_spread", "Crouched spread multiplier (approx.)", 0.8, 0.1, 2, 0.05],
		["prone_spread", "Prone spread multiplier (approx.)", 0.6, 0.1, 2, 0.05]
	],
	"aim": [
		["fov", "Horizontal field of view · degrees", 94.0, 60, 120, 1],
		["hip_turn", "Hip turn · degrees per full-width swipe", 240.0, 30, 1080, 1],
		["ads_turn", "ADS 1× turn · degrees per full-width swipe", 135.0, 10, 720, 1],
		["vertical", "Vertical sensitivity multiplier", 1.0, 0.1, 3, 0.01],
		["scope", "Scope magnification", "1×", ["1×", "2×", "3×", "4×", "6×", "8×"]],
		["scope_2", "2× sensitivity multiplier", 0.65, 0.05, 3, 0.01],
		["scope_3", "3× sensitivity multiplier", 0.45, 0.05, 3, 0.01],
		["scope_4", "4× sensitivity multiplier", 0.35, 0.05, 3, 0.01],
		["scope_6", "6× sensitivity multiplier", 0.24, 0.05, 3, 0.01],
		["scope_8", "8× sensitivity multiplier", 0.18, 0.05, 3, 0.01],
		["transition", "Sensitivity transition", "Instant", ["Instant", "After ADS", "Gradual"]],
		["acceleration", "Touch acceleration", false],
		["accel_strength", "Acceleration strength (trainer curve)", 0.35, 0, 2, 0.05],
		["gyro", "Gyroscope", "Off", ["Off", "ADS only", "Always"]],
		["gyro_gain", "Gyroscope multiplier", 1.0, 0.1, 5, 0.05],
		["gyro_invert_x", "Invert gyro horizontal", false],
		["gyro_invert_y", "Invert gyro vertical", false],
		["gyro_swap", "Swap gyro axes", false],
		["assist", "Aim slowdown (trainer approximation)", false],
		["assist_strength", "Aim slowdown strength", 0.25, 0, 0.8, 0.05],
		["reticle", "Crosshair style", "Cross", ["Cross", "Dot", "Circle"]],
		["reticle_size", "Crosshair size", 13.0, 2, 35, 1],
		["reticle_color", "Crosshair color", "Mint", ["Mint", "White", "Amber", "Pink"]]
	],
	"controls": [
		["mode", "Game-mode profile", "Operations", ["Operations", "Warfare"]],
		["ads_mode", "ADS input", "Hold", ["Hold", "Press", "Hybrid"]],
		["lean_mode", "Lean input", "Hold", ["Hold", "Press", "Hybrid"]],
		["lean_enabled", "Enable leaning", true],
		["lean_ads", "Leaning requests ADS", true],
		["ads_lean", "Restore previous lean when ADS starts", true],
		["quick_ads_ops", "Operations: fire requests ADS", false],
		["quick_ads_war", "Warfare: fire requests ADS", true],
		["release_fire", "Single shot on release", false],
		["auto_breath", "Hold breath automatically in ADS", true],
		["cancel_ads_sprint", "Sprint cancels ADS", true],
		["cancel_ads_reload", "Reload cancels ADS", false],
		["reload_cancel", "Reload cancellation input", "Hybrid", ["Off", "Reload", "Fire", "Hybrid"]],
		["auto_reload", "Reload automatically when empty", true],
		["stance_sprint", "Sprint exits crouch / prone", true],
		["combined_stance", "Tap crouch / hold prone", false],
		["hybrid_ms", "Hybrid / long press threshold · ms", 240.0, 100, 700, 10],
		["tactical_stick", "Warfare: full stick activates tactical sprint", true],
		["quick_throw", "Equipment use", "Quick throw", ["Quick throw", "Handheld"]],
		["turn_fire", "Turn camera with fire button", false],
		["turn_ads", "Turn camera with ADS button", false],
		["turn_lean", "Turn camera with lean buttons", false],
		["turn_jump", "Turn camera with jump button", true],
		["turn_crouch", "Turn camera with crouch button", false],
		["turn_prone", "Turn camera with prone button", false],
		["turn_gear", "Turn camera with equipment buttons", true],
		["touch_trails", "Show touch feedback", false],
		["sound", "Training sound effects", true]
	],
	"movement": [
		["walk", "Walk speed · m/s", 3.32, 0.2, 12, 0.01],
		["sprint", "Sprint speed · m/s", 5.9, 0.2, 18, 0.1],
		["ads_walk", "ADS movement speed · m/s", 1.9, 0.1, 10, 0.01],
		["crouch", "Crouch speed · m/s (approx.)", 1.65, 0.1, 8, 0.05],
		["prone", "Prone crawl speed · m/s (approx.)", 0.75, 0.1, 5, 0.05],
		["silent", "Silent walk speed · m/s (approx.)", 1.25, 0.1, 5, 0.05],
		["tactical", "Tactical sprint multiplier (approx.)", 1.15, 1, 2, 0.01],
		["acceleration", "Ground acceleration · m/s² (approx.)", 22.0, 2, 70, 0.5],
		["air_control", "Air control fraction (approx.)", 0.18, 0, 1, 0.01],
		["gravity", "Character gravity · m/s² (approx.)", 18.0, 5, 40, 0.1],
		["jump_height", "Jump height · m (approx.)", 0.75, 0.15, 2, 0.01],
		["jump_cooldown", "Jump cooldown · seconds (approx.)", 0.25, 0, 2, 0.01],
		["repeat_jump_penalty", "Repeat-jump height penalty (approx.)", 0.12, 0, 0.4, 0.01],
		["stance_time", "Crouch transition · seconds (approx.)", 0.2, 0.05, 1, 0.01],
		["prone_time", "Prone transition · seconds (approx.)", 0.38, 0.05, 1.5, 0.01],
		["lean_distance", "Lean camera offset · m (approx.)", 0.23, 0, 0.45, 0.01],
		["lean_angle", "Lean angle · degrees (approx.)", 9.0, 0, 20, 0.5],
		["lean_time", "Lean transition · seconds (approx.)", 0.13, 0.03, 0.6, 0.01],
		["mantle", "Allow mantling", true],
		["auto_mantle", "Automatically mantle while moving forward", false],
		["mantle_height", "Maximum mantle height · m (approx.)", 1.25, 0.3, 2, 0.05],
		["mantle_time", "Mantle duration · seconds (approx.)", 0.6, 0.2, 1.5, 0.05],
		["dive", "Warfare: sprint + prone dives", true],
		["dive_speed", "Dive speed multiplier (approx.)", 1.15, 0.5, 2, 0.05],
		["stamina", "Enable stamina", true],
		["stamina_drain", "Sprint stamina drain · fraction/sec (approx.)", 0.06, 0, 0.4, 0.01],
		["stamina_recovery", "Stamina recovery · fraction/sec (approx.)", 0.15, 0.01, 0.5, 0.01],
		["jump_cost", "Jump stamina cost (approx.)", 0.12, 0, 0.5, 0.01]
	],
	"drill": [
		["duration", "Session duration · seconds", 60.0, 15, 600, 15],
		["distance", "Target distance · m", 20.0, 5, 75, 1],
		["speed", "Target movement speed · m/s", 2.4, 0, 8, 0.1],
		["size", "Target size multiplier", 1.0, 0.3, 2, 0.05],
		["health", "Target health", 100.0, 1, 1000, 1],
		["armor", "Target armor rating (trainer model)", 0.0, 0, 100, 1],
		["flinch_interval", "Simulated incoming-hit interval · sec (0 = off)", 0.0, 0, 15, 0.5],
		["infinite_ammo", "Unlimited magazine", false],
		["seed", "Repeatable drill seed", 42.0, 1, 999999, 1],
		["target_pattern", "Moving target pattern", "Strafe", ["Strafe", "Unpredictable", "Sine"]]
	],
	"performance": [
		["fps", "Frame-rate limit", "60", ["30", "60", "90", "120"]],
		["render_scale", "3D rendering resolution", 0.85, 0.5, 1, 0.05],
		["tracers", "Show projectile tracers", true],
		["show_fps", "Show frame-rate / frame-time counter", true]
	]
}

static func defaults() -> Dictionary:
	var d = {"schema_version": VERSION, "profile_name": "Willbright M14", "hud": default_hud()}
	for group in GROUPS:
		d[group] = {}
		for f in GROUPS[group]:
			d[group][f[0]] = f[2]
	return d

static func default_hud() -> Dictionary:
	var positions = {
		"fire": [0.17, 0.23, 0.24], "move": [0.18, 0.76, 0.25],
		"lean_left": [0.80, 0.12, 0.14], "lean_right": [0.90, 0.12, 0.14],
		"jump": [0.80, 0.30, 0.14], "ads": [0.90, 0.30, 0.14],
		"crouch": [0.80, 0.48, 0.14], "prone": [0.90, 0.48, 0.14],
		"reload": [0.29, 0.29, 0.115], "scope": [0.35, 0.16, 0.09],
		"breath": [0.34, 0.43, 0.10], "sprint": [0.18, 0.55, 0.105],
		"gear": [0.85, 0.70, 0.13], "gadget": [0.73, 0.85, 0.12],
		"flashlight": [0.63, 0.86, 0.09], "switch": [0.54, 0.88, 0.10],
		"silent": [0.30, 0.71, 0.09], "mantle": [0.69, 0.46, 0.09]
	}
	var d = {}
	for k in positions:
		var p = positions[k]
		d[k] = {"x": p[0], "y": p[1], "size": p[2], "opacity": 0.68, "visible": true}
	return d

static func sanitize(raw: Variant) -> Dictionary:
	var d = defaults()
	if not raw is Dictionary:
		return d
	d.profile_name = str(raw.get("profile_name", d.profile_name)).substr(0, 64)
	for group in GROUPS:
		if not raw.get(group) is Dictionary:
			continue
		for f in GROUPS[group]:
			var v = raw[group].get(f[0], f[2])
			if f[2] is bool:
				d[group][f[0]] = v if v is bool else f[2]
			elif f.size() == 6:
				if (v is float or v is int) and is_finite(float(v)):
					d[group][f[0]] = clampf(float(v), f[3], f[4])
			elif f.size() == 4:
				d[group][f[0]] = v if v in f[3] else f[2]
			else:
				d[group][f[0]] = str(v).substr(0, 64)
	d.weapon.far_range = maxf(d.weapon.range + 1.0, d.weapon.far_range)
	d.weapon.max_spread = maxf(d.weapon.hip_spread, d.weapon.max_spread)
	d.weapon.magazine = roundf(d.weapon.magazine)
	d.weapon.burst_count = roundf(d.weapon.burst_count)
	if raw.get("hud") is Dictionary:
		for k in d.hud:
			var h = raw.hud.get(k, {})
			if not h is Dictionary:
				continue
			for prop in ["x", "y", "size", "opacity"]:
				var v = h.get(prop, d.hud[k][prop])
				if (v is float or v is int) and is_finite(float(v)):
					var lo = 0.055 if prop == "size" else 0.1 if prop == "opacity" else 0.03
					var hi = 0.35 if prop == "size" else 1.0 if prop == "opacity" else 0.97
					d.hud[k][prop] = clampf(v, lo, hi)
			if h.get("visible") is bool:
				d.hud[k].visible = h.visible
	return d
