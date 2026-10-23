extends Node
## Boyut denetimi: animede devasa olan teknikler oyuncu (1.7 m) kadrajdayken çekilir.
## [jutsu, çekim gecikmesi, kamera uzaklığı]

var main: Node
const SHOTS := [
	["suiro_sameodori_no_jutsu", 1.4, 34.0], ["suiton_senshokuko", 0.9, 26.0], ["hoshigaki_same", 0.35, 16.0], ["suiton_daikodan_no_jutsu", 0.5, 18.0],
	["suiton_daibakufu_no_jutsu", 1.3, 34.0], ["suiton_suiryuudan", 0.9, 30.0], ["kirin", 1.9, 34.0], ["katon_goka_messhitsu", 0.6, 30.0],
	["katon_goka_mekkyaku", 0.8, 30.0], ["doton_doryu_taiga", 0.6, 28.0], ["mokuton_jukai_kotan", 0.8, 34.0], ["sawarabi_no_mai", 1.0, 30.0],
	["cho_baika_no_jutsu", 1.0, 30.0], ["chodan_bakugeki", 0.85, 28.0], ["sabaku_soso", 0.6, 28.0], ["hakke_hasangeki", 0.3, 22.0],
	["jinton_ento", 0.6, 34.0],
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


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "akimichi", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.85, 0.3, 0.2), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	Game.world.env.weather = "açık"
	var v := Game.village("konoha")
	var base := Game.from_map(Vector2(v["x"] + 300, v["y"] - float(v["r"]) - 260))
	pl.respawn(base)
	pl.max_hp = 1e9
	pl.hp = 1e9
	pl.max_chakra = 1e9
	pl.chakra = 1e9
	Game.profile["level"] = 60
	Game.profile["rank"] = 4
	await _wait(1.5)
	var fwd: Vector3 = pl.cam_forward()
	fwd.y = 0
	fwd = fwd.normalized()
	var foe = _enemy(base + fwd * 14.0)
	for sh in SHOTS:
		pl.global_position = base
		pl.velocity = Vector3.ZERO
		pl.facing = atan2(-fwd.x, -fwd.z)
		pl.yaw = 0.0
		pl.pitch = -16.0
		pl.cam_dist = sh[2]
		foe.global_position = base + fwd * 14.0
		foe.statuses.clear()
		await _wait(0.6)
		Jutsu.execute(pl, sh[0], foe)
		await _wait(sh[1])
		await main.shot("sz_" + sh[0])
		if pl.combat and pl.combat.modes and pl.combat.modes.has_method("set_size"):
			pl.combat.modes.set_size(1.0, 0.0)
		Buffs.active.clear()
		await _wait(2.5)
	get_tree().quit()
