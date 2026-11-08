extends Node
## Shinken Shirahadori: pencere açıkken bıçaklı yakın darbe yakalanır (hasar yok, saldıran sersem); bıçaksız darbe geçer
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl: Player = main.player
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	e.global_position = pl.global_position + Vector3(0, 0, -2)
	await _w(0.3)
	PathJutsu.cast_path(pl, "shinken_shirahadori", null)
	var hp0 = pl.hp
	pl.take_hit({"dmg": 30.0, "melee": true, "blade": true, "kind": "heavy", "attacker": e})
	print("SHIRA blade: dmg=%.1f atk_stun=%s" % [hp0 - pl.hp, str(e.has_status("stun"))])
	PathJutsu.cast_path(pl, "shinken_shirahadori", null)
	var hp1 = pl.hp
	pl.take_hit({"dmg": 30.0, "melee": true, "blade": false, "kind": "heavy", "attacker": pl})
	print("SHIRA fist: dmg=%.1f (geçmeli)" % [hp1 - pl.hp])
	get_tree().quit()
