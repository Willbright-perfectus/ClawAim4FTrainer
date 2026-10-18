extends RefCounted

static func jump_speed(gravity: float, height: float) -> float:
	return sqrt(2.0 * maxf(gravity, 0.0) * maxf(height, 0.0))

static func vertical_fov(horizontal: float, aspect: float) -> float:
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(horizontal) * 0.5) / maxf(aspect, 0.1)))

static func scope_factor(aim: Dictionary, firing: bool = false, magnification: int = 0) -> float:
	var mag = int(str(aim.scope).trim_suffix("×")) if magnification == 0 else magnification
	return float(aim.get(("fire_" if firing else "") + "scope_" + str(mag), 1.0))

static func turn_gain(aim: Dictionary, ads: float, requested: bool, firing: bool = false, magnification: int = 0) -> float:
	var t = ads
	if aim.transition == "Instant":
		t = 1.0 if requested else 0.0
	elif aim.transition == "After ADS":
		t = 1.0 if ads > 0.99 else 0.0
	var hip = aim.fire_hip_turn if firing else aim.hip_turn
	var scoped = aim.fire_ads_turn if firing else aim.ads_turn
	return aim.swipe_gain * lerpf(hip, scoped * scope_factor(aim, firing, magnification), t)

static func damage(weapon: Dictionary, zone: String, distance: float, armor: float) -> float:
	var base = float(weapon.get(zone + "_damage", weapon.damage))
	var falloff = 1.0
	if distance > weapon.far_range:
		falloff = weapon.falloff_far
	elif distance > weapon.range:
		falloff = weapon.falloff_mid
	# Deliberately documented trainer armor model, NOT Delta Force's hidden formula.
	var reduction = clampf((armor - weapon.penetration) / 100.0, 0.0, 0.8)
	return base * falloff * (1.0 - reduction)

static func finite_vector(v: Vector3) -> bool:
	return is_finite(v.x) and is_finite(v.y) and is_finite(v.z)
