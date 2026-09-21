extends Control


func _ready() -> void:
	theme = ThemeFactory.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.025, 0.03, 0.045)
	add_child(bg)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(520, 300)
	panel.offset_left = -260
	panel.offset_right = 260
	panel.offset_top = -150
	panel.offset_bottom = 150
	add_child(panel)
	var v := VBoxContainer.new()
	panel.add_child(v)
	var t := Label.new()
	t.text = "Statistics"
	t.add_theme_font_size_override("font_size", 28)
	v.add_child(t)
	var s := StatsStore.load_stats()
	var body := Label.new()
	body.text = "Games %s\nHigh score %s\nJackpots %s\nMultiballs %s\nDrains %s" % [
		s.get("games", 0), s.get("high_score", 0), s.get("jackpots", 0),
		s.get("multiballs", 0), s.get("drains", 0)
	]
	v.add_child(body)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn"))
	v.add_child(back)
