extends Node
## Suirō Sameodori: atan düşman teknik sürerken ölüp silinirse kubbe ve köpekbalıkları temizleniyor mu (kalıcı kubbe hatası)

var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _count_sharks() -> int:
	var n = 0
	for c in get_tree().current_scene.get_children():
		if c is MeshInstance3D and c.mesh is SphereMesh or (c is Node3D and String(c.name).to_lower().contains("shark")):
			n += 1
	return n


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "akimichi", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	await _wait(1.5)
	var before = get_tree().current_scene.get_child_count()
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	e.global_position = pl.global_position + pl.face_dir() * 6.0
	await _wait(0.5)
	var base = get_tree().current_scene.get_child_count()
	var ids = {}
	for ch in get_tree().current_scene.get_children():
		ids[ch.get_instance_id()] = true
	Jutsu.execute(e, "suiro_sameodori_no_jutsu", pl)
	await _wait(1.5)
	var during = get_tree().current_scene.get_child_count()
	print("SCENE children before=%d base=%d during=%d" % [before, base, during])
	e.queue_free()   # atan teknik sürerken silinir
	await _wait(1.5)
	var after = get_tree().current_scene.get_child_count()
	print("SCENE after caster freed=%d (base %d)" % [after, base])
	await _wait(9.0)
	var left = 0
	for ch in get_tree().current_scene.get_children():
		if not ids.has(ch.get_instance_id()) and ch is MeshInstance3D:
			left += 1
	print("LEFT new meshes after 9s=%d" % left)
	print("RESULT %s" % ("OK" if left == 0 else "LEAK"))
	get_tree().quit()
