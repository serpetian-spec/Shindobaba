extends Node
## Kovalama görevleri (Kaçak Kurye, Yankesici...): olay yeri açık zeminde mi, oraya gidince kaçak doğuyor mu, yakalanınca görev ilerliyor mu
var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	pl.max_hp = 1e9
	pl.hp = 1e9
	await _wait(2.0)
	Hud.close_dialog()
	var ok_n = 0
	var tries = 0
	Game.profile["rep"] = {"konoha": 100, "suna": 100, "kiri": 100, "kumo": 100, "iwa": 100}
	Game.profile["rank"] = 1
	for vid in ["kiri", "kumo", "iwa"]:
		var v = Game.village(vid)
		pl.respawn(Game.from_map(Vector2(v["x"], v["y"])) + Vector3(0, 2, 0))
		await _wait(3.0)
		for rep in 2:
			var m = {}
			for k in 120:
				for mm in Missions.board_missions(vid, true):
					if (mm.get("steps", []) as Array).any(func(st): return String(st.get("kind", "")) == "chase"):
						m = mm
						break
				if not m.is_empty():
					break
			if m.is_empty():
				print("CHASE %s görev bulunamadı" % vid)
				break
			tries += 1
			Missions.accept(m)
			await _wait(1.0)
			var mk: Vector3 = Missions.target_marker
			var gh = Game.ground_height(mk.x, mk.z)
			# oraya yürü (ışınla) ve adım geçsin
			pl.respawn(mk + Vector3(0, 1.0, 0))
			await _wait(2.0)
			var step = int(Game.profile["active_mission"].get("step", -1))
			var th = Missions.st.get("thief")
			var th_ok = th != null and is_instance_valid(th)
			var th_info = ""
			if th_ok:
				th_info = "thief_d=%.1f thief_y-gh=%.2f open=%s" % [th.global_position.distance_to(pl.global_position), th.global_position.y - Game.ground_height(th.global_position.x, th.global_position.z), Missions.open_ground(th.global_position, 0.5).distance_to(th.global_position) < 0.3]
				pl.respawn(th.global_position + Vector3(1.5, 1, 0))
				await _wait(1.0)
				th.take_hit({"dmg": 1e6, "attacker": pl, "kind": "heavy"})
				await _wait(2.0)
			var step2 = int(Game.profile["active_mission"].get("step", -1)) if not Game.profile["active_mission"].is_empty() else 99
			var good = step >= 1 and th_ok and step2 >= 2
			ok_n += 1 if good else 0
			print("CHASE %s '%s' marker_y-gh=%.2f step_after_goto=%d thief=%s %s step_after_catch=%d %s" % [vid, m.get("title", ""), mk.y - gh, step, th_ok, th_info, step2, "OK" if good else "HATA"])
			Missions.abandon()
			Game.profile["active_mission"] = {}
			await _wait(1.0)
	print("CHASE SONUÇ %d / %d" % [ok_n, tries])
	get_tree().quit()
