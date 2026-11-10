extends Node
## Ödünç saç oturuşu: aynı stil, yüz 0'da hesaplanıp yüz N'ye ödünç takılan ile yüz N'de yerli hesaplanan saç kutusu (kafatasına göre)
var main: Node
func _box(cm) -> String:
	var ab = AABB(cm._anime_hair_vs[0], Vector3.ZERO)
	for q in cm._anime_hair_vs:
		ab = ab.expand(q)
	var c = (ab.get_center() - cm.skull_c) / cm.skull_r
	var sz = ab.size / (cm.skull_r * 2.0)
	return "%s merkez=(%.2f,%.2f,%.2f) boy=(%.2f,%.2f,%.2f)" % [cm.look["hair_style"], c.x, c.y, c.z, sz.x, sz.y, sz.z]
func _mk(fi: int, style: String, keep: bool):
	var lk = CharacterModel.default_look()
	lk.merge(Outfits.roll("worker", "konoha"), true)
	lk["gender"] = "f"; lk["face_id"] = fi; lk["hair_style"] = style; lk["age"] = "adult"; lk["npc"] = true; lk["band"] = null; lk["keep_hair"] = keep
	var cm = CharacterModel.new()
	get_tree().current_scene.add_child(cm)
	cm.setup(lk)
	return cm
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	for fi in [1, 2, 3, 4]:
		CharacterModel._hair_lock_static()
		CharacterModel._hair_cache.clear(); CharacterModel._hair_dyn.clear(); CharacterModel._hair_vs_cache.clear()
		var a = _mk(0, "f1", true)
		var b = _mk(fi, "f2", false)   # f2 önbellekte yok -> f1 (yüz 0) ödünç
		var bs = _box(b)
		CharacterModel._hair_lock_static()
		var c = _mk(fi, "f1", true)
		print("BORROW yüz=%d  ödünç: %s  |  yerli: %s" % [fi, bs, _box(c)])
		a.queue_free(); b.queue_free(); c.queue_free()
		await get_tree().process_frame
	get_tree().quit()
