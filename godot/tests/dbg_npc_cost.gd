extends Node
## Köy NPC model kurulum maliyeti: rastgele köylü/ninja görünümleri, kurulum süresi + saç/giysi parçası dökümü
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(4.0).timeout
	CharacterModel.PROF = true
	for rnd in 2:
		for arch in ["worker", "merchant", "chunin", "genin", "elder", "kid", "jonin", "farmer"]:
			var lk = CharacterModel.default_look()
			lk.merge(Outfits.roll(arch, "konoha"), true)
			lk["gender"] = "f" if randf() < 0.5 else "m"
			if rnd == 1:
				lk["hair_style"] = "kısa"; lk["own_hair"] = true
			var cm = CharacterModel.new()
			get_tree().current_scene.add_child(cm)
			var t = Time.get_ticks_usec()
			cm.setup(lk)
			print("NPC r%d %s %s hair=%s  %.1fms" % [rnd, arch, lk["gender"], cm.look.get("hair_style"), (Time.get_ticks_usec() - t) / 1000.0])
			cm.queue_free()
			await get_tree().process_frame
	get_tree().quit()
