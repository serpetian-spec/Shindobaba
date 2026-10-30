extends Node
## Kaçak dostluğu: pes etme -> bağışla -> kamp -> kamp ateşi -> seçenekler -> ortak iş -> köyde görülme -> Kage ültimatomu
var main: Node


func _press(prefix: String) -> bool:
	for b in Hud.dialog_layer.find_children("*", "Button", true, false):
		if String(b.text).begins_with(prefix):
			b.pressed.emit()
			return true
	return false


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	Game.profile["level"] = 25
	Game.profile["rank"] = 2
	Game.profile["ryo"] = 5000
	var spot = Missions._spot("konoha", 300, 500)
	pl.global_position = Game.from_map(Vector2(spot[0], spot[1])) + Vector3(0, 2, 0)
	await get_tree().create_timer(2.0).timeout
	var a = Enemy.archetype("rogue", 1)
	a["respawn"] = false
	a["name"] = "Kaçak Ninja Ryūga"
	var e = Enemy.new()
	e.setup(a)
	get_tree().current_scene.add_child(e)
	e.global_position = pl.global_position + pl.face_dir() * 4.0
	e.home = e.global_position
	await get_tree().create_timer(0.5).timeout
	e.take_hit({"dmg": e.max_hp * 0.8, "attacker": pl, "kind": "light", "dir": pl.face_dir(), "melee": true})
	await get_tree().create_timer(0.8).timeout
	print("ROGUE yielded=", e.has_meta("yielded"), " team=", e.team)
	await main.shot("rogue_yield")
	print("ROGUE spare pressed=", _press("Bağışla"))
	Menus.clear()
	await get_tree().create_timer(0.5).timeout
	var id = ""
	for k in Friends.all():
		if Friends.all()[k].get("rogue", false):
			id = k
	var f: Dictionary = Friends.all()[id]
	print("ROGUE friend=", f["name"], " status=", f["status"], " bond=", f["bond"], " motive=", f["motive"], " where=", Friends.where(id))
	# kampına git
	var lp = Friends.where(id)
	var cam = get_viewport().get_camera_3d()
	var cf = -cam.global_transform.basis.z
	cf.y = 0
	var p0 = lp - cf.normalized() * 9.0
	p0.y = Game.ground_height(p0.x, p0.z) + 0.3
	pl.global_position = p0
	await get_tree().create_timer(4.0).timeout
	var n = null
	for x in get_tree().get_nodes_in_group("talkers"):
		if String(x.get_meta("friend_id", "")) == id:
			n = x
	print("ROGUE at lair node=", n != null)
	await main.shot("rogue_lair")
	var labels = Friends._friend_opts(id, n).map(func(o): return o["label"])
	print("ROGUE opts=", labels)
	Menus.clear()
	RogueBonds.campfire(id)
	await get_tree().create_timer(4.5).timeout
	await main.shot("rogue_campfire")
	await get_tree().create_timer(9.0).timeout
	print("ROGUE after campfire bond=", f["bond"])
	f["bond"] = 45
	RogueBonds._job(id, "avci")
	await get_tree().create_timer(1.0).timeout
	print("ROGUE job=", Missions.active().get("title"), " party=", f.get("party"))
	Missions.abandon()
	f["party"] = true
	# köye girip devriyeye görün x3 -> ültimatom
	for k in 3:
		Game.profile["flags"]["rogue_seen_t"] = 0.0
		f["party"] = true
		pl.global_position = Progress.home_spawn() + Vector3(0, 1, 0)
		await get_tree().create_timer(2.5).timeout
	print("ROGUE seen=", Game.profile["flags"].get("rogue_seen"), " party=", f["party"], " waiting=", f.get("waiting"))
	await get_tree().create_timer(2.0).timeout
	await main.shot("rogue_ultimatum")
	print("ROGUE ultimatum shown=", _press("Onu teslim"), " status=", f["status"])
	Menus.clear()
	get_tree().quit()
