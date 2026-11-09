extends Node
## Saç ikincil hareketi: model hızla dönüp kayınca HairDangle zincir kemikleri dinlenme konumundan sapmalı
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "age": "adult", "clan": "none", "element": "katon", "village": "konoha", "hair_style": OS.get_environment("SV_H"), "hair": Color(0.85, 0.87, 0.92), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(3.0)
	var pl = main.player
	var dn = pl.model.find_children("HairDangle", "", true, false)
	print("MOTION dangle nodes=", dn.size())
	if dn.is_empty():
		get_tree().quit(); return
	var d = dn[0].get_parent()
	while d != null and not (d is Dangle):
		d = d.get_parent()
	var sk: Skeleton3D = d.skel if d else null
	print("MOTION chains=", d.chains.size() if d else -1, " bones=", sk.get_bone_count() if sk else -1)
	var mx = 0.0
	pl.set_physics_process(false)
	for f in 40:
		pl.model.rotation.y += 0.25
		pl.global_position.x += 0.08
		await get_tree().process_frame
		for b in range(1, sk.get_bone_count()):
			mx = maxf(mx, sk.get_bone_pose_position(b).distance_to(sk.get_bone_rest(b).origin))
	print("MOTION max_bone_offset=", mx)
	get_tree().quit()
