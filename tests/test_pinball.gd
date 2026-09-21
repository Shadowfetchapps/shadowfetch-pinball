extends RefCounted

const Types = preload("res://scripts/pin/pin_types.gd")
const Rules = preload("res://scripts/pin/pin_engine.gd")
const Sim = preload("res://scripts/pin/pin_sim.gd")

var _failures: Array[String] = []
var _checks := 0


func run_all() -> bool:
	_points()
	_missions()
	_multiball()
	_drain_once()
	_stuck()
	_streams(12000)
	_sim(8000)
	print("Pinball checks: %d  failures: %d" % [_checks, _failures.size()])
	for m in _failures:
		print("FAIL: ", m)
	return _failures.is_empty()


func _points() -> void:
	var e = _fresh()
	e.launch()
	_ok(int(e.apply(Types.Event.BUMPER)["points"]) == 100, "bumper 100")
	_ok(int(e.apply(Types.Event.SLING)["points"]) == 50, "sling 50")
	_ok(int(e.apply(Types.Event.TARGET)["points"]) == 250, "target 250")
	_ok(int(e.apply(Types.Event.RAMP)["points"]) == 500, "ramp 500")
	e.multiplier = 2
	_ok(int(e.apply(Types.Event.BUMPER)["points"]) == 200, "bumper x2")
	var d = e.apply(Types.Event.ROLLOVER, 1, "roll-a")
	var d2 = e.apply(Types.Event.ROLLOVER, 1, "roll-a")
	_ok(int(d["points"]) == 200, "rollover once")
	_ok(bool(d2.get("duplicate", false)), "no duplicate rollover")


func _missions() -> void:
	var e = _fresh()
	e.launch()
	for _i in 3:
		e.apply(Types.Event.SHADOW_TARGET)
	_ok(e.mission == Types.Mission.FETCH_MULTIBALL, "shadow to fetch")
	e.apply(Types.Event.LOCK)
	e.apply(Types.Event.LOCK)
	_ok(e.mission == Types.Mission.SYSTEM_OVERLOAD, "fetch to overload")
	_ok(e.balls_in_play == 2, "multiball two balls")
	for _i in 12:
		e.apply(Types.Event.BUMPER)
	_ok(e.mission == Types.Mission.NIGHT_RUN, "overload to night")
	for _i in 3:
		e.apply(Types.Event.RAMP)
	_ok(e.mission == Types.Mission.FINAL_JACKPOT, "night to jackpot")
	var j = e.apply(Types.Event.LOCK)
	_ok(int(j["points"]) == 5000, "jackpot 5000 during multi")
	_ok(e.mission == Types.Mission.COMPLETE, "wizard complete")
	_ok(e.missions_done.size() == 5, "five missions logged")


func _multiball() -> void:
	var e = _fresh()
	e.launch()
	e.mission = Types.Mission.FETCH_MULTIBALL
	e.apply(Types.Event.LOCK)
	e.apply(Types.Event.LOCK)
	_ok(e.balls_in_play == 2, "lock starts second ball")
	e.apply(Types.Event.DRAIN, 1)
	_ok(e.balls_in_play == 1, "one remains")
	_ok(e.phase == Types.Phase.LIVE, "multi survives one drain")
	e.apply(Types.Event.DRAIN, 2)
	_ok(e.phase == Types.Phase.BALL_OVER, "last drain ends ball")


func _drain_once() -> void:
	var e = _fresh()
	e.launch()
	e.apply(Types.Event.DRAIN, 4)
	var again = e.apply(Types.Event.DRAIN, 4)
	_ok(bool(again.get("duplicate", false)) or e.balls_left == 2, "drain once")
	_ok(e.balls_left == 2, "one ball consumed")


func _stuck() -> void:
	var e = _fresh()
	e.launch()
	var hit := false
	for _i in 12:
		var r = e.tick_stuck(false)
		if bool(r["recovered"]):
			hit = true
	_ok(hit, "stuck recovers")
	_ok(e.recovered >= 1, "recovery counted")


func _streams(n: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var kinds: Array = [
		Types.Event.BUMPER, Types.Event.SLING, Types.Event.TARGET, Types.Event.SHADOW_TARGET,
		Types.Event.ROLLOVER, Types.Event.RAMP, Types.Event.LOCK, Types.Event.LANE, Types.Event.PLUNGER
	]
	for g in n:
		var e = _fresh()
		e.launch()
		var total := 0
		for _s in 24:
			var k = kinds[rng.randi_range(0, kinds.size() - 1)]
			var r = e.apply(k, 1, "")
			if bool(r.get("accepted", false)):
				total += int(r.get("points", 0))
		_ok(e.score == total, "stream score")
		_ok(e.score >= 0, "nonneg")
		_ok(e.multiplier >= 1 and e.multiplier <= 5, "mult bounds")
	_ok(n >= 12000, "12000 streams")


func _sim(n: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in n:
		var p := Vector2(rng.randf_range(-0.2, 0.2), rng.randf_range(0.4, 1.8))
		var v := Vector2(rng.randf_range(-6, 6), rng.randf_range(-6, 6))
		var drained := false
		for _s in 40:
			var r = Sim.step(p, v, 0.016, i % 2 == 0, i % 3 == 0)
			p = r["p"]
			v = r["v"]
			_ok(not bool(r["nan"]), "no nan")
			if bool(r["drain"]):
				drained = true
				break
			if bool(r["escaped"]):
				_ok(Sim.in_table(p) or p.y > 0.2, "escaped recovered")
		_ok(p.y > -0.2 or drained, "no world escape")
	_ok(n >= 8000, "8000 trajectories")


func _fresh():
	var e = Rules.new()
	e.reset(Types.Mode.CLASSIC)
	return e


func _ok(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond and _failures.size() < 40:
		_failures.append(msg)
