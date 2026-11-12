extends Node
## Eskort: son yol noktası yapının içindeyken de görev biter mi (eskiden %97'de kalıyordu)
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "eye": Color(0.2, 0.4, 0.9), "skin": Color(0.96, 0.8, 0.66)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	var pl = main.player
	var q = Missions._q_escort(Progress.home(), "C")
	q["rank"] = "C"; q["village"] = Progress.home(); q["type"] = "quest"; q["giver"] = "Görev Masası"
	Missions.accept(q)
	await get_tree().create_timer(1.0).timeout
	# eskort adımına kadar ilerle
	for i in 6:
		if Missions._cur().get("kind") == "escort":
			break
		Missions._next_step()
		await get_tree().create_timer(0.5).timeout
	var s = Missions._cur()
	print("EE kind=", s.get("kind"))
	var npc = Missions.npcs.get(s.get("npc_id", ""))
	if npc == null:
		print("EE npc yok")
		get_tree().quit()
		return
	var a: Vector3 = npc.global_position
	var f = Vector3(1, 0, 0)
	var e = a + f * 14.0
	e.y = Game.ground_height(e.x, e.z)
	# son noktanın üstüne katı kutu
	var sb = StaticBody3D.new()
	var cs = CollisionShape3D.new()
	var bx = BoxShape3D.new()
	bx.size = Vector3(7, 8, 7)
	cs.shape = bx
	sb.add_child(cs)
	main.world.add_child(sb)
	sb.global_position = e + Vector3(0, 3, 0)
	npc.path = [a + f * 5.0, e]
	npc.path_i = 0
	var step0 = Missions.active().get("step", -1)
	for i in 60:
		pl.global_position = npc.global_position + Vector3(0, 0.3, 3.0)
		if OS.get_environment("EE_KEEP") == "":
			for en in Missions.step_nodes:
				if is_instance_valid(en) and en is Enemy:
					en.queue_free()
		await get_tree().create_timer(0.5).timeout
		var m = Missions.active()
		if m.is_empty() or int(m.get("step", -1)) != step0:
			print("EE bitti t=", i * 0.5, " s")
			break
		if i % 6 == 5:
			print("EE i=", i, " path_i=", npc.path_i, " d=", snappedf(npc.global_position.distance_to(e), 0.1))
	var m2 = Missions.active()
	print("EE sonuc gecti=", m2.is_empty() or int(m2.get("step", -1)) != step0)
	get_tree().quit()
