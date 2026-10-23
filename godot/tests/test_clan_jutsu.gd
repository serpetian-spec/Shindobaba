extends Node
## Klan jutsuları testi: ClanJutsu'nun uyguladığı her jutsu sırayla atılır (hata/çökme yok mu),
## seçilmiş olanların etki anında ekran görüntüsü alınır, uçuş kipi (Keijūgan, kum bulutu) denenir.

var main: Node
const SHOTS := [
	["sawarabi_no_mai", 0.9], ["tsubaki_no_mai", 0.5], ["tessenka_no_mai_tsuru", 0.6], ["karamatsu_no_mai", 0.5], ["bone_armor", 0.25],
	["hakke_hyakunijuhachi_sho", 0.6], ["hakke_hasangeki", 0.35], ["kagemane", 1.0], ["kage_nageami_shibari_no_jutsu", 0.8],
	["chodan_bakugeki", 0.75], ["choharite", 0.2], ["mushi_kabe", 0.5], ["garoga", 0.4], ["kinbaku_kingusari_no_jutsu", 0.6],
	["suiro_sameodori_no_jutsu", 1.2], ["magen_jubaku_satsu", 1.0], ["sofushasan_no_tachi", 0.9], ["fuma_kaze_guruma", 0.8],
	["kamizuru_hachi", 1.2], ["sabaku_soso", 0.6], ["gokusa_maiso", 1.5], ["akahigi_hyakki_no_soen", 1.5], ["kurohigi_kiki_ippatsu", 0.8],
	["choju_giga", 1.5], ["fuinjutsu_okutopasu_horudo", 0.6], ["kazahana_sajin_senpu", 1.0], ["karatachi_suijin_giri", 0.25],
	["raiga_bomu", 0.6], ["ikazuchi_raiun", 2.2], ["ranton_reiza_sakasu", 0.3], ["doton_goremu_no_jutsu", 1.5],
	["doton_iwayado_kuzushi", 1.0], ["bakuha_rensa", 0.7], ["uchiha_kaenjin", 0.8], ["uchihagaeshi", 0.3], ["katon_goka_mekkyaku", 0.7],
	["jinton_kaku", 0.75], ["jinton_ensui", 0.35], ["jinton_ento", 0.6], ["chinoike_kekkai", 0.5], ["hatake_ninken", 0.4],
	["kugutsu_no_jutsu", 1.0], ["chinoike_tetsu", 0.5], ["ikazuchi_kosen", 0.05],
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
		if f is ShadowClone or f is Summon or f is ClanConstruct:
			f.queue_free()


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "kaguya", "element": "katon", "hair_style": "diken",
		"hair": Color(0.9, 0.9, 0.92), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
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
	pl.pitch = -14.0
	pl.cam_dist = 13.0
	var pr = Game.profile
	pr["level"] = 60
	pr["rank"] = 4
	await _wait(1.5)
	var fwd: Vector3 = pl.cam_forward()
	fwd.y = 0
	fwd = fwd.normalized()
	var side = fwd.cross(Vector3.UP)
	var foes = [_enemy(base + fwd * 8.0), _enemy(base + fwd * 12.0 + side * 3.0), _enemy(base + fwd * 10.0 - side * 3.5)]
	await _wait(0.5)

	# 1) ClanJutsu'nun uyguladığı tüm jutsular
	var ids = []
	for k in Data.jutsu.keys():
		if not k.begins_with("_") and ClanJutsu.handles(k):
			ids.append(k)
	print("CLAN_HANDLERS ", ids.size())
	var n = 0
	for id in ids:
		pl.global_position = base
		pl.facing = atan2(-fwd.x, -fwd.z)
		for i in foes.size():
			foes[i].global_position = base + [fwd * 8.0, fwd * 12.0 + side * 3.0, fwd * 10.0 - side * 3.5][i]
			foes[i].statuses.clear()
			foes[i].team = "enemy"
		Jutsu.execute(pl, id, foes[0])
		n += 1
		await _wait(0.35)
		if pl.is_flying():
			pl.stop_flight()
		if n % 12 == 0:
			_clear()
			await _wait(0.3)
	print("CLAN_CAST_DONE ", n)
	_clear()
	await _wait(1.0)
	# 2) seçilmiş etkiler
	for sh in SHOTS:
		pl.global_position = base
		pl.facing = atan2(-fwd.x, -fwd.z)
		pl.velocity = Vector3.ZERO
		for i in foes.size():
			foes[i].global_position = base + [fwd * 8.0, fwd * 12.0 + side * 3.0, fwd * 10.0 - side * 3.5][i]
			foes[i].statuses.clear()
			foes[i].team = "enemy"
			if foes[i].model:
				foes[i].model.position = Vector3.ZERO
		await _wait(0.4)
		Jutsu.execute(pl, sh[0], foes[0])
		await _wait(sh[1])
		await main.shot("cj_" + sh[0])
		await _wait(0.6)
		_clear()
	# 3) uçuş: Hafif Kaya ile yüksel, ileri uç
	pl.global_position = base
	await _wait(0.3)
	Jutsu.execute(pl, "doton_keijugan_no_jutsu", null)
	await _wait(0.2)
	var y0 = pl.global_position.y
	Input.action_press("jump")
	await _wait(1.6)
	Input.action_release("jump")
	Input.action_press("forward")
	await _wait(1.2)
	Input.action_release("forward")
	print("FLIGHT src=", pl.flight_source(), " rise=", snappedf(pl.global_position.y - y0, 0.1))
	await main.shot("cj_flight_light")
	Jutsu.execute(pl, "jinton_kaku", foes[0])
	await _wait(0.75)
	await main.shot("cj_flight_jinton")
	pl.stop_flight()
	await _wait(1.5)
	Jutsu.execute(pl, "sabaku_suna_no_kumo", null)
	Input.action_press("jump")
	await _wait(1.2)
	Input.action_release("jump")
	print("FLIGHT src=", pl.flight_source())
	await main.shot("cj_flight_sand")
	pl.stop_flight()
	# 4) mühürlü düşman jutsu yapamaz, işaretli fazla hasar alır
	foes[0].apply_status("sealed", 5.0)
	print("SEALED ", foes[0].has_status("sealed"))
	get_tree().quit()
