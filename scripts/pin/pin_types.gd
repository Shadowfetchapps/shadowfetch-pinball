class_name PinTypes
extends RefCounted

enum Mode { CLASSIC, PRACTICE, MULTIBALL_DRILL, WIZARD }
enum Phase { READY, LIVE, BALL_OVER, GAME_OVER }
enum Mission { SHADOW_MODE, FETCH_MULTIBALL, SYSTEM_OVERLOAD, NIGHT_RUN, FINAL_JACKPOT, COMPLETE }
enum Event {
	BUMPER,
	SLING,
	TARGET,
	SHADOW_TARGET,
	ROLLOVER,
	RAMP,
	LOCK,
	LANE,
	DRAIN,
	PLUNGER,
	NUDGE,
}


static func mode_name(mode: Mode) -> String:
	match mode:
		Mode.PRACTICE:
			return "Practice"
		Mode.MULTIBALL_DRILL:
			return "Multiball Drill"
		Mode.WIZARD:
			return "Wizard"
		_:
			return "Classic"


static func mission_name(m: Mission) -> String:
	match m:
		Mission.SHADOW_MODE:
			return "SHADOW MODE"
		Mission.FETCH_MULTIBALL:
			return "FETCH MULTIBALL"
		Mission.SYSTEM_OVERLOAD:
			return "SYSTEM OVERLOAD"
		Mission.NIGHT_RUN:
			return "NIGHT RUN"
		Mission.FINAL_JACKPOT:
			return "FINAL JACKPOT"
		_:
			return "COMPLETE"


static func event_points(kind: Event, multiplier: int, multiball: bool) -> int:
	var m := maxi(1, multiplier)
	match kind:
		Event.BUMPER:
			return 100 * m
		Event.SLING:
			return 50 * m
		Event.TARGET:
			return 250 * m
		Event.SHADOW_TARGET:
			return 400 * m
		Event.ROLLOVER:
			return 100 * m
		Event.LANE:
			return 150 * m
		Event.RAMP:
			return 500 * m
		Event.LOCK:
			return (5000 * m) if multiball else (1000 * m)
		Event.PLUNGER:
			return 10
		Event.NUDGE:
			return 0
		Event.DRAIN:
			return 0
		_:
			return 0
