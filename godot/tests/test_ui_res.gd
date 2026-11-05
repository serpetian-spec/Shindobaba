extends Node
## Küçük ekranlarda menü taşıyor mu: Gözler ve Görevler sekmesi; pencere boyutu ve görünür alan yazdırılır
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Hud.close_dialog()
	var want = Vector2i(1920, 1080)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--win="):
			var pp = a.substr(6).split("x")
			want = Vector2i(int(pp[0]), int(pp[1]))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	get_window().size = want
	await get_tree().create_timer(0.5).timeout
	var tag = "%dx%d" % [get_window().size.x, get_window().size.y]
	print("UIRES window=%s visible_rect=%s scale_factor=%.2f" % [tag, get_viewport().get_visible_rect().size, get_tree().root.content_scale_factor])
	for tab in Menus.TABS.map(func(t): return t[0]):
		Menus.ninja_menu(main, tab)
		await get_tree().create_timer(0.5).timeout
		# taşan kontroller: görünür alanın dışına çıkan en sağ kenar
		var vr = get_viewport().get_visible_rect().size
		var maxx = 0.0
		for c in Hud.dialog_layer.find_children("*", "Control", true, false):
			if c.is_visible_in_tree() and c.size.x > 0:
				maxx = maxf(maxx, c.get_global_rect().end.x)
				if c.get_global_rect().end.x > vr.x + 2 and c.get_global_rect().position.x < vr.x:
					print("  OVER %s %s %s txt=%s" % [tab, c.get_class(), c.get_global_rect(), String(c.get("text")).left(40) if c.get("text") != null else ""])
		print("UIRES %s tab=%s max_right=%.0f visible_w=%.0f TAŞMA=%s" % [tag, tab, maxx, vr.x, maxx > vr.x + 2])
		await main.shot("ui_%s_%s" % [tag, tab])
	get_tree().quit()
