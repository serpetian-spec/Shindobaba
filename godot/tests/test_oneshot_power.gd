extends Node
## Tek atma güce göre: güçlü hedef Jigokudō/execute ile tek gitmez; zayıf hedef gider. Oyuncu ve düşman aynı kural.
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "age": "adult", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "kısa", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var mine = Combat.power_of(pl)
	print("OS player power=", mine)
	for lv in [maxi(1, int(mine) - 5), int(mine) + 10, int(mine) * 2 + 20]:
		var a = Enemy.archetype("rogue", 0)
		a["respawn"] = false
		var e = Enemy.new()
		e.setup(a)
		get_tree().current_scene.add_child(e)
		e.level = lv
		e.global_position = pl.global_position + Vector3(4, 0, 0)
		await get_tree().process_frame
		e.hp = e.max_hp
		e.take_hit({"dmg": float(e.max_hp) * 4.0, "attacker": pl, "kind": "light", "knock": 0.0, "pierce_guard": true})
		print("OS jigokudo->enemy lv=", lv, " dead=", e.is_dead(), " hp%=", snappedf(e.hp / e.max_hp * 100.0, 0.1))
		if not e.is_dead():
			e.die({"execute": true, "attacker": pl, "dmg": 9999.0})
			await get_tree().process_frame
			print("OS execute->enemy lv=", lv, " dead=", e.is_dead(), " hp%=", snappedf(e.hp / e.max_hp * 100.0, 0.1))
		# AI eşitliği: aynı düşman oyuncuya tek atan darbe
		pl.hp = pl.max_hp
		pl.combat.invuln = 0.0
		pl.combat.take_hit({"dmg": pl.max_hp * 4.0, "attacker": e, "kind": "light", "knock": 0.0, "pierce_guard": true, "dir": Vector3.FORWARD})
		print("OS enemy lv=", lv, " -> player hp%=", snappedf(pl.hp / pl.max_hp * 100.0, 0.1))
		pl.hp = pl.max_hp
		if is_instance_valid(e): e.queue_free()
		await get_tree().create_timer(0.3).timeout
	get_tree().quit()
