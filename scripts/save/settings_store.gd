extends Node

const Paths = preload("res://scripts/save/app_paths.gd")
const SETTINGS_VERSION := 1

var graphics_quality: String = "high"
var resolution: Vector2i = Vector2i(1600, 900)
var fullscreen: bool = false
var vsync: bool = true
var antialiasing: int = 2
var shadows_enabled: bool = true
var effects_enabled: bool = true
var master_volume: float = 0.85
var music_volume: float = 0.18
var sfx_volume: float = 0.82
var ambient_volume: float = 0.26
var camera_sensitivity: float = 1.0
var shot_sensitivity: float = 1.0
var ai_difficulty: String = "medium"

signal settings_changed


func _ready() -> void:
	load_settings()
	if not _is_headless():
		apply_display()
		apply_audio()


func settings_path() -> String:
	return Paths.settings_path()


func reset_to_defaults() -> void:
	from_dict(defaults())


func defaults() -> Dictionary:
	return {
		"version": SETTINGS_VERSION,
		"graphics_quality": "high",
		"resolution": [1600, 900],
		"fullscreen": false,
		"vsync": true,
		"antialiasing": 2,
		"shadows_enabled": true,
		"effects_enabled": true,
		"master_volume": 0.85,
		"music_volume": 0.18,
		"sfx_volume": 0.82,
		"ambient_volume": 0.26,
		"camera_sensitivity": 1.0,
		"shot_sensitivity": 1.0,
		"ai_difficulty": "medium",
	}


func to_dict() -> Dictionary:
	return {
		"version": SETTINGS_VERSION,
		"graphics_quality": graphics_quality,
		"resolution": [resolution.x, resolution.y],
		"fullscreen": fullscreen,
		"vsync": vsync,
		"antialiasing": antialiasing,
		"shadows_enabled": shadows_enabled,
		"effects_enabled": effects_enabled,
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"ambient_volume": ambient_volume,
		"camera_sensitivity": camera_sensitivity,
		"shot_sensitivity": shot_sensitivity,
		"ai_difficulty": ai_difficulty,
	}


func from_dict(d: Dictionary) -> bool:
	if d.is_empty():
		return false
	var g := str(d.get("graphics_quality", "high"))
	if g not in ["low", "medium", "high"]:
		g = "high"
	graphics_quality = g
	var res: Variant = d.get("resolution", [1600, 900])
	if res is Array and res.size() >= 2:
		resolution = Vector2i(clampi(int(res[0]), 800, 7680), clampi(int(res[1]), 600, 4320))
	else:
		resolution = Vector2i(1600, 900)
	fullscreen = bool(d.get("fullscreen", false))
	vsync = bool(d.get("vsync", true))
	antialiasing = int(d.get("antialiasing", 2))
	if antialiasing not in [0, 2, 4, 8]:
		antialiasing = 2
	shadows_enabled = bool(d.get("shadows_enabled", true))
	effects_enabled = bool(d.get("effects_enabled", true))
	master_volume = clampf(float(d.get("master_volume", 0.85)), 0.0, 1.0)
	music_volume = clampf(float(d.get("music_volume", 0.18)), 0.0, 1.0)
	sfx_volume = clampf(float(d.get("sfx_volume", 0.82)), 0.0, 1.0)
	ambient_volume = clampf(float(d.get("ambient_volume", 0.26)), 0.0, 1.0)
	camera_sensitivity = clampf(float(d.get("camera_sensitivity", 1.0)), 0.3, 2.5)
	shot_sensitivity = clampf(float(d.get("shot_sensitivity", 1.0)), 0.3, 2.5)
	var ai := str(d.get("ai_difficulty", "medium"))
	if ai not in ["easy", "medium", "hard"]:
		ai = "medium"
	ai_difficulty = ai
	return true


func save_settings() -> void:
	Paths.ensure_dirs()
	var f := FileAccess.open(settings_path(), FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(to_dict(), "\t"))
	settings_changed.emit()


func load_settings() -> void:
	reset_to_defaults()
	if not FileAccess.file_exists(settings_path()):
		return
	var f := FileAccess.open(settings_path(), FileAccess.READ)
	if f == null:
		return
	var json := JSON.new()
	if json.parse(f.get_as_text()) == OK and json.data is Dictionary and from_dict(json.data):
		return
	push_warning("Corrupt settings recovered to defaults")
	reset_to_defaults()
	save_settings()


func apply_display() -> void:
	if _is_headless():
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolution)
	var vp := get_viewport()
	if vp:
		match antialiasing:
			8:
				vp.msaa_3d = Viewport.MSAA_8X
			4:
				vp.msaa_3d = Viewport.MSAA_4X
			2:
				vp.msaa_3d = Viewport.MSAA_2X
			_:
				vp.msaa_3d = Viewport.MSAA_DISABLED
		vp.use_taa = false


func apply_audio() -> void:
	_set_bus("Master", master_volume)
	_set_bus("Music", music_volume)
	_set_bus("SFX", sfx_volume)
	_set_bus("Ambient", ambient_volume)


func _set_bus(name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(idx, linear <= 0.001)


func quality_shadows() -> bool:
	return shadows_enabled and graphics_quality != "low"


func quality_effects() -> bool:
	return effects_enabled and graphics_quality != "low"


func _is_headless() -> bool:
	return DisplayServer.get_name() == "headless" or OS.has_feature("headless")
