extends Node
## Kör Mangekyō: V Sharingan'ı kapatabilmeli; Gözler menüsü 1600x900'de taşmamalı
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _v(ey) -> void:
	var a = InputEventAction.new(); a.action = "dojutsu"; a.pressed = true
	ey.handle_input(a)
	await _w(0.1)
	var b = InputEventAction.new(); b.action = "dojutsu"; b.pressed = false
	ey.handle_input(b)
	await _w(0.4)

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	var pl = main.player
	Hud.close_dialog()
	Gear.grant(Game.profile, "goz_mangekyo", "sag_goz", null, null, {"lvl": 3, "origin": "dogustan"})
	Gear.grant(Game.profile, "goz_mangekyo", "sol_goz", null, null, {"lvl": 3, "origin": "dogustan"})
	Gear.apply_look(Game.profile)
	SpecialSlots.refresh(Game.profile)
	var ey: Eyes = pl.combat.modes.eyes
	Game.profile["ms_blind"] = 1.0
	await _v(ey)
	print("BL1 after_V1 active=%s ms_on=%s" % [ey.active, ey.ms_on])
	await _v(ey)
	print("BL2 after_V2 active=%s ms_on=%s" % [ey.active, ey.ms_on])
	Game.profile["ms_blind"] = 0.0
	await _v(ey); await _v(ey); await _v(ey)
	print("BL3 notblind_3V active=%s ms_on=%s" % [ey.active, ey.ms_on])
	Menus.ninja_menu(main, "eyes")
	await _w(0.6)
	var vp = get_viewport().get_visible_rect().size
	var worst = 0.0
	var stack = [get_tree().root]
	while not stack.is_empty():
		var n = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is Control and n.is_visible_in_tree() and n is Label and n.text != "":
			var r = n.get_global_rect()
			worst = maxf(worst, r.end.x)
	print("BL4 vp=%s rightmost_label_x=%.0f fits=%s" % [str(vp), worst, str(worst <= vp.x)])
	await main.shot("eyes_menu")
	get_tree().quit()
