extends Node
## SFProps silah yönü kalibrasyonu: her silah tutma noktası (kırmızı küre) orijinde, namlu +Z (mavi çizgi) boyunca.
## İkinci aşama: silahları karakterin eline takıp yakın çekim.
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.42
	main.world.env.region_weather = "açık"
	main.world.env.weather_t = 9999.0
	main.world.env.overcast = 0.0
	var pl = main.player
	await get_tree().create_timer(2.0).timeout
	pl.set_process(false)
	pl.set_physics_process(false)
	var base = pl.global_position + Vector3(4, 1.2, -4)
	var ids = SFProps.WEAPONS.keys()
	if OS.get_environment("IDS") != "":
		ids = OS.get_environment("IDS").split(",")
	var stage = OS.get_environment("STAGE")
	if stage == "":
		var i = 0
		for id in ids:
			var n = SFProps.weapon_node(id)
			if n == null:
				print("WPN YOK ", id)
				continue
			main.add_child(n)
			n.global_position = base + Vector3(0, -(i % 6) * 0.0, 0)
			var mk = MeshInstance3D.new()
			var sp = SphereMesh.new(); sp.radius = 0.03; sp.height = 0.06
			mk.mesh = sp
			var mm = StandardMaterial3D.new(); mm.albedo_color = Color.RED; mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mk.material_override = mm
			n.add_child(mk)
			var ln = MeshInstance3D.new()
			var bx = BoxMesh.new(); bx.size = Vector3(0.008, 0.008, 2.2)
			ln.mesh = bx
			var lm = StandardMaterial3D.new(); lm.albedo_color = Color(0.1, 0.3, 1); lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			ln.material_override = lm
			ln.position = Vector3(0, 0, 1.1)
			n.add_child(ln)
			var L = float(SFProps.WEAPONS[id]["len"])
			var c = base + Vector3(0, 0, L * 0.4)
			pl.cam.global_position = c + Vector3(L * 1.3 + 0.4, 0.15, 0)
			pl.cam.look_at(c)
			await get_tree().create_timer(0.3).timeout
			await main.shot("cal_%s" % id)
			n.queue_free()
			i += 1
		get_tree().quit()
		return
	if stage == "acc":
		for spec in [["head_style", "kage"], ["head_style", "kasa"], ["face_style", "anbu_kedi"], ["face_style", "kitsune"], ["face_style", "tengu"], ["face_style", "oni"], ["back_item", "kabak"], ["back_item", "sake"], ["back_item", "parsomen"]]:
			pl.model.queue_free()
			var lk = pl._look_with_age()
			lk[spec[0]] = spec[1]
			var m = CharacterModel.new()
			pl.add_child(m)
			m.setup(lk)
			pl.model = m
			m.rotation.y = pl.facing
			m.play("idle")
			await get_tree().create_timer(0.6).timeout
			var hp = pl.global_position + Vector3(0, 1.25 * m.age_scale, 0)
			for side in [0, 1]:
				var dir = pl.face_dir() if side == 0 else (-pl.face_dir() + pl.global_transform.basis.x).normalized()
				pl.cam.global_position = hp + dir * 1.4 + Vector3(0, 0.15, 0)
				pl.cam.look_at(hp)
				await get_tree().create_timer(0.2).timeout
				await main.shot("acc_%s_%d" % [spec[1], side])
		get_tree().quit()
		return
	# eldeki görünüm
	for id in ids:
		var it = Gear.item(id)
		var slot = "weapon_l" if String(it.get("slot", "")) == "sol" else "weapon_r"
		pl.model.queue_free()
		var lk = pl._look_with_age()
		lk["weapon_r"] = id
		lk["weapon_l"] = id if String(it.get("weapon", {}).get("style", "")) == "dual" else null
		var m = CharacterModel.new()
		pl.add_child(m)
		m.setup(lk)
		pl.model = m
		m.rotation.y = pl.facing
		m.play("idle")
		await get_tree().create_timer(0.6).timeout
		var hp = pl.global_position + Vector3(0, 1.1, 0)
		pl.cam.global_position = hp + pl.face_dir() * 1.25 + Vector3(0.7, 0.15, 0)
		pl.cam.look_at(hp)
		await get_tree().create_timer(0.2).timeout
		await main.shot("hand_%s" % id)
	get_tree().quit()
