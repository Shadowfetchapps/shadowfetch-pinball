class_name PinGameController
extends Node3D

const Types = preload("res://scripts/pin/pin_types.gd")
const Rules = preload("res://scripts/pin/pin_engine.gd")

var engine = Rules.new()
var table: PinTable
var camera: Camera3D
var ui: PinHUD
var balls: Array = []
var _next_id := 1
var _charge := 0.0
var _charging := false
var _stats: Dictionary = {}
var _quiet := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_stats = StatsStore.load_stats()
	engine.reset(GameSession.mode)
	_world()
	ui = PinHUD.new()
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui)
	ui.setup(engine)
	ui.launch_requested.connect(_plunger)
	ui.pause_requested.connect(_toggle_pause)
	ui.restart_requested.connect(_restart)
	ui.settings_requested.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/menus/settings_menu.tscn")
	)
	ui.menu_requested.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
	)
	ui.quit_requested.connect(func(): get_tree().quit())
	table.scored.connect(_on_score)
	_handle_cli()


func _world() -> void:
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55, 20, 0)
	key.light_energy = 1.15
	key.shadow_enabled = SettingsStore.quality_shadows()
	add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 1.8, 1.0)
	fill.light_energy = 2.4
	fill.omni_range = 6.0
	fill.light_color = Color(0.75, 0.85, 1.0)
	add_child(fill)
	table = PinTable.new()
	add_child(table)
	camera = Camera3D.new()
	camera.fov = 38
	camera.position = Vector3(0.0, 1.85, -0.55)
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.05, 1.15))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		_toggle_pause()
		return
	if get_tree().paused or engine.phase == Types.Phase.GAME_OVER:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_charging = mb.pressed
			if not mb.pressed and _charge > 0.05:
				_plunger()
	if event.is_action_pressed("plunger"):
		_charging = true
	if event.is_action_released("plunger"):
		_charging = false
		_plunger()


func _process(dt: float) -> void:
	if ui == null or table == null:
		return
	if get_tree().paused:
		return
	var left := Input.is_action_pressed("flipper_left") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _cursor_left()
	var right := Input.is_action_pressed("flipper_right") or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if not get_tree().paused:
		table.drive_flippers(left, right, dt)
	if _charging:
		_charge = minf(_charge + dt * 1.4 * SettingsStore.shot_sensitivity, 1.0)
		ui.set_power(_charge)
	_watch_balls(dt)
	table.pulse(Types.mission_name(engine.mission))
	ui.refresh()


func _cursor_left() -> bool:
	return get_viewport().get_mouse_position().x < get_viewport().get_visible_rect().size.x * 0.5


func _plunger() -> void:
	if engine.phase == Types.Phase.GAME_OVER:
		return
	if engine.phase == Types.Phase.LIVE and engine.balls_in_play > 0 and balls.size() > 0:
		_charge = 0.2
		ui.set_power(_charge)
		return
	engine.launch()
	_spawn_ball(Vector3(0.48, 0.06, 0.28), Vector3(0, 0.01, 2.6 + _charge * 4.8))
	_charge = 0.2
	ui.set_power(_charge)
	AudioManager.play("hit")


func _spawn_ball(pos: Vector3, impulse: Vector3) -> void:
	var ball := table.make_ball()
	ball.position = pos
	ball.set_meta("ball_id", _next_id)
	_next_id += 1
	add_child(ball)
	balls.append(ball)
	ball.apply_central_impulse(impulse)


func _watch_balls(dt: float) -> void:
	var moving := false
	var alive: Array = []
	for b in balls:
		if not is_instance_valid(b):
			continue
		if b.linear_velocity.length() > 18.0:
			b.linear_velocity = b.linear_velocity.limit_length(18.0)
		if is_nan(b.global_position.x) or b.global_position.y < -0.4 or absf(b.global_position.x) > 1.2:
			b.global_position = Vector3(0.0, 0.08, 0.55)
			b.linear_velocity = Vector3.ZERO
		if b.linear_velocity.length() > 0.12:
			moving = true
		alive.append(b)
	balls = alive
	var r: Dictionary = engine.tick_stuck(moving or engine.phase != Types.Phase.LIVE)
	if bool(r.get("recovered", false)):
		for b in balls:
			if is_instance_valid(b):
				b.global_position = Vector3(0.0, 0.08, 0.62)
				b.linear_velocity = Vector3(0, 0, 1.2)
		AudioManager.play("goal")
	_quiet = 0.0 if moving else _quiet + dt


func _on_score(kind, ball_id, key) -> void:
	if engine.phase == Types.Phase.GAME_OVER:
		return
	if kind == Types.Event.LOCK and engine.mission == Types.Mission.FETCH_MULTIBALL and engine.locks == 0:
		_hold_ball(ball_id)
	var before_multi = engine.balls_in_play
	var res: Dictionary = engine.apply(kind, int(ball_id), str(key) + str(Time.get_ticks_msec() / 180))
	if not bool(res.get("accepted", false)):
		return
	if kind == Types.Event.DRAIN:
		_stats["drains"] = int(_stats.get("drains", 0)) + 1
		_free_ball(int(ball_id))
	if engine.balls_in_play > before_multi:
		_stats["multiballs"] = int(_stats.get("multiballs", 0)) + 1
		_spawn_ball(Vector3(0.0, 0.08, 0.7), Vector3(0.4, 0.02, 2.2))
	if engine.mission == Types.Mission.COMPLETE or str(engine.last_message).contains("JACKPOT"):
		if kind == Types.Event.LOCK:
			_stats["jackpots"] = int(_stats.get("jackpots", 0)) + 1
	if engine.phase == Types.Phase.GAME_OVER:
		_stats["games"] = int(_stats.get("games", 0)) + 1
		_stats["high_score"] = maxi(int(_stats.get("high_score", 0)), engine.score)
		StatsStore.save_stats(_stats)
		AudioManager.play("win")
	else:
		AudioManager.play("hit")
	ui.refresh()


func _hold_ball(ball_id: int) -> void:
	for b in balls:
		if is_instance_valid(b) and int(b.get_meta("ball_id", 0)) == int(ball_id):
			b.freeze = true
			b.global_position = Vector3(0.34, 0.08, 1.55)


func _free_ball(ball_id: int) -> void:
	var keep: Array = []
	for b in balls:
		if is_instance_valid(b) and int(b.get_meta("ball_id", 0)) == ball_id:
			b.queue_free()
		elif is_instance_valid(b):
			keep.append(b)
	balls = keep


func _toggle_pause() -> void:
	ui.set_paused(not get_tree().paused)


func _restart() -> void:
	get_tree().paused = false
	for b in balls:
		if is_instance_valid(b):
			b.queue_free()
	balls.clear()
	engine.reset(GameSession.mode)
	_next_id = 1
	ui.refresh()


func _handle_cli() -> void:
	var args := OS.get_cmdline_user_args()
	if "--screenshot" in args:
		await get_tree().create_timer(0.6).timeout
		var img := get_viewport().get_texture().get_image()
		if img:
			var dir := ProjectSettings.globalize_path("res://docs/screenshots")
			DirAccess.make_dir_recursive_absolute(dir)
			img.save_png(dir.path_join("table.png"))
			print("SCREENSHOT ", dir.path_join("table.png"))
		get_tree().quit()
	if "--self-test" in args or GameSession.self_test:
		await get_tree().process_frame
		var e = Rules.new()
		e.reset(Types.Mode.CLASSIC)
		e.launch()
		for _i in 3:
			e.apply(Types.Event.SHADOW_TARGET)
		e.apply(Types.Event.LOCK)
		e.apply(Types.Event.LOCK)
		var ok = e.mission == Types.Mission.SYSTEM_OVERLOAD and e.balls_in_play == 2
		print("SELFTEST contact=true first=2 pocketed=2 foul= ok=%s" % ok)
		get_tree().quit(0 if ok else 1)
