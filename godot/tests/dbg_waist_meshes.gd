extends Node
## Bel hizasından geçen tüm mesh parçaları: ad, sınır kutusu, ebeveyn (beldeki kalın halkanın kaynağını bulmak için)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 98, "name": "T", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "s2", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.5).timeout
	var pl = main.player
	for sid in ["set_uchiha"]:
		Gear.grant(Game.profile, sid, "set")
		Gear.apply_look(Game.profile)
		pl.rebuild_model()
		await get_tree().create_timer(2.0).timeout
		var m = pl.model
		var hy = m.skel.global_transform * m.skel.get_bone_global_rest(m.skel.find_bone("Hips")).origin
		for mi in m.find_children("*", "MeshInstance3D", true, false):
			if not mi.visible or mi.mesh == null:
				continue
			var ab: AABB = mi.global_transform * mi.get_aabb()
			if ab.position.y < hy.y + 0.2 and ab.end.y > hy.y - 0.05:
				print("WM %s parent=%s size=%s y=[%.2f,%.2f] skin=%s" % [mi.name, mi.get_parent().name, ab.size, ab.position.y - hy.y, ab.end.y - hy.y, mi.skin != null])
	get_tree().quit()
