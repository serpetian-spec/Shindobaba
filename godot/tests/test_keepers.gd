extends Node
## Köy sözleşme ustaları: her ustada [F] → diyalog seçenekleri → satın al (Chunin + Ryō) → sözleşme imzalı mı, çağırma çalışıyor mu
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	var pl = main.player
	await get_tree().create_timer(2.0).timeout
	Game.profile["rank"] = 2
	Game.profile["level"] = 30
	for it in Interact.items.duplicate():
		if it.get("kind", "") != "contract_keeper":
			continue
		var vid = String(it["village"])
		pl.respawn(it["pos"] + Vector3(0, 0.3, 2.0))
		await get_tree().create_timer(5.0).timeout
		Game.profile["ryo"] = 99999
		Progress.interact(it)
		await get_tree().create_timer(0.3).timeout
		var opts = Hud._last_opts if "_last_opts" in Hud else []
		print("KEEPER %s near=%.1f dialog=%s" % [vid, pl.global_position.distance_to(it["pos"]), Hud.dialog_open()])
		if vid == "kiri":
			await main.shot("keeper_dialog_kiri")
		for id in Contracts.DEFS:
			if String(Contracts.DEFS[id].get("keeper", "")) == vid and not Contracts.signed(id):
				var r0 = int(Game.profile["ryo"])
				var price = 800 + 400 * Contracts.DEFS[id]["tiers"].size()
				Progress.add_ryo(-price)
				Contracts._blood_sign(id)
				print("  SIGN %s signed=%s ryo_spent=%d" % [id, Contracts.signed(id), r0 - int(Game.profile["ryo"])])
				Game.profile["summon"] = id
				Contracts.summon(pl, {"id": "kuchiyose"})
				await get_tree().create_timer(1.5).timeout
				var n = 0
				for s in get_tree().get_nodes_in_group("fighters"):
					if s is Summon:
						n += 1
						s.queue_free()
				print("  SUMMON %s count=%d" % [id, n])
		Hud.close_dialog()
	get_tree().quit()
