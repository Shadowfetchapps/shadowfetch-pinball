class_name PinTable
extends Node3D

const Types = preload("res://scripts/pin/pin_types.gd")

signal scored(kind, ball_id, key)

const BALL_R := 0.027

var flip_l: AnimatableBody3D
var flip_r: AnimatableBody3D
var _ang_l := -0.48
var _ang_r := 0.48
var _lights: Array[OmniLight3D] = []


func _ready() -> void:
	_room()
	_playfield()
	_walls()
	_flippers()
	_bumpers()
	_slings()
	_targets()
	_lanes()
	_ramp()
	_lock()
	_drain()
	_plunger_lane()


func make_ball() -> RigidBody3D:
	var ball := RigidBody3D.new()
	ball.mass = 0.16
	ball.continuous_cd = true
	ball.linear_damp = 0.18
	ball.angular_damp = 0.2
	ball.can_sleep = false
	ball.contact_monitor = true
	ball.max_contacts_reported = 8
	var mesh_i := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = BALL_R
	sph.height = BALL_R * 2.0
	mesh_i.mesh = sph
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.78, 0.82, 0.9)
	mat.metallic = 0.72
	mat.roughness = 0.18
	mat.emission_enabled = true
	mat.emission = Color(0.25, 0.45, 0.7)
	mat.emission_energy_multiplier = 0.6
	mesh_i.material_override = mat
	ball.add_child(mesh_i)
	var col := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = BALL_R
	col.shape = sh
	ball.add_child(col)
	var phys := PhysicsMaterial.new()
	phys.bounce = 0.42
	phys.friction = 0.12
	ball.physics_material_override = phys
	return ball


func drive_flippers(left: bool, right: bool, dt: float) -> void:
	var target_l := 0.62 if left else -0.48
	var target_r := -0.62 if right else 0.48
	_ang_l = lerpf(_ang_l, target_l, 1.0 - exp(-dt * 28.0))
	_ang_r = lerpf(_ang_r, target_r, 1.0 - exp(-dt * 28.0))
	if flip_l:
		flip_l.rotation.y = _ang_l
	if flip_r:
		flip_r.rotation.y = _ang_r


func pulse(mission_name: String) -> void:
	var c := Color(0.4, 0.8, 1.0)
	if mission_name.contains("FETCH"):
		c = Color(0.55, 0.95, 0.7)
	elif mission_name.contains("OVERLOAD"):
		c = Color(1.0, 0.45, 0.25)
	elif mission_name.contains("NIGHT"):
		c = Color(0.45, 0.35, 1.0)
	elif mission_name.contains("JACKPOT") or mission_name.contains("COMPLETE"):
		c = Color(1.0, 0.85, 0.3)
	for l in _lights:
		if is_instance_valid(l):
			l.light_color = c


func _room() -> void:
	var env_n := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.025, 0.03, 0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.22, 0.26, 0.34)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = false
	env_n.environment = env
	add_child(env_n)


func _playfield() -> void:
	_box(Vector3(1.12, 0.08, 2.28), Vector3(0, -0.04, 1.05), Color(0.07, 0.09, 0.12), 0.45, 0.35)
	var art := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.04, 0.002, 2.16)
	art.mesh = box
	art.position = Vector3(0, 0.002, 1.05)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.1, 0.16)
	mat.roughness = 0.35
	mat.metallic = 0.28
	art.material_override = mat
	add_child(art)


func _walls() -> void:
	_box(Vector3(0.06, 0.16, 2.2), Vector3(-0.55, 0.08, 1.05), Color(0.2, 0.28, 0.36), 0.3, 0.6)
	_box(Vector3(0.06, 0.16, 2.2), Vector3(0.55, 0.08, 1.05), Color(0.2, 0.28, 0.36), 0.3, 0.6)
	_box(Vector3(1.16, 0.2, 0.06), Vector3(0, 0.1, 2.16), Color(0.18, 0.24, 0.32), 0.3, 0.55)
	_box(Vector3(0.42, 0.12, 0.06), Vector3(-0.34, 0.06, 0.08), Color(0.22, 0.26, 0.32), 0.35, 0.5)
	_box(Vector3(0.42, 0.12, 0.06), Vector3(0.34, 0.06, 0.08), Color(0.22, 0.26, 0.32), 0.35, 0.5)


func _flippers() -> void:
	flip_l = _flipper(Vector3(-0.16, 0.04, 0.22), 1)
	flip_r = _flipper(Vector3(0.16, 0.04, 0.22), -1)
	add_child(flip_l)
	add_child(flip_r)


func _flipper(pos: Vector3, side: int) -> AnimatableBody3D:
	var body := AnimatableBody3D.new()
	body.position = pos
	body.sync_to_physics = true
	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.22, 0.05, 0.045)
	mesh_i.mesh = box
	mesh_i.position = Vector3(0.1 * side, 0, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.88, 0.95)
	mat.metallic = 0.7
	mat.roughness = 0.22
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.55, 0.9)
	mat.emission_energy_multiplier = 0.45
	mesh_i.material_override = mat
	body.add_child(mesh_i)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.22, 0.05, 0.045)
	col.shape = sh
	col.position = mesh_i.position
	body.add_child(col)
	return body


func _bumpers() -> void:
	_bumper(Vector3(0.0, 0.07, 1.42), "b1")
	_bumper(Vector3(-0.16, 0.07, 1.24), "b2")
	_bumper(Vector3(0.16, 0.07, 1.24), "b3")


func _bumper(pos: Vector3, key: String) -> void:
	_cyl(0.055, 0.1, pos, Color(0.85, 0.35, 0.22), true)
	_area(Vector3(0.12, 0.1, 0.12), pos, Types.Event.BUMPER, key)


func _slings() -> void:
	_area(Vector3(0.16, 0.08, 0.14), Vector3(-0.28, 0.05, 0.48), Types.Event.SLING, "sl")
	_area(Vector3(0.16, 0.08, 0.14), Vector3(0.28, 0.05, 0.48), Types.Event.SLING, "sr")
	_box(Vector3(0.18, 0.08, 0.04), Vector3(-0.3, 0.04, 0.5), Color(0.9, 0.55, 0.2), 0.3, 0.4)
	_box(Vector3(0.18, 0.08, 0.04), Vector3(0.3, 0.04, 0.5), Color(0.9, 0.55, 0.2), 0.3, 0.4)


func _targets() -> void:
	_area(Vector3(0.08, 0.1, 0.04), Vector3(-0.32, 0.06, 1.72), Types.Event.SHADOW_TARGET, "s1")
	_area(Vector3(0.08, 0.1, 0.04), Vector3(0.0, 0.06, 1.82), Types.Event.SHADOW_TARGET, "s2")
	_area(Vector3(0.08, 0.1, 0.04), Vector3(0.32, 0.06, 1.72), Types.Event.SHADOW_TARGET, "s3")
	_box(Vector3(0.07, 0.1, 0.03), Vector3(-0.32, 0.06, 1.72), Color(0.35, 0.7, 1.0), 0.25, 0.5)
	_box(Vector3(0.07, 0.1, 0.03), Vector3(0.0, 0.06, 1.82), Color(0.35, 0.7, 1.0), 0.25, 0.5)
	_box(Vector3(0.07, 0.1, 0.03), Vector3(0.32, 0.06, 1.72), Color(0.35, 0.7, 1.0), 0.25, 0.5)
	_area(Vector3(0.1, 0.08, 0.04), Vector3(-0.4, 0.05, 0.95), Types.Event.TARGET, "t1")
	_box(Vector3(0.08, 0.08, 0.03), Vector3(-0.4, 0.05, 0.95), Color(0.95, 0.85, 0.4), 0.3, 0.4)


func _lanes() -> void:
	for i in 3:
		var x := -0.16 + i * 0.16
		_area(Vector3(0.07, 0.08, 0.06), Vector3(x, 0.05, 2.02), Types.Event.LANE, "lane-%d" % i)
		_box(Vector3(0.015, 0.1, 0.12), Vector3(x - 0.05, 0.06, 2.0), Color(0.5, 0.85, 1.0), 0.2, 0.6)
	_area(Vector3(0.08, 0.08, 0.08), Vector3(-0.46, 0.05, 0.72), Types.Event.ROLLOVER, "in-l")
	_area(Vector3(0.08, 0.08, 0.08), Vector3(0.46, 0.05, 0.72), Types.Event.ROLLOVER, "in-r")


func _ramp() -> void:
	var ramp := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.12, 0.03, 0.85)
	ramp.mesh = box
	ramp.position = Vector3(-0.38, 0.12, 1.15)
	ramp.rotation_degrees = Vector3(-16, 12, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.28, 0.34, 0.45)
	mat.metallic = 0.55
	mat.roughness = 0.28
	ramp.material_override = mat
	add_child(ramp)
	var body := StaticBody3D.new()
	body.position = ramp.position
	body.rotation = ramp.rotation
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = box.size
	col.shape = sh
	body.add_child(col)
	add_child(body)
	_area(Vector3(0.14, 0.1, 0.12), Vector3(-0.3, 0.22, 1.55), Types.Event.RAMP, "ramp")


func _lock() -> void:
	_cyl(0.045, 0.02, Vector3(0.34, 0.02, 1.55), Color(0.15, 0.9, 0.55), true)
	_area(Vector3(0.1, 0.08, 0.1), Vector3(0.34, 0.04, 1.55), Types.Event.LOCK, "lock")


func _drain() -> void:
	_area(Vector3(0.22, 0.08, 0.1), Vector3(0.0, 0.03, 0.02), Types.Event.DRAIN, "drain")


func _plunger_lane() -> void:
	_box(Vector3(0.08, 0.12, 1.7), Vector3(0.48, 0.06, 1.05), Color(0.16, 0.2, 0.26), 0.4, 0.4)
	_area(Vector3(0.08, 0.08, 0.08), Vector3(0.48, 0.05, 0.22), Types.Event.PLUNGER, "plunge")


func _area(size: Vector3, pos: Vector3, kind, key: String) -> void:
	var a := Area3D.new()
	a.position = pos
	a.monitoring = true
	a.monitorable = true
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	col.shape = sh
	a.add_child(col)
	a.set_meta("kind", kind)
	a.set_meta("key", key)
	a.body_entered.connect(func(body: Node):
		if body is RigidBody3D:
			scored.emit(kind, int(body.get_meta("ball_id", 1)), key)
			if kind == Types.Event.BUMPER or kind == Types.Event.SLING:
				var n = body.global_position - a.global_position
				n.y = 0.02
				body.apply_central_impulse(n.normalized() * (0.085 if kind == Types.Event.BUMPER else 0.06))
	)
	add_child(a)


func _box(size: Vector3, pos: Vector3, color: Color, rough: float, metal: float) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_i.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	mat.metallic = metal
	mesh_i.material_override = mat
	body.add_child(mesh_i)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	col.shape = sh
	body.add_child(col)
	add_child(body)


func _cyl(r: float, h: float, pos: Vector3, color: Color, glow: bool) -> void:
	var mesh_i := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = h
	mesh_i.mesh = cyl
	mesh_i.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.28
	mat.metallic = 0.45
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.7
	mesh_i.material_override = mat
	add_child(mesh_i)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 0.12, 0)
	light.light_energy = 1.3
	light.omni_range = 0.55
	light.light_color = color
	add_child(light)
	_lights.append(light)
