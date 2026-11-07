extends Node
## Bijūdama: toplanış, uçuş, patlama kareleri (BijudamaFX) — oyuncu ölçeğinde pelerin topu + dev ölçek
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.9, 0.75, 0.2), "top": Color(0.9, 0.45, 0.1), "pants": Color(0.15, 0.15, 0.2), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.4, 0.8)}
	main._start_new_game()
	var pl: Player = main.player
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	Game.set_meta("sandbox", true)
	var vs = Game.village("suna")
	var base = Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"]))
	pl.respawn(base)
	await _w(1.5)
	Hud.close_dialog()
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var big = OS.get_environment("BIG") != ""
	var size = 3.0 if big else 1.0
	var from = pl.global_position + Vector3.UP * (6.0 if big else 1.6) + Vector3(0, 0, -1.2)
	var target = pl.global_position + Vector3(0, 0, -30.0 if big else -16.0)
	target.y = Game.ground_height(target.x, target.z) + 0.5
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	e.global_position = target
	e.max_hp = 1e9; e.hp = 1e9
	e.set_physics_process(false)
	var side = Vector3(14.0 if big else 6.0, (6.0 if big else 2.5), -6.0)
	cc.global_position = pl.global_position + side
	cc.look_at(from + Vector3(0, 0, -4.0))
	cc.current = true
	BijudamaFX.gather(from, size, 0.9)
	var ball = BijudamaFX.ball(size)
	get_tree().current_scene.add_child(ball)
	ball.global_position = from
	ball.scale = Vector3.ONE * 0.05
	ball.create_tween().tween_property(ball, "scale", Vector3.ONE, 0.85)
	await _w(0.45)
	await main.shot("bd_0_gather")
	await _w(0.42)
	await main.shot("bd_1_ball")
	ball.queue_free()
	var dir = (target + Vector3.UP - from).normalized()
	TailedBeasts.fire_ball(pl, from, dir, size * 0.5, Color(1, 0.5, 0.1), 100.0, 30.0)
	await _w(0.12)
	await main.shot("bd_2_launch")
	cc.global_position = target + Vector3(side.x * 1.6, side.y * 1.5, 14.0 if big else 8.0)
	cc.look_at(target + Vector3.UP * 2.0)
	var t0 = Time.get_ticks_msec()
	while e.hp >= 1e9 - 1.0 and Time.get_ticks_msec() - t0 < 2500:
		await get_tree().process_frame
	await _w(0.08)
	await main.shot("bd_3_boom")
	await _w(0.3)
	await main.shot("bd_4_dome")
	await _w(0.6)
	await main.shot("bd_5_after")
	get_tree().quit()
