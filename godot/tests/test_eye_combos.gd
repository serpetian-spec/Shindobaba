extends Node
## Göz kombinasyonları: V döngüsü (kısa bas) — Byakugan aşamalarda kapanmamalı, hepsi birlikte kapanmalı
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _v(ey) -> void:
	var a = InputEventAction.new(); a.action = "dojutsu"; a.pressed = true
	ey.handle_input(a)
	await _w(0.08)
	var b = InputEventAction.new(); b.action = "dojutsu"; b.pressed = false
	ey.handle_input(b)
	await _w(0.2)
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pr = Game.profile
	var pl = main.player
	var ey = pl.combat.modes.eyes
	for combo in [["goz_mangekyo", "goz_byakugan"], ["goz_ems", "goz_byakugan"], ["goz_byakugan", "goz_ems"]]:
		if ey.active:
			ey.toggle()
		ey.ms_on = false
		Gear.grant(pr, combo[0], "sag_goz")
		Gear.grant(pr, combo[1], "sol_goz")
		Gear.apply_look(pr)
		pr["ms_blind"] = 0.0
		await _w(0.2)
		var seq = []
		for k in 3:
			await _v(ey)
			seq.append("V%d:act=%s ms=%s sag=%d sol=%d" % [k + 1, ey.active, ey.ms_on, ey._kind("sag") if ey.active else 0, ey._kind("sol") if ey.active else 0])
		print("EYE %s+%s | %s | susanoo_tier=%d" % [combo[0], combo[1], " ; ".join(seq), Susanoo.max_tier(pr)])
	get_tree().quit()
