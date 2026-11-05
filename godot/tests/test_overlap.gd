extends Node
## Köy kurulurken iç içe ev engeli: kaç ev kaydırıldı / atlandı; Konoha'dan kuşbakışı görüntü
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	var t0 = Time.get_ticks_msec()
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	print("OVL kaydırılan=%d atlanan=%d gerçek-çakışma=%d  (%.0f sn) %s" % [Builder.overlap_moved, Builder.overlap_skipped, Builder.overlap_post, (Time.get_ticks_msec() - t0) / 1000.0, str(Builder.overlap_log)])
	Hud.close_dialog()
	var v = Game.village("konoha")
	var c = Game.from_map(Vector2(v["x"], v["y"]))
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	for k in 3:
		var off = [Vector3(-300, 0, 150), Vector3(250, 0, 250), Vector3(150, 0, -300)][k]
		var at = c + off
		at.y = Game.ground_height(at.x, at.z)
		main.player.respawn(at)
		await get_tree().create_timer(3.0).timeout
		cc.global_position = at + Vector3(40, 70, 40)
		cc.look_at(at)
		cc.current = true
		Hud.close_dialog()
		await get_tree().create_timer(0.3).timeout
		await main.shot("ovl_%d" % k)
	get_tree().quit()
