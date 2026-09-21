class_name PinEngine
extends RefCounted

const Types = preload("res://scripts/pin/pin_types.gd")

var mode: Types.Mode = Types.Mode.CLASSIC
var phase: Types.Phase = Types.Phase.READY
var mission: Types.Mission = Types.Mission.SHADOW_MODE
var score: int = 0
var multiplier: int = 1
var balls_left: int = 3
var balls_in_play: int = 0
var locks: int = 0
var shadow_hits: int = 0
var bumper_chain: int = 0
var ramp_hits: int = 0
var lanes_lit: int = 0
var last_message: String = "Launch the ball"
var stuck_ticks: int = 0
var recovered: int = 0
var drained_ids: Dictionary = {}
var scored_once: Dictionary = {}
var missions_done: Array[String] = []
var winner: int = -1


func reset(p_mode: Types.Mode) -> void:
	mode = p_mode
	phase = Types.Phase.READY
	mission = Types.Mission.SHADOW_MODE
	score = 0
	multiplier = 1
	balls_left = 99 if mode == Types.Mode.PRACTICE else 3
	if mode == Types.Mode.WIZARD:
		balls_left = 5
	balls_in_play = 0
	locks = 0
	shadow_hits = 0
	bumper_chain = 0
	ramp_hits = 0
	lanes_lit = 0
	last_message = "Launch the ball"
	stuck_ticks = 0
	recovered = 0
	drained_ids.clear()
	scored_once.clear()
	missions_done.clear()
	winner = -1


func launch() -> Dictionary:
	if phase == Types.Phase.GAME_OVER:
		return {"accepted": false}
	if phase == Types.Phase.READY or phase == Types.Phase.BALL_OVER:
		balls_in_play = 1
		phase = Types.Phase.LIVE
		last_message = "Ball in play"
		return {"accepted": true, "balls_in_play": balls_in_play}
	if balls_in_play <= 0:
		balls_in_play = 1
		phase = Types.Phase.LIVE
		return {"accepted": true, "balls_in_play": balls_in_play}
	return {"accepted": false, "balls_in_play": balls_in_play}


func apply(kind: Types.Event, ball_id: int = 1, key: String = "") -> Dictionary:
	if phase == Types.Phase.GAME_OVER:
		return {"accepted": false, "points": 0}
	if kind == Types.Event.DRAIN:
		return _drain(ball_id)
	if phase != Types.Phase.LIVE and kind != Types.Event.PLUNGER:
		return {"accepted": false, "points": 0}
	if kind == Types.Event.PLUNGER:
		launch()
	if not key.is_empty():
		var token := "%s:%s:%d" % [key, str(kind), ball_id]
		if scored_once.has(token):
			return {"accepted": false, "points": 0, "duplicate": true}
		scored_once[token] = true
	var multi := balls_in_play > 1
	var pts := Types.event_points(kind, multiplier, multi)
	score += pts
	_progress(kind)
	return {"accepted": true, "points": pts, "score": score, "mission": Types.mission_name(mission), "multiball": multi}


func tick_stuck(moving: bool) -> Dictionary:
	if phase != Types.Phase.LIVE:
		stuck_ticks = 0
		return {"recovered": false}
	if moving:
		stuck_ticks = 0
		return {"recovered": false}
	stuck_ticks += 1
	if stuck_ticks >= 8:
		stuck_ticks = 0
		recovered += 1
		last_message = "Ball recovered"
		return {"recovered": true}
	return {"recovered": false}


func _drain(ball_id: int) -> Dictionary:
	if drained_ids.has(ball_id):
		return {"accepted": false, "points": 0, "duplicate": true}
	drained_ids[ball_id] = true
	if balls_in_play > 0:
		balls_in_play -= 1
	if balls_in_play > 0:
		last_message = "Drain  ·  %d balls" % balls_in_play
		return {"accepted": true, "points": 0, "balls_in_play": balls_in_play}
	if mode == Types.Mode.PRACTICE:
		phase = Types.Phase.READY
		last_message = "Practice drain"
		return {"accepted": true, "points": 0}
	balls_left -= 1
	if balls_left <= 0:
		phase = Types.Phase.GAME_OVER
		winner = 0
		last_message = "Final  %d" % score
	else:
		phase = Types.Phase.BALL_OVER
		last_message = "Ball over  ·  %d left" % balls_left
	return {"accepted": true, "points": 0, "balls_in_play": 0}


func _progress(kind: Types.Event) -> void:
	match kind:
		Types.Event.SHADOW_TARGET:
			if mission == Types.Mission.SHADOW_MODE:
				shadow_hits = mini(shadow_hits + 1, 3)
				last_message = "Shadow %d/3" % shadow_hits
				if shadow_hits >= 3:
					_advance(Types.Mission.FETCH_MULTIBALL)
		Types.Event.LOCK:
			if mission == Types.Mission.FETCH_MULTIBALL:
				locks = mini(locks + 1, 2)
				last_message = "Lock %d/2" % locks
				if locks >= 2:
					_start_multiball()
					_advance(Types.Mission.SYSTEM_OVERLOAD)
			elif mission == Types.Mission.FINAL_JACKPOT:
				last_message = "FINAL JACKPOT"
				_advance(Types.Mission.COMPLETE)
			else:
				last_message = "Lock"
		Types.Event.BUMPER:
			if mission == Types.Mission.SYSTEM_OVERLOAD:
				bumper_chain += 1
				last_message = "Overload %d/12" % bumper_chain
				if bumper_chain >= 12:
					_advance(Types.Mission.NIGHT_RUN)
			else:
				last_message = "Bumper"
		Types.Event.RAMP:
			if mission == Types.Mission.NIGHT_RUN:
				ramp_hits = mini(ramp_hits + 1, 3)
				last_message = "Night run %d/3" % ramp_hits
				if ramp_hits >= 3:
					_advance(Types.Mission.FINAL_JACKPOT)
			else:
				last_message = "Ramp"
		Types.Event.LANE:
			lanes_lit = mini(lanes_lit + 1, 3)
			if lanes_lit >= 3:
				multiplier = mini(multiplier + 1, 5)
				lanes_lit = 0
				last_message = "Multiplier x%d" % multiplier
			else:
				last_message = "Lane %d/3" % lanes_lit
		Types.Event.SLING:
			last_message = "Sling"
		Types.Event.TARGET:
			last_message = "Target"
		Types.Event.ROLLOVER:
			last_message = "Rollover"
		_:
			pass


func _start_multiball() -> void:
	balls_in_play = maxi(balls_in_play, 1) + 1
	if mode == Types.Mode.MULTIBALL_DRILL:
		balls_in_play = 2
	last_message = "FETCH MULTIBALL"


func _advance(next: Types.Mission) -> void:
	missions_done.append(Types.mission_name(mission))
	mission = next
	if next == Types.Mission.COMPLETE:
		multiplier = mini(multiplier + 1, 5)
		last_message = "Wizard complete  x%d" % multiplier
		if mode == Types.Mode.WIZARD:
			mission = Types.Mission.SHADOW_MODE
			shadow_hits = 0
			locks = 0
			bumper_chain = 0
			ramp_hits = 0
