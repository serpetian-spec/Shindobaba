extends Node
## Düşman jinchūriki: can azaldıkça pelerin seviyeleri (kuyruk sayısı canavara göre), tam dönüşüm, form dağılınca geri dönüş

var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "akimichi", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl: Player = main.player
	var vs = Game.village("suna")
	var base = Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"]))
	pl.respawn(base)
	pl.max_hp = 1e9
	pl.hp = 1e9
	await _wait(2.0)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	# arketip indeksi -> canavar: 0 shukaku, 1 matatabi, 3 son_goku ; kurama ayrı
	for idx in [0, 1, 3, -1]:
		var a = Enemy.archetype("jinchuriki", maxi(0, idx))
		if idx == -1:
			a["beast"] = "kurama"
		var e := Enemy.new()
		e.setup(a)
		main.actors.add_child(e)
		e.global_position = pl.global_position + pl.face_dir() * 7.0
		e.target = pl
		var bid = String(a["beast"])
		var seq = []
		var shot_n = 0
		for step in 12:
			e.hp = e.max_hp * (1.0 - (step + 1) * 0.07)
			await _wait(0.6)
			var lv = int(e.get_meta("jin_lvl", 0))
			if seq.is_empty() or seq.back() != lv:
				seq.append(lv)
				var tl = (e.get_meta("jin_tails", []) as Array).size()
				print("JIN %s step %d hp=%.2f lvl=%d tails=%d form=%s" % [bid, step, e.hp / e.max_hp, lv, tl, e.has_meta("jin_form")])
				if idx == 1 and lv in [2, 5, 6] and shot_n < 3:
					shot_n += 1
					var form = e.get_meta("jin_form") if e.has_meta("jin_form") else null
					var ctr = (form.global_position + Vector3.UP * form.height * 0.4) if form else e.global_position + Vector3.UP * 1.0
					var dd = 40.0 if form else 4.5
					cc.global_position = ctr + pl.face_dir() * -1.0 * dd + Vector3(dd * 0.4, dd * 0.2, 0)
					cc.look_at(ctr)
					cc.current = true
					await _wait(0.1)
					await main.shot("jin_%s_%d" % [bid, lv])
					pl.cam.current = true
			if e.has_meta("jin_form"):
				break
		var form = e.get_meta("jin_form") if e.has_meta("jin_form") else null
		if form:
			form.take_hit({"dmg": form.max_hp * 2.0, "attacker": pl, "kind": "heavy"})
			await _wait(0.6)
			print("BROKEN %s host_visible=%s host_hp=%.2f spent=%s beast_freed=%s" % [bid, e.visible, e.hp / e.max_hp, e.get_meta("jin_spent", false), not is_instance_valid(form) or form.is_queued_for_deletion()])
		print("SEQ %s tails=%d -> %s" % [bid, BeastCloak.beast_tails(bid), seq])
		if is_instance_valid(e):
			e.queue_free()
		await _wait(0.5)
	get_tree().quit()
