extends Node
## AİLEN kartı: eş / mezun çocuk / küçük çocuk satırları tıklanır; küçük çocuk oyuncunun evinde yaşar
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _find_btn(n: Node, sub: String) -> Button:
	if n is Button and sub in n.text:
		return n
	for c in n.get_children():
		var r = _find_btn(c, sub)
		if r:
			return r
	return null

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pr = Game.profile
	var pl = main.player
	var sid = Friends.add_person("Aiko", {"gender": "f"}, 1, "villager", Progress.home(), pl.global_position + Vector3(10, 0, 0))
	Friends.all()[sid]["romance"] = "eş"
	pr["spouse"] = sid
	var gid = Friends.add_person("Uchiha Ren", {"gender": "m"}, 0, "villager", Progress.home(), pl.global_position + Vector3(20, 0, 0))
	pr["children"] = [{"name": "Uchiha Ren", "gender": "m", "clans": ["uchiha"], "born": 0.0, "grad": true},
		{"name": "Uchiha Mio", "gender": "f", "clans": ["uchiha"], "born": Time.get_unix_time_from_system()}]
	Menus.ninja_menu(main, "relations")
	await _w(0.5)
	var root = get_tree().root
	for s in ["Eşin: Aiko", "Oğlun: Uchiha Ren", "Kızın: Uchiha Mio"]:
		var b = _find_btn(root, s)
		print("FR1 %s -> %s" % [s, b.text if b else "YOK"])
	await main.shot("family_rows")
	_find_btn(root, "Eşin: Aiko").pressed.emit()
	await _w(0.4)
	print("FR2 spouse waypoint=%s find=%s" % [str(pr.get("waypoint")), str(pr.get("find_friend"))])
	_find_btn(root, "Kızın: Uchiha Mio").pressed.emit()
	await _w(0.4)
	print("FR3 home waypoint=%s" % str(pr.get("waypoint")))
	var door = {}
	for it in Interact.items:
		if String(it.get("room", "")) == "home_player":
			door = it
	Interiors.inst.enter(door)
	await _w(4.0)
	var kids = []
	for n in get_tree().get_nodes_in_group("talkers"):
		if "display" in n and String(n.display) == "Uchiha Mio":
			kids.append(n)
	print("FR4 inside=%s kid_nodes=%d" % [Interiors.inst.inside, kids.size()])
	if not kids.is_empty():
		var cc = Camera3D.new()
		get_tree().current_scene.add_child(cc)
		var o: Vector3 = Interiors.inst.origin
		cc.global_position = main.player.global_position + Vector3(0, 1.7, 0) + (main.player.global_position - kids[0].global_position).normalized() * 0.5
		print("FR5 dist=%.2f" % main.player.global_position.distance_to(kids[0].global_position))
		cc.look_at(kids[0].global_position + Vector3(0, 0.6, 0))
		cc.current = true
		await _w(0.3)
		await main.shot("family_kid_home")
	get_tree().quit()
