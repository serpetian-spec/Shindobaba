extends Node
## Veri güdümlü jutsu motoru testi:
## 1) tüm jutsuları (673) sırayla çalıştırır, sayar ("CAST i/n id")  2) çeşitli şekil/element örneklerinin ekran görüntüleri
## 3) öğrenme yolu / doğa / göz şartı kontrolleri

var main: Node
const SAMPLES := [
	"katon_endan", "suiton_suidan_no_jutsu", "futon_kazekiri_no_jutsu", "raiton_jibashi", "doton_doryudan",
	"suiton_daibakufu_no_jutsu", "katon_goka_mekkyaku", "futon_atsugai", "suiro_no_jutsu", "ranton_reiza_sakasu",
	"mokuton_jukai_kotan", "hyoton_hyogan_domu", "yoton_yokai_no_jutsu", "bakuton_jiraiken", "kirigakure_no_jutsu",
	"kage_nui_no_jutsu", "doton_doryu_joheki", "magen_jubaku_satsu", "shiki_fujin", "mizu_bunshin_no_jutsu",
	"konoha_senpu", "katon_dai_endan", "chakra_chains", "futton_komu_no_jutsu", "jibaku_bunshin", "kanchi_no_jutsu",
	"suna_no_yoroi", "sennin_modo", "raiton_rariatto", "hiraishin_no_jutsu", "doton_goremu_no_jutsu", "sozo_saisei",
	"futon_shinku_renpa", "jinton_genkai_hakuri_no_jutsu", "kakuremino_no_jutsu", "uchihagaeshi", "bashosen_kaze_no_maki",
]


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _enemy(pos: Vector3) -> Enemy:
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	e.global_position = pos
	e.home = pos
	e.lose_target(999)
	e.state = "idle"
	e.max_hp = 1e9
	e.hp = 1e9
	return e


func _clear() -> void:
	for pr in get_tree().get_nodes_in_group("projectiles"):
		pr.queue_free()
	for w in get_tree().get_nodes_in_group("element_walls"):
		if is_instance_valid(w):
			w.queue_free()
	for f in get_tree().get_nodes_in_group("fighters"):
		if f is ShadowClone or f is Summon:
			f.queue_free()


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.08, 0.08, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	Game.world.env.weather = "açık"
	var v := Game.village("konoha")
	var base := Game.from_map(Vector2(v["x"] + 300, v["y"] + 140))
	pl.respawn(base)
	pl.max_hp = 1e9
	pl.hp = 1e9
	pl.max_chakra = 1e9
	pl.chakra = 1e9
	pl.yaw = 0.0
	pl.pitch = -12.0
	pl.cam_dist = 11.0
	var pr = Game.profile
	pr["level"] = 60
	pr["rank"] = 4
	pr["elements"] = ["katon", "suiton", "fuuton", "doton", "raiton"]
	await _wait(1.5)
	var fwd: Vector3 = pl.cam_forward()
	fwd.y = 0
	fwd = fwd.normalized()
	var e1 = _enemy(base + fwd * 12.0)
	var e2 = _enemy(base + fwd * 15.0 + fwd.cross(Vector3.UP) * 3.0)
	var e3 = _enemy(base + fwd * 9.0 - fwd.cross(Vector3.UP) * 3.0)
	await _wait(0.5)

	# --- 3) öğrenme şartları
	print("NATURE katon=", Progress.has_nature("katon"), " mokuton=", Progress.has_nature("mokuton"))
	print("CANLEARN mokuton_jukai_kotan='", Progress.can_learn("mokuton_jukai_kotan"), "'")
	Progress.awaken_nature("mokuton", false)
	print("CANLEARN after awaken='", Progress.can_learn("mokuton_jukai_kotan"), "'  amaterasu='", Progress.can_learn("amaterasu"), "'")
	print("TRAINER konoha opts=", Progress.village_trainer_options("konoha").size(), " scrolls=", Progress.scroll_shop_items().size())

	# --- 2) örnek ekran görüntüleri
	var shot_i = 0
	for jid in SAMPLES:
		if not Data.jutsu.has(jid):
			print("SAMPLE YOK: ", jid)
			continue
		pl.global_position = base
		pl.facing = atan2(-fwd.x, -fwd.z)
		Jutsu.execute(pl, jid, e1)
		var d: Dictionary = Data.jutsu[jid]
		await _wait(0.35 if d.get("shape", "") in ["projectile", "beam"] else 0.6)
		await main.shot("je_%02d_%s" % [shot_i, jid])
		shot_i += 1
		await _wait(0.6)
		_clear()

	# --- 1) tümü
	var ids = []
	for k in Data.jutsu.keys():
		if not String(k).begins_with("_"):
			ids.append(k)
	var n = 0
	for jid in ids:
		pl.global_position = base
		for e in [e1, e2, e3]:
			if is_instance_valid(e):
				e.global_position = e.home
				e.statuses.clear()
		print("CAST %d/%d %s" % [n + 1, ids.size(), jid])
		Jutsu.execute(pl, jid, e1)
		n += 1
		await _wait(0.06)
		if n % 25 == 0:
			_clear()
			Buffs.active.clear()
			pl.model.visible = true
			await _wait(0.3)
	print("JUTSU_ENGINE_DONE casted=", n, " total=", ids.size())
	get_tree().quit()
