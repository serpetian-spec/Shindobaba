extends Node
## Aynı karede 1 / 2 / 4 köylü girince o karenin ve sonraki iki karenin toplam süresi (betik + çizim tarafı). Sıcak önbellekle.
var main: Node
var _tp := 0
var _td := 0
var log := []
func _pf() -> void:
	_tp = Time.get_ticks_usec()
func _pre() -> void:
	_td = Time.get_ticks_usec()
	log.append([(_td - _tp) / 1000.0, 0.0])
func _post() -> void:
	if not log.is_empty():
		log[-1][1] = (Time.get_ticks_usec() - _td) / 1000.0
func _frame() -> float:
	var t = Time.get_ticks_usec()
	await get_tree().process_frame
	return (Time.get_ticks_usec() - t) / 1000.0
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await get_tree().create_timer(16.0).timeout
	Hud.close_dialog()
	seed(7)
	get_tree().process_frame.connect(_pf)
	RenderingServer.frame_pre_draw.connect(_pre)
	RenderingServer.frame_post_draw.connect(_post)
	var looks := []
	for i in 40:
		var vg = Villager.new()
		vg.role = ["walker", "shopper", "customer"][i % 3]
		vg.plan_look()
		while not CharacterModel.prepare(vg.look):
			await get_tree().process_frame
		looks.append([vg.role, vg.look])
		vg.free()
	# ısıt: her görünüş bir kez kurulur
	for lk in looks:
		var w = Villager.new(); w.role = lk[0]; w.look = lk[1].duplicate(true); w._planned = true
		main.add_child(w); w.global_position = main.player.global_position + Vector3(0, 0, -6)
		await get_tree().process_frame
		w.queue_free()
	await get_tree().create_timer(2.0).timeout
	var k = 0
	for cnt in [1, 1, 1, 2, 2, 4, 4, 1, 2, 4]:
		await get_tree().create_timer(0.6).timeout
		var base = await _frame()
		await get_tree().process_frame
		var t0 = Time.get_ticks_usec()
		log.clear()
		var made := []
		for j in cnt:
			var lk = looks[k % looks.size()]; k += 1
			var w = Villager.new(); w.role = lk[0]; w.look = lk[1].duplicate(true); w._planned = true
			main.add_child(w); w.global_position = main.player.global_position + Vector3(j * 1.2 - 2.0, 0, -6)
			made.append(w)
		var script_ms = (Time.get_ticks_usec() - t0) / 1000.0
		var f1 = await _frame()
		var f2 = await _frame()
		var f3 = await _frame()
		print("SF %d kisi | kurulum %.1f | sonraki kareler %.1f %.1f %.1f | bos kare %.1f | fazladan toplam %.1f (kisi basi %.1f)" % [cnt, script_ms, f1, f2, f3, base, script_ms + f1 + f2 + f3 - 3 * base, (script_ms + f1 + f2 + f3 - 3 * base) / cnt])
		var tx = ""
		for e in log.slice(0, 5):
			tx += " [isleyis %.0f cizim %.0f]" % [e[0], e[1]]
		print("SF    " + tx)
		await get_tree().create_timer(0.4).timeout
		for w in made:
			w.queue_free()
	# aşamalı ön kurulum: gizli tutucuda kur, bitince gövdeye tak; her karenin süresi
	var holder = Node3D.new()
	holder.visible = false
	main.add_child(holder)
	holder.position = Vector3(0, -900, 0)
	for rep in 6:
		await get_tree().create_timer(0.6).timeout
		var base2 = await _frame()
		await get_tree().process_frame
		var lk2 = looks[k % looks.size()]; k += 1
		log.clear()
		var m = CharacterModel.new()
		m.staged = true
		holder.add_child(m)
		m.setup(lk2[1].duplicate(true))
		var fr := []
		while not m.built:
			fr.append(await _frame())
		log.clear()
		var t1 = Time.get_ticks_usec()
		var w2 = Villager.new(); w2.role = lk2[0]; w2.look = lk2[1].duplicate(true); w2._planned = true
		holder.remove_child(m)
		m.position = Vector3.ZERO
		w2.model = m
		main.add_child(w2); w2.global_position = main.player.global_position + Vector3(0, 0, -6)
		var adopt = (Time.get_ticks_usec() - t1) / 1000.0
		var a1 = await _frame()
		var a2 = await _frame()
		var tx2 = ""
		for e in log.slice(0, 3):
			tx2 += " [isleyis %.0f cizim %.0f]" % [e[0], e[1]]
		print("ST bos %.1f | kurulum kareleri %s | takma %.1f | sonraki %.1f %.1f |%s" % [base2, str(fr.map(func(x): return snappedf(x, 0.1))), adopt, a1, a2, tx2])
		await get_tree().create_timer(0.4).timeout
		w2.queue_free()
	get_tree().quit()
