extends Node
## Geliştirme sunucusu: oyun açık kalır; _tmp/dev/cmd.gd belirince onu derleyip çalıştırır (her kontrolde oyunu baştan açma).
## Komut betiği: `extends Node` + `func run(main) -> void` (await kullanabilir). Bitince _tmp/dev/done.txt yazılır.
## DEV_SAVE boşsa yeni oyun açılır (Konoha); "quit" yazan komut sunucuyu kapatır.
var main: Node
var DIR := (ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir() + "/_tmp/dev")


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	print("DEV hazir")
	FileAccess.open(DIR.path_join("ready.txt"), FileAccess.WRITE).store_string("ok")
	while true:
		await get_tree().create_timer(0.4).timeout
		var cp = DIR.path_join("cmd.gd")
		if not FileAccess.file_exists(cp):
			continue
		var src = FileAccess.get_file_as_string(cp)
		DirAccess.remove_absolute(cp)
		if src.strip_edges() == "quit":
			get_tree().quit()
			return
		# "#reload: res://a.gd, res://b.gd" satırı: o betikler diskten açık oyuna yeniden yüklenir (Godot'yu baştan açmadan kod değişikliği)
		for line in src.split("
"):
			if line.begins_with("#reload:"):
				for path in line.substr(8).split(",", false):
					var sp = path.strip_edges()
					var scr: GDScript = load(sp)
					scr.source_code = FileAccess.get_file_as_string(sp)
					var rerr = scr.reload(true)
					print("DEV reload %s -> %d" % [sp, rerr])
		var sc = GDScript.new()
		sc.source_code = src
		var err = sc.reload()
		var res = "ok"
		if err != OK:
			res = "derleme hatasi %d" % err
		else:
			var n: Node = sc.new()
			add_child(n)
			if n.has_method("run"):
				await n.run(main)
			n.queue_free()
		FileAccess.open(DIR.path_join("done.txt"), FileAccess.WRITE).store_string(res)
