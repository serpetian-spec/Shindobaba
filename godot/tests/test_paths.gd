extends Node
## Efsane Yolları testi: söylenti → in bulma → yola katılma (pasif bonus), ustaların inleri, Tab > Yollar sekmesi,
## iki yolun bütün teknikleri sırayla atılır (hata yok mu) ve seçilenlerin etki anı çekilir (oyuncu ölçek için kadrajda).

var main: Node
const SHOTS := [
	["sen_ei_jashu", 0.4, 2.0], ["jagei_jubaku", 0.55, 1.5], ["hebi_bunshin_no_jutsu", 0.4, 0.5], ["sen_ei_tajashu", 0.5, 3.0], ["kusanagi_kuchi", 0.42, 1.0],
	["gogyo_fuin", 0.6, 1.0], ["sen_ei_ranjashu", 0.55, 1.5], ["mandara_no_jin", 0.9, 2.0], ["orochimaru_ryu_no_kawarimi_no_jutsu", 0.5, 4.5],
	["buki_kuchiyose", 0.7, 1.0], ["tesso_kusari", 0.3, 1.5], ["soshoryu", 1.6, 2.0], ["ito_buki_arashi", 1.2, 6.5],
	["kuchiyose_tetsuzan", 0.85, 3.5], ["bashosen_kaze_no_maki", 1.3, 2.5], ["bashosen_hi_no_maki", 1.0, 2.0], ["bashosen_rai_no_maki", 1.4, 3.5],
	["bashosen_mizu_no_maki", 1.2, 2.0], ["tekkosen", 0.5, 6.5], ["sojasosai_no_jutsu", 1.0, 1.5],
	["kuchiyose_rashomon", 0.6, 8.5], ["kuchiyose_sanju_rashomon", 1.2, 10.5], ["ten_no_juin", 0.6, 22.0], ["juin_ni_no_dankai", 0.8, 18.5],
	["hakuja_sennin_modo", 1.6, 30.0], ["yamata_no_jutsu", 2.2, 16.5], ["kuchiyose_edo_tensei", 2.4, 1.0],
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
	for n in get_tree().current_scene.get_children():
		if n is Projectile:
			n.queue_free()
	for f in get_tree().get_nodes_in_group("fighters"):
		if f is ShadowClone or f is EdoWarrior or f is ClanConstruct:
			f.queue_free()


func _look_at_lair(pl: Player, pid: String, dist: float) -> void:
	var at: Array = LegendPaths.lairs[pid]
	var lair = Game.from_map(Vector2(float(at[0]), float(at[1])))
	pl.yaw = 0.0
	await _wait(0.1)
	var f: Vector3 = pl.cam_forward()
	f.y = 0
	f = f.normalized()
	pl.respawn(lair - f * dist)
	pl.facing = atan2(-f.x, -f.z)


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.25, 0.18, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	var pr = Game.profile
	Game.world.env.time_of_day = 0.45
	Game.world.env.weather = "açık"
	await _wait(2.0)
	print("LAIRS ", LegendPaths.lairs)
	# 1) söylenti: seviye 6 → silah yolu
	pr["level"] = 6
	await _wait(2.5)
	print("STATE lv6 silah=", LegendPaths.state("silah"), " yilan=", LegendPaths.state("yilan"))
	# 2) demirhane: yaklaşınca bulunur
	pl.cam_dist = 9.0
	pl.pitch = -10.0
	await _look_at_lair(pl, "silah", 15.0)
	await _wait(3.5)
	print("STATE near forge silah=", LegendPaths.state("silah"))
	Hud.show_game_hud(false)
	await main.shot("pt_forge")
	pl.cam_dist = 26.0
	pl.pitch = -22.0
	await _wait(0.5)
	await main.shot("pt_forge_wide")
	Hud.show_game_hud(true)
	LegendPaths.interact({"path": "silah"})
	await _wait(0.5)
	await main.shot("pt_mentor_dialog")
	Hud.close_dialog()
	# sınavı geçmiş say: yola katıl
	LegendPaths.node().quest_done({"path": "silah", "trial": true, "teach": ""}, true)
	await _wait(0.5)
	print("JOINED silah=", LegendPaths.joined("silah"), " learned_first=", "buki_kuchiyose" in pr["learned"], " throw_dmg=", Stats.skill(pr, "throw_dmg"))
	# 3) yılan ini
	pr["level"] = 30
	Hud.show_game_hud(false)
	pl.cam_dist = 10.0
	pl.pitch = -8.0
	await _look_at_lair(pl, "yilan", 16.0)
	await _wait(4.0)
	print("STATE near den yilan=", LegendPaths.state("yilan"))
	await main.shot("pt_den")
	pl.cam_dist = 30.0
	pl.pitch = -24.0
	await _wait(0.5)
	await main.shot("pt_den_wide")
	LegendPaths.node().quest_done({"path": "yilan", "trial": true, "teach": ""}, true)
	# usta öğretme diyaloğu (yolda)
	pr["ryo"] = 99999
	Hud.show_game_hud(true)
	LegendPaths.interact({"path": "yilan"})
	await _wait(0.5)
	await main.shot("pt_teach_dialog")
	Hud.close_dialog()
	# 4) Tab > Yollar
	main._pause()
	Menus.ninja_menu(main, "paths")
	await _wait(0.7)
	await main.shot("pt_tab")
	main.resume()
	await _wait(0.5)
	print("CAN_LEARN ", Progress.can_learn("mandara_no_jin"))
	if "--lairs-only" in OS.get_cmdline_user_args():
		print("PATHS_DONE")
		get_tree().quit()
		return
	# 5) teknikler: açık alanda üç düşmanla
	Hud.show_game_hud(false)
	pr["level"] = 60
	var v := Game.village("konoha")
	var base := Game.from_map(Vector2(v["x"] + 300, v["y"] + 140))
	pl.respawn(base)
	pl.max_hp = 1e9
	pl.hp = 1e9
	pl.max_chakra = 1e9
	pl.chakra = 1e9
	pl.yaw = 0.0
	pl.pitch = -16.0
	pl.cam_dist = 16.0
	await _wait(1.5)
	var fwd: Vector3 = pl.cam_forward()
	fwd.y = 0
	fwd = fwd.normalized()
	var side = fwd.cross(Vector3.UP)
	var spots = [fwd * 9.0, fwd * 13.0 + side * 3.5, fwd * 11.0 - side * 4.0]
	var foes = []
	for s in spots:
		foes.append(_enemy(base + s))
	await _wait(0.5)
	var ids = []
	for pid in LegendPaths.PATHS:
		for jid in LegendPaths.PATHS[pid]["order"]:
			ids.append(jid)
	var missing = ids.filter(func(x): return not PathJutsu.handles_path(x) or not Data.jutsu.has(x))
	print("PATH_IDS ", ids.size(), " missing=", missing)
	for sh in SHOTS:
		pl.global_position = base
		pl.facing = atan2(-fwd.x, -fwd.z)
		pl.velocity = Vector3.ZERO
		pl.hp = 1e9
		if pl.is_flying():
			pl.stop_flight()
		Buffs.active.clear()
		for i in foes.size():
			foes[i].global_position = base + spots[i]
			foes[i].statuses.clear()
			if foes[i].model:
				foes[i].model.position = Vector3.ZERO
		await _wait(0.4)
		Jutsu.execute(pl, sh[0], foes[0])
		await _wait(sh[1])
		await main.shot("pt_" + sh[0])
		await _wait(float(sh[2]))
		_clear()
	print("SEALED ", foes[0].has_status("sealed"))
	print("PATHS_DONE")
	get_tree().quit()
