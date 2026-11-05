extends Node
## Bingo kitabı: "Takip Et" kitabı yeniden çizer — portredeki kişi aynı kalmalı

var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _sig() -> String:
	var out = []
	for m in get_tree().root.find_children("*", "CharacterModel", true, false):
		if m.get_viewport() is SubViewport and m.is_inside_tree() and not m.is_queued_for_deletion():
			var parts = []
			for n in m.find_children("*", "MeshInstance3D", true, false):
				if n.visible and n.mesh:
					parts.append("%s:%d" % [n.name, n.mesh.get_surface_count()])
			parts.sort()
			out.append("%d|%s" % [parts.size(), ",".join(parts).md5_text()])
	return " / ".join(out)


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "akimichi", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _wait(1.5)
	var ms = load("res://scripts/ui/menus.gd")
	print("entries=", Missions.bingo_entries().size())
	for idx in [0, 1, 2]:
		ms._bb_index = idx
		ms.bingo_book(main)
		await _wait(0.6)
		var e = Missions.bingo_entries()[idx]
		var s0 = _sig()
		await main.shot("bb_%d_a" % idx)
		Missions.track_bounty(int(e["id"]))
		ms.bingo_book(main)
		await _wait(0.6)
		var s1 = _sig()
		await main.shot("bb_%d_b" % idx)
		print("BB idx=%d id=%s before=[%s] after=[%s]" % [idx, e["id"], s0, s1])
	get_tree().quit()
