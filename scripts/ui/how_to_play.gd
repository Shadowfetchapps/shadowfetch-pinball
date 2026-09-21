extends Control


func _ready() -> void:
	theme = ThemeFactory.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.025, 0.03, 0.045)
	add_child(bg)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 70
	panel.offset_right = -70
	panel.offset_top = 40
	panel.offset_bottom = -40
	add_child(panel)
	var v := VBoxContainer.new()
	panel.add_child(v)
	var t := Label.new()
	t.text = "How to Play"
	t.add_theme_font_size_override("font_size", 28)
	v.add_child(t)
	var s := ScrollContainer.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(s)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = """TABLE
This is an original Shadowfetch machine. It is not a copy of a commercial table.

CONTROLS
Left flipper: Left Arrow or left mouse on the left half.
Right flipper: Right Arrow or right mouse.
Plunger: hold Space or hold left click, then release. LAUNCH also fires.

MISSIONS
SHADOW MODE — hit the three cyan shadow targets.
FETCH MULTIBALL — lock two balls. The second lock starts two-ball play.
SYSTEM OVERLOAD — twelve bumper hits.
NIGHT RUN — three ramp shots.
FINAL JACKPOT — hit the lock while the table is lit for the jackpot.

A quiet ball is recovered above the flippers. Drains score once per ball. Fictional scores only.
"""
	s.add_child(body)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn"))
	v.add_child(back)
