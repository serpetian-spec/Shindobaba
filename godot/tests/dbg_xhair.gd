extends Node
## Nişangâh: boşta beyaz, düşman üstünde kırmızı; jutsu nişangâha gider
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.5).timeout
	await main.shot("xh_free")
	var aim = pl.aim_point()
	var e = Enemy.new()
	e.setup(Enemy.archetype("bandit", 0))
	get_tree().current_scene.add_child(e)
	var fl = aim - pl.global_position
	fl.y = 0
	e.global_position = pl.global_position + fl.normalized() * 4.0
	e.set_physics_process(false)
	await get_tree().create_timer(0.6).timeout
	print("XH soft=%s rect=%s vis=%s hud=%s" % [Jutsu.soft_target(pl) != null, Hud.xhair.get_global_rect(), Hud.xhair.is_visible_in_tree(), Hud.game_hud.visible])
	await main.shot("xh_lock")
	var hp0 = e.hp
	Jutsu.execute(pl, "kami_shuriken", pl.combat._cast_target())
	await get_tree().create_timer(0.5).timeout
	await main.shot("xh_fire")
	await get_tree().create_timer(1.5).timeout
	print("XH fire dmg=%.0f" % (hp0 - e.hp))
	get_tree().quit()
