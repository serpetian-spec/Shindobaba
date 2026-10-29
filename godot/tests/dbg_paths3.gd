extends Node
## 6 yeni efsane yolu: inler kuruldu mu, görevler oluşuyor mu, katılım ve tüm tekniklerin öğrenimi, inlerin görüntüsü
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	var pl = main.player
	print("P3 lairs=%s" % [LegendPaths.lairs.keys()])
	Game.profile["level"] = 30
	Game.profile["ryo"] = 999999
	var pids = ["kil", "kakuzu", "hiraishin", "chidori", "jashin", "hachibi"]
	for pid in pids:
		var q = LegendPaths._quest(pid, "trial", "")
		print("P3 %s trial=%s steps=%d" % [pid, q.get("title", "?"), q.get("steps", []).size()])
		for jid in LegendPaths.PATHS[pid]["quest"]:
			var qk = String(LegendPaths.PATHS[pid]["quest"][jid])
			var q2 = LegendPaths._quest(pid, qk, jid)
			print("P3 %s special(%s)=%s steps=%d" % [pid, qk, q2.get("title", "?"), q2.get("steps", []).size()])
		LegendPaths.set_state(pid, LegendPaths.JOINED)
		var miss = []
		for jid in LegendPaths.PATHS[pid]["order"]:
			if not Data.jutsu.has(jid):
				miss.append(jid)
			LegendPaths._teach(pid, jid, true)
		print("P3 %s learned_all=%s missing=%s passive_ok=%s" % [pid, LegendPaths.PATHS[pid]["order"].all(func(j): return j in Game.profile["learned"]), miss, LegendPaths.passive(Game.profile, LegendPaths.PATHS[pid]["passive"].keys()[0]) > 0.0])
	var shot_pid = OS.get_environment("PID") if OS.get_environment("PID") != "" else "kil"
	var lp = LegendPaths.lairs.get(shot_pid, [])
	if lp.is_empty():
		print("P3 no lair for ", shot_pid)
		get_tree().quit()
		return
	var w = Game.from_map(Vector2(lp[0], lp[1]))
	pl.respawn(w + Vector3(0, 0, 10))
	await get_tree().create_timer(4.0).timeout
	Hud.show_game_hud(false)
	pl.set_process(false)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.global_position = w + Vector3(-10, 7, 16)
	cam.look_at(w + Vector3(0, 1, -2))
	await get_tree().create_timer(0.5).timeout
	await main.shot("lair_" + shot_pid)
	get_tree().quit()
