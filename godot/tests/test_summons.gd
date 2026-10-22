extends Node
## Çağırma sözleşmeleri testi: her sözleşmenin her kademesi oyuncunun yanında, sennin modu yüzleri,
## kurbağa + katon ortak jutsusu, binme, gizli diyarlar.
var main: Node


func _shot(pl: Node3D, name: String, dist: float, height: float, side := 0.6) -> void:
	var c = pl.global_position
	var cam: Camera3D = pl.cam
	pl.set_process(false)
	cam.global_position = c + Vector3(side * dist, height, dist)
	cam.look_at(c + Vector3(0, height * 0.45, 0))
	await get_tree().create_timer(0.35).timeout
	await main.shot(name)


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "kısa", "hair": Color(0.25, 0.15, 0.1), "top": Color(0.95, 0.5, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var pr = Game.profile
	pr["level"] = 40
	pr["rank"] = 3
	pl.apply_profile_stats()
	Contracts.ensure()
	for id in Contracts.DEFS:
		pr["contracts"][id] = {"mastery": 500.0, "sage": Contracts.DEFS[id]["sage"], "sage_trials": 3}
	var spot = Game.from_map(Vector2(-27000, -14000))  # açık arena (Kum Fırtınası Düzlüğü)
	pl.respawn(spot)
	await get_tree().create_timer(2.5).timeout
	var n_ok = 0
	var n_err = 0
	for id in Contracts.DEFS:
		for t in Contracts.DEFS[id]["tiers"]:
			pr["summon"] = id
			pl.chakra = 9999.0
			pl.max_chakra = 9999.0
			var before = get_tree().get_nodes_in_group("summons").size()
			# kademeyi zorla: geçici olarak diğer kademeleri gizle
			var d: Dictionary = Contracts.DEFS[id]["tiers"][t]
			var s = Summon.new()
			s.contract = id
			s.tier = t
			s.def = d
			s.owner_f = pl
			s.team = pl.team
			get_tree().current_scene.add_child(s)
			s.global_position = pl.global_position + pl.face_dir() * (2.5 + d["h"] * 0.6) + Vector3(2.0, 0, 0)
			s.global_position.y = Game.ground_height(s.global_position.x, s.global_position.z)
			s.facing = pl.facing + PI
			await get_tree().create_timer(0.6).timeout
			if is_instance_valid(s) and not s.dead:
				n_ok += 1
			else:
				n_err += 1
			var big = maxf(d["h"], d.get("len", 0.0) * 0.5)
			await _shot(pl, "sm_%s_%d" % [id, t], 3.0 + big * 1.4, 1.5 + d["h"] * 0.8)
			pl.set_process(true)
			if is_instance_valid(s):
				s.dismiss()
			await get_tree().create_timer(0.3).timeout
	print("SUMMON OK=", n_ok, " ERR=", n_err)
	# gerçek Kuchiyose akışı (çember + duman, en iyi kademe)
	pr["summon"] = "kurbağa"
	pl.chakra = 9999.0
	Contracts.summon(pl, Data.jutsu.get("kuchiyose", {"id": "kuchiyose", "cost": 20}))
	await get_tree().create_timer(0.2).timeout
	await _shot(pl, "sm_kuchiyose_cember", 14.0, 6.0)
	pl.set_process(true)
	await get_tree().create_timer(1.6).timeout
	var toad: Summon = null
	for s in get_tree().get_nodes_in_group("summons"):
		toad = s
	print("KUCHIYOSE tier=", toad.tier if toad else -1, " model=", toad.def.get("model", "") if toad else "")
	await _shot(pl, "sm_kuchiyose_sonra", 30.0, 14.0)
	pl.set_process(true)
	# ortak jutsu: katon + kurbağa yağı
	var en = Enemy.new()
	get_tree().current_scene.add_child(en)
	en.global_position = pl.global_position + pl.face_dir() * 25.0
	await get_tree().create_timer(0.5).timeout
	if toad:
		toad.tgt = en
		toad.combo("katon")
		await get_tree().create_timer(0.25).timeout
		await _shot(pl, "sm_combo_yag_ates", 30.0, 12.0, 1.4)
		pl.set_process(true)
		print("COMBO cd=", toad.combo_cd)
		# binme
		pl.global_position = toad.global_position + Vector3(toad.radius + 1.0, 0, 0)
		toad.mounted = true
		pl.set_meta("riding", toad)
		await get_tree().create_timer(0.6).timeout
		await _shot(pl, "sm_binme", 30.0, 10.0)
		pl.set_process(true)
		toad._dismount()
	# sennin modu yüzleri
	for s2 in get_tree().get_nodes_in_group("summons"):
		s2.dismiss()
	pl.respawn(spot)
	await get_tree().create_timer(1.0).timeout
	for k in ["kurbağa", "yılan", "sümüklü"]:
		pl.combat.modes.sage_kind = k
		pl.combat.modes._enter_sage()
		await get_tree().create_timer(0.3).timeout
		pl.set_process(false)
		var em: MeshInstance3D = pl.model.eyes_mesh
		var hp = em.global_transform * em.get_aabb().get_center()
		pl.model.play("idle", 0.0)
		pl.cam.global_position = hp + pl.face_dir() * 0.3 + Vector3(0, -0.04, 0)
		pl.cam.look_at(hp)
		await get_tree().create_timer(0.3).timeout
		await main.shot("sm_sennin_%s" % k)
		pl.set_process(true)
		pl.combat.modes._end_sage()
	# gizli diyarlar
	for k in ["kurbağa", "yılan", "sümüklü"]:
		var rp = ContractRealms.realm_pos(k)
		print("REALM ", k, " ", rp)
		if rp != Vector3.ZERO:
			pl.respawn(rp + Vector3(0, 0.5, 8.0))
			await get_tree().create_timer(2.0).timeout
			await _shot(pl, "sm_diyar_%s" % k, -45.0, 22.0, 0.3)
			pl.set_process(true)
	get_tree().quit()
