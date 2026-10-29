extends Node
## Kiri: hikâye hedefleri ve etkileşim noktaları (pusula doğru yeri mi gösteriyor)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "suiton", "village": "kiri", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	print("TGT home=%s" % Progress.home())
	var v = Game.village(Progress.home())
	var c = Vector2(v["x"], v["y"])
	main.player.respawn(Game.from_map(c))
	await get_tree().create_timer(10.0).timeout
	for it in Interact.items:
		var m = Game.to_map(it["pos"])
		if m.distance_to(c) < float(v["r"]) * 1.6 and not it.get("interior", false) and String(it["kind"]) in ["academy", "enter", "mission_board", "training", "lookout", "kage", "anbu"]:
			print("TGT item kind=%s alias=%s off=%s text=%s" % [it["kind"], it.get("alias", ""), (m - c).round(), String(it.get("text", it.get("label", ""))).left(50)])
	Missions._story_cache.clear()
	for s in [0, 1, 4, 5, 6, 7]:
		var t = Missions.story_target_for(s)
		if not t.is_empty():
			print("TGT step %d %s off=%s" % [s, t["name"], (Game.to_map(t["pos"]) - c).round()])
	get_tree().quit()
