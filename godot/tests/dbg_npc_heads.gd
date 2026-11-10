extends Node
## Köyde en yakın NPC'lerin kafa yakın çekimi (ödünç/arka plan saç kontrolü)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Game.world.env.time_of_day = 0.45
	await get_tree().create_timer(14.0).timeout
	Hud.visible = false
	var life = main.actors.get_node_or_null("VillageLife")
	var pl = main.player
	var ms = []
	for n in life.npcs:
		if is_instance_valid(n):
			ms.append(n)
	ms.sort_custom(func(a, b): return a.global_position.distance_to(pl.global_position) < b.global_position.distance_to(pl.global_position))
	var cam = Camera3D.new()
	get_tree().current_scene.add_child(cam)
	cam.current = true
	var k = 0
	for n in ms.slice(0, 8):
		var cms = n.find_children("*", "CharacterModel", true, false)
		if cms.is_empty() or cms[0].skel == null:
			continue
		var sk: Skeleton3D = cms[0].skel
		var hd = cms[0].find_children("HairDangle*", "", true, false).size()
		var near = 0
		for o in ms:
			if o != n and o.global_position.distance_to(n.global_position) < 0.8:
				near += 1
		print("HEAD %d style=%s dangles=%d models=%d yakın_npc=%d" % [k, cms[0].look.get("hair_style"), hd, cms.size(), near])
		var hp = (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Head"))).origin + Vector3(0, 0.08, 0)
		var fwd = -cms[0].global_transform.basis.z
		cam.global_position = hp + fwd * 0.75 + Vector3(0, 0.04, 0)
		cam.look_at(hp)
		await get_tree().process_frame
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("D:/Naruto 3D Game/_tmp/shots/npchair/h%d.png" % k)
		k += 1
	print("HEADS %d" % k)
	get_tree().quit()
