extends Node
## Alın koruyucu takılışları (önbellekli halka / saç işini beklemeyen kafa ölçümü kontrolü): her takılış iki kez kurulur
## (ikincisi önbellekten), önden ve arkadan çekilir. Sonra en yakın köylülerin yakın çekimi.
var main: Node
var OUT := (ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir() + "/_tmp/shots/bandchk/")
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "s2", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.2), "village": "konoha"}
	main._start_new_game()
	Game.world.env.time_of_day = 0.45
	await get_tree().create_timer(12.0).timeout
	Hud.visible = false
	var pl = main.player
	var cam = Camera3D.new()
	get_tree().current_scene.add_child(cam)
	cam.current = true
	cam.fov = 40.0
	var wears = ["alin", "kakashi", "zabuza", "sakura", "boyun", "bel", "kol", "kusak", "yamato", "kankuro", "kakuzu", "hiruzen"]
	var base = pl.global_position + Vector3(0, 0, -6.0)
	var k = 0
	for pass_i in 2:
		for i in wears.size():
			var lk = CharacterModel.default_look()
			lk["gender"] = "m" if i % 2 == 0 else "f"
			lk["hair_style"] = "s2" if i % 2 == 0 else "f2"
			lk["band"] = Color(0.15, 0.2, 0.45)
			lk["band_style"] = "head"
			lk["band_wear"] = wears[i]
			lk["face_id"] = i % 4
			var cm = CharacterModel.new()
			get_tree().current_scene.add_child(cm)
			var t0 = Time.get_ticks_usec()
			cm.setup(lk)
			print("BANDSHOT %s gecis=%d kurulum=%d ms" % [wears[i], pass_i, (Time.get_ticks_usec() - t0) / 1000])
			var at = base + Vector3(k * 3.0, 0, 0)
			at.y = Game.ground_height(at.x, at.z)
			cm.global_position = at
			await get_tree().process_frame
			await get_tree().process_frame
			for side in [1.0, -1.0]:
				var tg = at + Vector3(0, 1.32, 0)
				cam.global_position = tg + cm.global_transform.basis.z * (-2.1 * side) + Vector3(0.5 * side, 0.15, 0)
				cam.look_at(tg)
				await get_tree().process_frame
				await get_tree().process_frame
				get_viewport().get_texture().get_image().save_png(OUT + "b_%d_%02d_%s.png" % [pass_i, i, "on" if side > 0 else "arka"])
			cm.queue_free()
			k += 1
	# köylüler
	var life = main.actors.get_node_or_null("VillageLife")
	var ms = []
	for n in life.npcs:
		if is_instance_valid(n):
			ms.append(n)
	ms.sort_custom(func(a, b): return a.global_position.distance_to(pl.global_position) < b.global_position.distance_to(pl.global_position))
	var j = 0
	for n in ms.slice(0, 8):
		var cms = n.find_children("*", "CharacterModel", true, false)
		if cms.is_empty() or cms[0].skel == null:
			continue
		var tg2 = n.global_position + Vector3(0, 1.25, 0)
		cam.global_position = tg2 - cms[0].global_transform.basis.z * 2.3 + Vector3(0, 0.15, 0)
		cam.look_at(tg2)
		await get_tree().process_frame
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(OUT + "v_%d.png" % j)
		j += 1
	print("BANDSHOT bitti koylu=%d" % j)
	get_tree().quit()
