extends Node
## Kanon şartları: Hiraishin işaret, Kirin fırtına, büyük Suiton su (yarı güç)
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.15), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.3, 0.3), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	await get_tree().create_timer(1.0).timeout
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 600, vs["y"])))
	await get_tree().create_timer(1.0).timeout
	Game.world.env.weather = "açık"
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	e.global_position = pl.global_position + Vector3(0, 0, -8)
	e.set_physics_process(false)
	print("CR hiraishin işaretsiz: '%s'" % CanonRules.block(pl, "hiraishin_no_jutsu"))
	Jutsu.execute(pl, "hiraishin_kunai", e)
	await get_tree().create_timer(1.5).timeout
	print("CR kunai sonrası: '%s' marked=%s" % [CanonRules.block(pl, "hiraishin_no_jutsu"), str(e.has_status("marked"))])
	var pp = pl.global_position
	print("CR hava=%s wl=%.2f ter=%.2f katon_t=%s now=%.1f" % [str(Game.world.env.weather), Game.water_level(pp.x, pp.z), Game.terrain_height(pp.x, pp.z), str(pl.get_meta("katon_t", -999.0)), Game.now()])
	print("CR kirin açık hava: '%s'" % CanonRules.block(pl, "kirin"))
	Jutsu.execute(pl, "katon_gokakyu_no_jutsu" if Data.jutsu.has("katon_gokakyu_no_jutsu") else "katon_goryuka_no_jutsu", e)
	await get_tree().create_timer(0.5).timeout
	print("CR kirin katon sonrası: '%s'" % CanonRules.block(pl, "kirin"))
	print("CR çölde daibakufu çarpan=%.2f su=%s" % [CanonRules.dmg_mult(pl, "suiton_daibakufu_no_jutsu"), str(CanonRules.water_near(pl))])
	Game.world.env.weather = "yağmur"
	print("CR yağmurda kirin: '%s'" % CanonRules.block(pl, "kirin"))
	print("CR yağmurda daibakufu çarpan=%.2f" % CanonRules.dmg_mult(pl, "suiton_daibakufu_no_jutsu"))
	print("CR jiton need=%s" % Data.jutsu["senpo_jiton_rasengan"].get("need", ""))
	get_tree().quit()
