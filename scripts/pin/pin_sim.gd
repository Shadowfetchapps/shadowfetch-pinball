class_name PinSim
extends RefCounted

const Types = preload("res://scripts/pin/pin_types.gd")

const TABLE := Rect2(-0.52, 0.0, 1.04, 2.15)
const DRAIN := Rect2(-0.12, -0.08, 0.24, 0.12)
const BUMPERS := [
	Vector2(0.0, 1.35),
	Vector2(-0.16, 1.18),
	Vector2(0.16, 1.18),
]


static func in_table(p: Vector2) -> bool:
	return TABLE.grow(0.04).has_point(p)


static func in_drain(p: Vector2) -> bool:
	return DRAIN.has_point(p)


static func clamp_world(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, TABLE.position.x, TABLE.position.x + TABLE.size.x), clampf(p.y, -0.1, TABLE.end.y))


static func step(p: Vector2, v: Vector2, dt: float, flip_l: bool, flip_r: bool) -> Dictionary:
	v.y -= 2.8 * dt
	if flip_l and p.x < 0.0 and p.y < 0.28:
		v += Vector2(1.6, 4.2)
	if flip_r and p.x > 0.0 and p.y < 0.28:
		v += Vector2(-1.6, 4.2)
	for b in BUMPERS:
		if p.distance_to(b) < 0.09:
			var n: Vector2 = (p - b).normalized()
			v += n * 3.4
	p += v * dt
	if p.x < TABLE.position.x:
		p.x = TABLE.position.x
		v.x = absf(v.x) * 0.72
	if p.x > TABLE.end.x:
		p.x = TABLE.end.x
		v.x = -absf(v.x) * 0.72
	if p.y > TABLE.end.y:
		p.y = TABLE.end.y
		v.y = -absf(v.y) * 0.6
	if v.length() > 14.0:
		v = v.limit_length(14.0)
	var escaped := not in_table(p) and not in_drain(p) and p.y < -0.12
	if escaped:
		p = Vector2(0.0, 0.42)
		v = Vector2.ZERO
	return {"p": p, "v": v, "drain": in_drain(p), "escaped": escaped, "nan": is_nan(p.x) or is_nan(v.x)}
