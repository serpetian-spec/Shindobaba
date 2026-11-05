extends Node
## Bunshin çöküşü: dışarıda, akademi içinde ve akademi uygulama sınavında Bunshin / Kage Bunshin; her adımda yazdır (çökerse son satır yeri gösterir)
var main: Node

func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _cast(pl, id: String, tag: String) -> void:
	print("BUN cast %s @%s ..." % [id, tag])
	if not id in Game.profile["learned"]:
		Game.profile["learned"].append(id)
	pl.combat.cooldowns.erase(id)
	pl.chakra = pl.max_chakra
	pl.combat.begin_cast(id)
	await _wait(3.0)
	var cl = get_tree().get_nodes_in_group("fighters").filter(func(f): return f is ShadowClone)
	print("BUN ok %s @%s klon=%d" % [id, tag, cl.size()])
	for c in cl:
		if is_instance_valid(c) and c.has_method("take_hit"):
			c.take_hit({"dmg": 1e6, "attacker": null, "kind": "heavy"})
	await _wait(1.5)
	print("BUN klon vuruldu %s @%s" % [id, tag])


func _ready() -> void:
	await get_tree().process_frame
	Game.set_meta("sandbox", true)
	for g in ["m", "f"]:
		main.creator_state = {"slot": 3, "name": "Test", "gender": g, "clan": "none", "element": "katon", "hair_style": "diken" if g == "m" else "uzun", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
		main._start_new_game()
		var pl = main.player
		await _wait(2.0)
		Hud.close_dialog()
		for id in ["bunshin_no_jutsu", "bunshin", "kage_bunshin_no_jutsu"]:
			if Data.jutsu.has(id):
				await _cast(pl, id, "dışarı_" + g)
		# akademi içi + uygulama sınavı
		var v = Game.village("konoha")
		var c = Game.from_map(Vector2(v["x"], v["y"]))
		for it in Interact.items:
			if it.get("kind", "") == "enter" and String(it.get("room", "")) == "academy" and Vector2(it["pos"].x - c.x, it["pos"].z - c.z).length() < float(v["r"]) * 1.3:
				pl.respawn(it["pos"] + Vector3(0, 0.3, 0))
				await _wait(1.0)
				Interiors.inst.enter(it)
				await _wait(2.0)
				break
		Exams.academy_practical()
		await _cast(pl, "bunshin_no_jutsu", "akademi_sınavı_" + g)
		Hud.close_dialog()
		await _cast(pl, "kage_bunshin_no_jutsu", "akademi_içi_" + g)
		Interiors.inst.exit()
		await _wait(1.5)
	print("BUN BİTTİ (çökme yok)")
	get_tree().quit()
