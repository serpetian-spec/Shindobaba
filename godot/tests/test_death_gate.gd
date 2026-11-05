extends Node
## 8. kapı (Ölüm Kapısı): Sekizō kapısız engellenir, açılınca atılır; süre dolunca ölüm
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.5).timeout
	Hud.close_dialog()
	var pl = main.player
	var pr = Game.profile
	pr["learned"].append("sekizo")
	pl.combat.begin_cast("sekizo")
	await get_tree().create_timer(0.1).timeout
	print("GATE kapısız: eylem=%s msg=%s" % [pl.combat.action, Hud.msg_lbl.text])
	pl.combat.action = ""
	pl.combat.modes.gates = 7
	pl.combat.modes._open_death_gate()
	await get_tree().create_timer(1.2).timeout
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var fd = pl.face_dir()
	cc.global_position = pl.global_position + fd * 3.0 + fd.cross(Vector3.UP) * 1.5 + Vector3.UP * 1.5
	cc.look_at(pl.global_position + Vector3.UP * 1.1)
	cc.current = true
	Hud.close_dialog()
	await main.shot("gate8")
	pl.cam.current = true
	print("GATE açıldı: kapı=%d hız=%s" % [pl.combat.modes.gates, str(Buffs.active.get("gates", {}).get("mods", Buffs.active.get("gates", {})))])
	pl.combat.cooldowns.clear()
	Game.set_meta("sandbox", true)
	pl.combat.begin_cast("sekizo")
	await get_tree().create_timer(0.1).timeout
	print("GATE 8. kapıda Sekizō: eylem=%s" % pl.combat.action)
	get_tree().quit()
	await get_tree().create_timer(47.0).timeout
	print("GATE 47 sn sonra: can=%.0f kapı=%d" % [pl.hp, pl.combat.modes.gates])
	get_tree().quit()
