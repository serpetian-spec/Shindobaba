extends Node
## Kaçak, köy ninjasıyla konuşmaya kalkar: konuşma yerine saldırı + köy alarmı; çevredeki ninjalar katılır
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	Orgs.flags()["rogue"] = true
	Orgs.flags()["rogue_from"] = "konoha"
	var pl = main.player
	pl.max_hp = 1e9; pl.hp = 1e9
	var vs = Game.village("konoha")
	pl.respawn(Game.from_map(Vector2(float(vs["x"]), float(vs["y"]))))
	await _w(4.0)
	Hud.close_dialog()
	var target = null
	var best = 1e9
	for v in get_tree().get_nodes_in_group("talkers"):
		if (v is Villager or v is ClanResident) and Friends.is_ninja(v) and not v.has_meta("friend_id"):
			var dd = v.global_position.distance_to(pl.global_position)
			if dd < best:
				best = dd
				target = v
	print("RTALK nearest ninja villager dist=%.0f name=%s" % [best, target.display if target else "-"])
	if target == null:
		get_tree().quit()
		return
	pl.global_position = target.global_position + Vector3(1.5, 0, 0)
	await _w(0.5)
	Orgs._raid = {}
	target.talk()
	await _w(3.0)
	var n = 0
	for e in get_tree().get_nodes_in_group("fighters"):
		if e is Enemy and not e.dead and e.target == pl:
			n += 1
	print("RTALK raid=%s hostile=%d dialog_open=%s" % [str(Orgs._raid.get("vid", "-")), n, Hud.has_method("dialog_open") and Hud.dialog_open()])
	get_tree().quit()
