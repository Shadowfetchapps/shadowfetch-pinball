extends SceneTree

const PinTests = preload("res://tests/test_pinball.gd")
const SettingsTests = preload("res://tests/test_settings_store.gd")


func _initialize() -> void:
	print("Running Shadowfetch Pinball tests...")
	var tmp := OS.get_user_data_dir().path_join("pin-test-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(tmp)
	OS.set_environment("SHADOWFETCH_PINBALL_CONFIG", tmp.path_join("config"))
	OS.set_environment("SHADOWFETCH_PINBALL_DATA", tmp.path_join("data"))
	var ok := PinTests.new().run_all() and SettingsTests.new().run_all()
	if ok:
		print("ALL TESTS PASSED")
	else:
		print("TESTS FAILED")
	quit(0 if ok else 1)
