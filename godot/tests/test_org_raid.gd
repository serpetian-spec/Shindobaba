extends Node
## Örgüt Tapınak Baskını: kamp düşmanları oyuncuyu kovalayıp uzakta kalınca, oyuncu kampa dönünce geri geliyorlar mı, işaretçi doğru mu, adım ilerliyor mu

var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "akimichi", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pr = Game.profile
	pr["level"] = 46
	var pl: Player = main.player
	pl.max_hp = 1e9
	pl.hp = 1e9
	await _wait(1.0)
	var orgs = Orgs.random_orgs()
	var o = null
	for x in orgs:
		if String(x["goal"]) == "Yasak parşömenleri toplamak":
			o = x
	if o == null:
		o = orgs[0]
		o["goal"] = "Yasak parşömenleri toplamak"
	var m = Orgs.ro_goal_job(o)
	print("JOB ", m.get("title", "?"))
	Missions.accept(m)
	await _wait(1.0)
	var c: Vector3 = Missions.target_marker
	pl.respawn(c + Vector3(20, 1, 0))
	pl.hp = 1e9
	await _wait(3.0)
	print("LAIR ", Missions.st.get("lair", ""), " step_nodes=", Missions.step_nodes.size(), " n=", Missions._cur().get("n"))
	for nd in Missions.step_nodes:
		if is_instance_valid(nd):
			print("  node ", nd.get_class(), " ", nd.name, " d=", nd.global_position.distance_to(c) if nd is Node3D else -1)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	for k in 2:
		cc.global_position = c + [Vector3(14, 6, 10), Vector3(-12, 5, -14)][k]
		cc.look_at(c + Vector3.UP * 2)
		cc.current = true
		Hud.close_dialog()
		await _wait(0.3)
		await main.shot("lair_%d" % k)
	pl.cam.current = true
	var es = Missions.step_nodes.filter(func(e): return is_instance_valid(e) and e is Enemy)
	print("CAMP enemies=", es.size(), " marker_d=", Missions.target_marker.distance_to(c))
	# kovalayıp uzakta kalsınlar: oyuncu 200 m öteye, düşmanlar onu hedef alarak 150 m öteye
	var far = c + Vector3(200, 0, 0)
	far.y = Game.ground_height(far.x, far.z)
	pl.respawn(far + Vector3.UP)
	for e in es:
		e.global_position = Vector3(far.x - 50, Game.ground_height(far.x - 50, far.z), far.z)
		e.target = pl
	await _wait(2.0)
	print("FAR marker -> nearest enemy d=", Missions.target_marker.distance_to(es[0].global_position) if not es.is_empty() and is_instance_valid(es[0]) else -1.0)
	# kampa dön
	pl.respawn(c + Vector3(6, 1, 0))
	pl.hp = 1e9
	await _wait(3.5)
	var back = 0
	for e in es:
		if is_instance_valid(e) and e.global_position.distance_to(c) < 40.0:
			back += 1
	print("BACK at camp=", back, "/", es.size(), " marker_d=", Missions.target_marker.distance_to(c))
	# hepsini kes: adım ilerlemeli
	for e in Missions.step_nodes.filter(func(x): return is_instance_valid(x) and x is Enemy and not x.dead):
		while is_instance_valid(e) and not e.dead:
			e.take_hit({"dmg": 400.0, "attacker": pl, "kind": "light", "knock": 1.0, "dir": Vector3.FORWARD, "melee": true})
			await _wait(0.1)
	await _wait(2.0)
	print("STEP now=", Missions._cur().get("kind", "?"), " text=", Missions._cur().get("text", ""))
	print("NAMEPLATE sample=", es[0].nameplate.text if not es.is_empty() and is_instance_valid(es[0]) and es[0].nameplate else "-")
	get_tree().quit()
