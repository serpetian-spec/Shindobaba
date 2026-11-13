extends Node
## Sabit deney: aynı 40 köylü (aynı tohum, aynı görünüşler) 0,3 sn arayla sahneye girer. SAB_MODE=sync (tek karede kurulum) |
## staged (sahne dışı aşamalı kurulum). Tüm karelerin süresi toplanır: 25 / 40 ms üstü kare sayısı, en uzun kare.
var main: Node
var fr: Array = []
var rec := false
var _l := 0
func _process(_dt: float) -> void:
	var n = Time.get_ticks_usec()
	if rec and _l > 0:
		fr.append((n - _l) / 1000.0)
	_l = n
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await get_tree().create_timer(4.0).timeout
	Hud.close_dialog()
	# sessiz yer: köyden uzak düz arazi (başka kişi kaynağı karışmasın)
	var v = Game.village("konoha")
	var q = Game.from_map(Vector2(float(v["x"]) + float(v["r"]) + 700.0, float(v["y"])))
	q.y = Game.ground_height(q.x, q.z) + 1.0
	main.player.global_position = q
	Game.profile["kd_wait"] = 99999.0
	await get_tree().create_timer(14.0).timeout
	seed(11)
	var roles = ["walker", "shopper", "patrol", "kid", "vendor", "worker", "sitter", "spar", "customer", "guard"]
	var looks := []
	for i in 40:
		var vg = Villager.new()
		vg.role = roles[i % roles.size()]
		vg.plan_look()
		var tr = 0
		while not CharacterModel.prepare(vg.look) and tr < 400:
			tr += 1
			await get_tree().process_frame
		looks.append([vg.role, vg.look])
		vg.free()
	await get_tree().create_timer(2.0).timeout
	var mode = OS.get_environment("SAB_MODE")
	# taban: kimse girmezken 6 sn
	rec = true
	await get_tree().create_timer(6.0).timeout
	rec = false
	var b = fr.duplicate()
	fr.clear()
	rec = true
	for lk in looks:
		var w = Villager.new(); w.role = lk[0]; w.look = lk[1].duplicate(true); w._planned = true
		if mode == "staged":
			var pm = await CharacterModel.staged_model(self, w.look)
			if pm != null:
				w.model = pm
		main.add_child(w)
		w.global_position = main.player.global_position + Vector3(randf() * 16.0 - 8.0, 0, -5.0 - randf() * 10.0)
		await get_tree().create_timer(0.3).timeout
	await get_tree().create_timer(1.0).timeout
	rec = false
	b.sort()
	var fs = fr.duplicate()
	fs.sort()
	print("SAB %-6s taban: p50 %.1f en uzun %.1f | giris: kare %d p50 %.1f p99 %.1f en uzun %.1f | >25ms %d | >33ms %d | >40ms %d (taban >25ms %d)" % [mode, b[b.size() / 2], b[-1], fs.size(), fs[fs.size() / 2], fs[int(fs.size() * 0.99)], fs[-1],
		fs.filter(func(x): return x > 25.0).size(), fs.filter(func(x): return x > 33.0).size(), fs.filter(func(x): return x > 40.0).size(), b.filter(func(x): return x > 25.0).size()])
	get_tree().quit()
