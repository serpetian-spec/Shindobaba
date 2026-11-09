extends SceneTree
func _init() -> void:
	var AH = load("res://scripts/actors/anime_hair.gd")
	var tot = 0
	var worst = ["", 0]
	for st in AH.STYLES:
		var t0 = Time.get_ticks_usec()
		AH.build(st, Vector3(0, 1.6, 0), Vector3(0.1, 0.1, 0.07), false)
		var dt = Time.get_ticks_usec() - t0
		tot += dt
		if dt > worst[1]: worst = [st, dt]
	print("COST n=", AH.STYLES.size(), " avg_ms=", tot / 1000.0 / AH.STYLES.size(), " worst=", worst[0], " ", worst[1] / 1000.0)
	quit()
