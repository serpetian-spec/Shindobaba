extends Node
## Ekran belleği ölçümü: Konoha'da doğ, köyde koş, VRAM dökümü yaz (4 GB kartlarda çökme avı).
## Kullanım: --test=res://tests/test_vram.gd

var main: Node
var pl: Player


func _dump(tag: String) -> void:
	var rs = RenderingServer
	var mb = 1048576.0
	print("VRAM %s: toplam %.0f MB  doku %.0f MB  tampon %.0f MB  | nesne %d  çizim %d  üçgen %d" % [tag,
		rs.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / mb,
		rs.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / mb,
		rs.get_rendering_info(RenderingServer.RENDERING_INFO_BUFFER_MEM_USED) / mb,
		rs.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		rs.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		rs.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
	print("   düğüm %d  kaynak %d  statik bellek %.0f MB" % [Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT), Performance.get_monitor(Performance.MEMORY_STATIC) / mb])


func _ready() -> void:
	await get_tree().process_frame
	_dump("menü")
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12),
		"top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	pl = main.player
	await get_tree().create_timer(3.0).timeout
	_dump("doğuş")
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	var cam = Camera3D.new()
	get_tree().current_scene.add_child(cam)
	cam.current = true
	var f = pl.face_dir()
	var i := 0
	for d in [[0.7, 1.55, 28.0], [2.6, 1.0, 45.0], [14.0, 3.0, 60.0]]:
		cam.fov = d[2]
		cam.global_position = pl.global_position + f * d[0] + Vector3.UP * d[1]
		cam.look_at(pl.global_position + Vector3.UP * (1.55 if i == 0 else 1.0))
		await get_tree().create_timer(0.6).timeout
		get_viewport().get_texture().get_image().save_png((ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir() + "/_tmp/kv/tex_%d.png") % i)
		i += 1
	print("VRAM BITTI")
	get_tree().quit()
