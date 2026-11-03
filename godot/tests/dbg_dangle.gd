extends Node
## İkincil hareket kontrolü: birkaç saç stili + bant; karakterler dururken / koşarken / dönünce yandan ve arkadan çekim.
## HAIR=stil1,stil2 env ile stil seçilebilir.
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	var v = Game.village("konoha")
	var base = Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500))
	base.y = Game.terrain_height(base.x, base.z)
	var styles = OS.get_environment("HAIR").split(",", false)
	if styles.is_empty():
		styles = PackedStringArray(["yuksek_kuyruk", "uzun", "ikiz_orgu", "savas_yelesi"])
	var ms = []
	for i in styles.size():
		var m = CharacterModel.new()
		main.add_child(m)
		m.setup({"gender": "f" if i % 2 == 1 else "m", "hair_style": styles[i], "hair": Color(0.15, 0.1, 0.3).lightened(i * 0.15), "top_style": "uzun", "band": Color(0.15, 0.2, 0.4), "band_style": "head", "village": "konoha"})
		m.global_position = base + Vector3(i * 1.2, 0, 0)
		m.play("idle")
		ms.append(m)
		print("DANGLES ", styles[i], " n=", m._dangles.size(), " chains=", m._dangles.map(func(d): return d.chains.size()))
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	var mid = base + Vector3((styles.size() - 1) * 0.6, 0, 0)
	cam.global_position = mid + Vector3(-1.0, 1.5, 3.0)
	cam.look_at(mid + Vector3(0, 1.2, 0))
	await get_tree().create_timer(1.2).timeout
	await main.shot("dg_rest_back")
	# koşu: +Z yönünde hızlanır (saç arkaya savrulmalı)
	for m in ms:
		m.play("run")
	var t = 0.0
	while t < 0.8:
		await get_tree().process_frame
		var dt = get_process_delta_time()
		t += dt
		for m in ms:
			m.global_position += Vector3(0, 0, -7.0 * dt)
		cam.global_position += Vector3(0, 0, -7.0 * dt)
	cam.global_position = ms[0].global_position + Vector3(-3.0, 1.3, 0.3) + Vector3((styles.size() - 1) * 0.6, 0, 0)
	cam.look_at(ms[0].global_position + Vector3((styles.size() - 1) * 0.6, 1.2, 0))
	await main.shot("dg_run_side")
	# ani dur: uçlar öne savrulur
	for m in ms:
		m.play("idle")
	await get_tree().create_timer(0.12).timeout
	await main.shot("dg_stop_side")
	for m in ms:
		for d in m._dangles:
			var tips = []
			for ci in d.chains.size():
				var rest: PackedVector3Array = d.chains[ci]["rest"]
				var tipw: Vector3 = d._p[ci][rest.size() - 1] if d._live else Vector3.ZERO
				tips.append(snappedf(tipw.distance_to(d.skel.global_transform * rest[rest.size() - 1]), 0.001))
			print("TIPDEV ", d.mi.name, " ", tips)
	await get_tree().create_timer(1.5).timeout
	await main.shot("dg_settle_side")
	# darbe
	for m in ms:
		m.react(Vector3(1, 0, 0), 1.0)
	await get_tree().create_timer(0.1).timeout
	await main.shot("dg_hit_side")
	get_tree().quit()
