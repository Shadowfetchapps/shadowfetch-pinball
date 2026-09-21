class_name PinHUD
extends CanvasLayer

signal launch_requested
signal pause_requested
signal restart_requested
signal settings_requested
signal menu_requested
signal quit_requested

var engine
var _score: Label
var _status: Label
var _power: ProgressBar
var _pause: PanelContainer


func setup(p_engine) -> void:
	engine = p_engine
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = ThemeFactory.make()
	add_child(root)
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 20
	top.offset_right = -20
	top.offset_top = 14
	top.offset_bottom = 56
	root.add_child(top)
	_score = Label.new()
	_score.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_score)
	var pause_btn := Button.new()
	pause_btn.text = "PAUSE"
	pause_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_btn.pressed.connect(func(): pause_requested.emit())
	top.add_child(pause_btn)
	_status = Label.new()
	_status.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_status.offset_left = 20
	_status.offset_right = -20
	_status.offset_top = 56
	_status.offset_bottom = 90
	root.add_child(_status)
	_power = ProgressBar.new()
	_power.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_power.offset_left = 24
	_power.offset_right = -24
	_power.offset_top = -36
	_power.offset_bottom = -16
	_power.max_value = 1
	_power.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_power)
	var launch := Button.new()
	launch.text = "LAUNCH"
	launch.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	launch.offset_left = -180
	launch.offset_top = -86
	launch.offset_right = -24
	launch.offset_bottom = -42
	launch.mouse_filter = Control.MOUSE_FILTER_STOP
	launch.pressed.connect(func(): launch_requested.emit())
	root.add_child(launch)
	_pause = PanelContainer.new()
	_pause.visible = false
	_pause.set_anchors_preset(Control.PRESET_CENTER)
	_pause.custom_minimum_size = Vector2(340, 340)
	_pause.offset_left = -170
	_pause.offset_right = 170
	_pause.offset_top = -170
	_pause.offset_bottom = 170
	_pause.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	root.add_child(_pause)
	var pv := VBoxContainer.new()
	_pause.add_child(pv)
	var t := Label.new()
	t.text = "Paused"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(t)
	pv.add_child(_p("RESUME", func(): set_paused(false)))
	pv.add_child(_p("RESTART", func(): restart_requested.emit()))
	pv.add_child(_p("SETTINGS", func(): settings_requested.emit()))
	pv.add_child(_p("MAIN MENU", func(): menu_requested.emit()))
	pv.add_child(_p("QUIT", func(): quit_requested.emit()))
	refresh()


func _p(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 40
	b.pressed.connect(func():
		AudioManager.play("ui")
		cb.call()
	)
	return b


func set_paused(v: bool) -> void:
	_pause.visible = v
	get_tree().paused = v


func set_power(p: float) -> void:
	if _power:
		_power.value = p


func refresh() -> void:
	if engine == null:
		return
	_score.text = "%s   ·   %d   ·   x%d   ·   Balls %d   ·   Play %d" % [
		GameSession.mode_name(), engine.score, engine.multiplier, engine.balls_left, engine.balls_in_play
	]
	_status.text = "%s   ·   %s" % [engine.last_message, _mission()]


func _mission() -> String:
	const T = preload("res://scripts/pin/pin_types.gd")
	return T.mission_name(engine.mission)
