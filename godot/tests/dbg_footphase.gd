extends Node
## Ayak temas fazları: walk/jog/run döngüsünde sol/sağ ayağın en alçak olduğu ilerleme oranı
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var m = main.player.model
	main.player.set_physics_process(false)
	var sk: Skeleton3D = m.skel
	for an in ["walk", "jog", "run"]:
		m.play(an, 0.0)
		await get_tree().process_frame
		var ap: AnimationPlayer = m.anim
		var L = ap.current_animation_length
		var res = {"Left": [], "Right": []}
		for i in 40:
			ap.seek(L * i / 40.0, true)
			await get_tree().process_frame
			for side in ["Left", "Right"]:
				var bi = sk.find_bone(side + "Foot")
				res[side].append(sk.get_bone_global_pose(bi).origin.y)
		var out = []
		for side in ["Left", "Right"]:
			var arr: Array = res[side]
			var mi = 0
			for i in arr.size():
				if arr[i] < arr[mi]:
					mi = i
			out.append("%s min@%.2f" % [side, mi / 40.0])
		print("PHASE ", an, " len=", snappedf(L, 0.01), " ", out)
	get_tree().quit()
