extends Node
## Shiki Fūjin: hedef kol uzanmadan uzaklaşırsa mühür (ve bedel) gerçekleşmez
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "sarutobi", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.3, 0.3), "top": Color(0.2, 0.2, 0.25), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.0)
	var fw: Vector3 = pl.cam_forward()
	fw.y = 0
	fw = fw.normalized()
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	e.global_position = pl.global_position + fw * 5.0
	e.set_physics_process(false)
	await _w(0.3)
	pl.chakra = 300.0
	Jutsu.execute(pl, "shiki_fujin", e)
	await _w(0.5)
	e.global_position = pl.global_position + fw * 14.0   # kaçış
	await _w(2.5)
	print("SE escaped alive=%s sealed=%s" % [str(is_instance_valid(e) and not e.dead), str(e.has_status("sealed"))])
	await _w(12.0)
	print("SE caster_hp=%.0f (kaçışta bedel yok)" % pl.hp)
	get_tree().quit()
