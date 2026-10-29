extends Node
## Toplu kontrol: harita su/kara düzeltmesi, çocuk klon boyu, pelerin kuyruk sınırı
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var t0 = Time.get_ticks_msec()
	if FileAccess.file_exists(Game.MAP_FIX):
		DirAccess.remove_absolute(Game.MAP_FIX)
	var before: Image = (load("res://data/world/map.png") as Texture2D).get_image()
	before.convert(Image.FORMAT_RGB8)
	Game._fix_map()
	var after = Image.load_from_file(Game.MAP_FIX)
	var diff = 0
	for y in range(0, after.get_height(), 2):
		for x in range(0, after.get_width(), 2):
			if after.get_pixel(x, y) != before.get_pixel(x, y):
				diff += 1
	print("BATCH map_fix ms=%d changed_px(1/4 sample)=%d" % [Time.get_ticks_msec() - t0, diff])
	after.save_png("D:/Naruto 3D Game/_tmp/shots/map_fixed.png")
	pl.model.apply_age("child")
	var cl = ShadowClone.new()
	cl.team = pl.team
	cl.look = pl.model.look.duplicate()
	get_tree().current_scene.add_child(cl)
	await get_tree().create_timer(0.3).timeout
	print("BATCH child_scale player=%.2f clone=%.2f" % [pl.model.scale.x, cl.model.scale.x])
	get_tree().quit()
