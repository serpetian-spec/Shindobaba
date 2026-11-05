extends Node
## Bingo kaçağı dünyada doğunca kitaptaki portreyle aynı kişi olmalı (saç, stil, cinsiyet, isim); iki kez doğsa da aynı

var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "akimichi", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _wait(1.0)
	var bad = 0
	var n = 0
	for e in Missions._bingo()["list"]:
		var book: Dictionary = Missions._bb_look(e)
		var seen = []
		for rep in 2:
			var before = get_tree().current_scene.find_children("*", "Enemy", true, false)
			Missions._bb_spawn(e, Game.player.global_position + Vector3(20 + rep * 5, 0, 0))
			await get_tree().process_frame
			var b: Enemy = null
			for x in get_tree().current_scene.find_children("*", "Enemy", true, false):
				if not x in before and x.has_meta("bingo_id") and int(x.get_meta("bingo_id")) == int(e["id"]):
					b = x
			if b == null:
				print("NOSPAWN ", e["id"])
				break
			var L: Dictionary = b.look
			seen.append([String(L.get("hair_style", "")), str(L.get("hair", "")), b.display_name])
			var diff = []
			for k in ["gender", "hair_style", "hair"]:
				if not e.has("legend_weapon") and str(L.get(k, "")) != str(book.get(k, "")):
					diff.append("%s %s->%s" % [k, book.get(k, ""), L.get(k, "")])
			if not diff.is_empty():
				bad += 1
				print("DIFF id=%d '%s' clan=%s %s" % [e["id"], b.display_name, e.get("clan", ""), diff])
			for x in get_tree().current_scene.find_children("*", "Enemy", true, false):
				if not x in before:
					x.queue_free()
			Missions._bb_spawned.erase(int(e["id"]))
			await get_tree().process_frame
		n += 1
		if seen.size() == 2 and seen[0] != seen[1]:
			bad += 1
			print("RESPAWN CHANGE id=%d %s vs %s" % [e["id"], seen[0], seen[1]])
	print("BINGO SPAWN entries=%d bad=%d" % [n, bad])
	get_tree().quit()
