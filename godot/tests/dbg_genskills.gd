extends Node
## Şifacı ve Sekiz Kapı teknikleri: her biri hatasız çalışıyor mu (+ birkaç kare)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "kase", "hair": Color(0.08, 0.08, 0.1), "top": Color(0.2, 0.5, 0.25), "pants": Color(0.2, 0.5, 0.25), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.1, 0.1, 0.1)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.0).timeout
	Hud.show_game_hud(false)
	pl.max_hp = 99999.0; pl.hp = 99999.0; pl.max_chakra = 9999.0; pl.chakra = 9999.0
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	var only = OS.get_environment("ONLY")
	var ids = [only] if only != "" else ["kage_shuriken_no_jutsu", "kage_senbon", "kanashibari_no_jutsu", "kasumi_jusha_no_jutsu", "oboro_bunshin_no_jutsu", "bubble_clone_technique", "bubitorappu", "chakura_kontororu_baku", "fujinheki", "genjutsu_shibari", "jouro_senbon", "kaeru_kaeru_no_jutsu", "genjutsu_suzune_bunshin", "karasu_bunshin_no_jutsu", "kawazu_kumite", "kumo_shibari"]
	for id in ids:
		var e = Enemy.new()
		var a = Enemy.archetype("bandit", 0)
		a["hp"] = 5000.0
		e.setup(a)
		get_tree().current_scene.add_child(e)
		e.global_position = pl.global_position + pl.face_dir() * 3.0
		e.home = e.global_position
		e.set_physics_process(false)
		var hp0 = e.hp
		pl.hp = 99999.0
		Jutsu.execute(pl, id, e)
		if OS.get_environment("ONLY") != "":
			print("PS2 dbg handles=%s fwd=%s near=%d" % [PathJutsu.handles_path(id), PathJutsu.get_pinst().fwd(pl, e), PathJutsu.get_pinst().enemies_near(pl, pl.global_position + PathJutsu.get_pinst().fwd(pl, e) * 6.0, 5.0).size()])
		if id == "kami_shuriken":
			e.global_position = pl.global_position + pl.face_dir() * 14.0
			var fw0 = pl.face_dir()
			cam.global_position = pl.global_position + fw0 * 3.0 + fw0.cross(Vector3.UP) * 2.5 + Vector3.UP * 1.6
			cam.look_at(pl.global_position + fw0 * 4.0 + Vector3.UP * 1.2)
			await get_tree().create_timer(0.2).timeout
			await main.shot("ps_kami_shuriken")
		await get_tree().create_timer(0.35).timeout
		if id in ["kage_shuriken_no_jutsu", "bubble_clone_technique", "chakura_kontororu_baku", "fujinheki", "genjutsu_shibari", "jouro_senbon", "kumo_shibari", "kasumi_jusha_no_jutsu"]:
			pl.set_process(false)
			var fw = pl.face_dir()
			if id == "kami_tsubasa":
				fw = -fw
			cam.global_position = pl.global_position + fw * 5.0 + fw.cross(Vector3.UP) * 3.0 + Vector3.UP * 2.0
			cam.look_at(pl.global_position + fw * 2.0 + Vector3.UP)
			if id == "kami_tsubasa":
				cam.global_position = pl.global_position + fw * 4.5 + Vector3.UP * 1.6
				cam.look_at(pl.global_position + Vector3.UP * 1.3)
			if id == "senpo_kawazu_naki":
				cam.global_position = pl.global_position + fw * 1.3 + fw.cross(Vector3.UP) * 0.5 + Vector3.UP * 1.55
				cam.look_at(pl.global_position + Vector3.UP * 1.4)
			await main.shot("ps_%s" % id)
			if id == "kami_tsubasa":
				await get_tree().create_timer(0.38).timeout
				await main.shot("ps_%s_b" % id)
			pl.set_process(true)
		await get_tree().create_timer(1.6).timeout
		print("GS %s enemy_dmg=%.0f player_hp=%.0f" % [id, hp0 - e.hp if is_instance_valid(e) else -1.0, pl.hp])
		if is_instance_valid(e):
			e.queue_free()
		await get_tree().create_timer(0.3).timeout
	get_tree().quit()
