extends Control

const Types = preload("res://scripts/pin/pin_types.gd")


func _ready() -> void:
	theme = ThemeFactory.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.025, 0.03, 0.045)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(540, 520)
	box.offset_left = -270
	box.offset_right = 270
	box.offset_top = -260
	box.offset_bottom = 260
	add_child(box)
	var t := Label.new()
	t.text = "Game Modes"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 28)
	box.add_child(t)
	box.add_child(_m("CLASSIC", "Three balls. Five missions.", Types.Mode.CLASSIC))
	box.add_child(_m("PRACTICE", "Unlimited drains. Learn the table.", Types.Mode.PRACTICE))
	box.add_child(_m("MULTIBALL DRILL", "Lock work and two-ball play.", Types.Mode.MULTIBALL_DRILL))
	box.add_child(_m("WIZARD", "Five balls. Loop the missions.", Types.Mode.WIZARD))
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size.y = 44
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn"))
	box.add_child(back)


func _m(title: String, blurb: String, mode) -> Button:
	var b := Button.new()
	b.text = "%s\n%s" % [title, blurb]
	b.custom_minimum_size.y = 68
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func():
		AudioManager.play("ui")
		GameSession.reset_defaults()
		GameSession.mode = mode
		get_tree().change_scene_to_file("res://scenes/main/game.tscn")
	)
	return b
