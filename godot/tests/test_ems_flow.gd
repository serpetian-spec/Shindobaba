extends Node
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pr = Game.profile
	var pl = main.player
	Gear.grant(pr, "goz_mangekyo", "sag_goz")
	Gear.grant(pr, "goz_mangekyo", "sol_goz")
	Gear.apply_look(pr)
	pr["ms_blind"] = 1.0
	var u2 = Gear.grant(pr, "goz_mangekyo", "")
	var ey = pl.combat.modes.eyes
	print("EMS before: ems=%s blind=%.2f" % [ey._ems(), ey.blind()])
	ey.transplant(pr, u2, "sag_goz")
	await _w(0.5)
	print("EMS after transplant: r=%s l=%s ems=%s blind=%.2f" % [str(pr["look"].get("eye_r")), str(pr["look"].get("eye_l")), ey._ems(), ey.blind()])
	var ev = InputEventAction.new()
	ev.action = "dojutsu"
	ev.pressed = true
	ey.handle_input(ev)
	await _w(0.1)
	var ev2 = InputEventAction.new()
	ev2.action = "dojutsu"
	ev2.pressed = false
	ey.handle_input(ev2)
	await _w(0.3)
	print("EMS V1: active=%s ms_on=%s kind_sag=%d" % [ey.active, ey.ms_on, ey._kind("sag")])
	get_tree().quit()
