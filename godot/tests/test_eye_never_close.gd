extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pr = Game.profile
	Gear.grant(pr, "goz_sharingan", "sol_goz", null, null, {"lvl": 3, "origin": "nakil"})
	Gear.apply_look(pr)
	var ey = main.player.combat.modes.eyes
	ey.refresh_visual()
	print("NEVER sol=", ey._never_closes("sol"), " sag=", ey._never_closes("sag"), " active=", ey.active)
	ey.toggle(); ey.toggle()
	print("NEVER after toggle active=", ey.active, " still_visible=", ey._never_closes("sol"))
	for gid in ["goz_mangekyo", "goz_ems"]:
		var u = Gear.grant(pr, gid, "sag_goz", null, null, {"lvl": 3, "origin": "nakil"})
		Gear.apply_look(pr)
		ey.refresh_visual()
		print("NEVER %s never=%s raw=%d kind=%d origin=%s" % [gid, ey._never_closes("sag"), ey._raw_kind("sag"), ey._kind("sag"), Gear.find(pr, u).get("origin")])
	Gear.grant(pr, "goz_ems", "sag_goz", null, null, {"lvl": 3, "origin": "nakil"})
	Gear.grant(pr, "goz_ems", "sol_goz", null, null, {"lvl": 3, "origin": "nakil"})
	Gear.apply_look(pr)
	if ey.active: ey._close()
	var seq = []
	for k in 3:
		var a1 = InputEventAction.new(); a1.action = "dojutsu"; a1.pressed = true
		ey.handle_input(a1)
		await get_tree().create_timer(0.08).timeout
		var b1 = InputEventAction.new(); b1.action = "dojutsu"; b1.pressed = false
		ey.handle_input(b1)
		await get_tree().create_timer(0.2).timeout
		seq.append("V%d act=%s ms=%s vis_tomoe=%s" % [k + 1, ey.active, ey.ms_on, ey._never_closes("sag")])
	print("NEVER ems_cycle ", seq)
	pr["clan"] = "uchiha"
	print("NEVER uchiha=", ey._never_closes("sol"))
	get_tree().quit()
