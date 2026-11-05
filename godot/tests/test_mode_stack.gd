extends Node
## Güç modları üst üste: Sharingan + Sennin + mod jutsusu birlikte açık kalıyor mu, chakra yiyor mu, bitince kapanıyor mu

var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken",
		"hair": Color(0.1, 0.1, 0.1), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	await _wait(1.5)
	var pm = pl.combat.modes
	pl.max_chakra = 300.0
	pl.chakra = 300.0
	if pm.eyes and not pm.eyes.active:
		pm.eyes.toggle()
	await _wait(0.3)
	print("after eyes: eyes=", pm.eyes.active if pm.eyes else null, " n=", pm.active_modes())
	pm.sage_kind = "kurbağa"
	pm._enter_sage()
	await _wait(0.3)
	print("after sage: eyes=", pm.eyes.active if pm.eyes else null, " sage=", pm.sage, " n=", pm.active_modes())
	Buffs.add("raiton_armor", 30.0, {"armor": 0.8})
	await _wait(0.3)
	print("after jutsu mode: eyes=", pm.eyes.active if pm.eyes else null, " sage=", pm.sage, " raiton=", Buffs.has("raiton_armor"), " n=", pm.active_modes())
	var c0 = pl.chakra
	await _wait(3.0)
	print("chakra 3s: ", c0, " -> ", pl.chakra, " (n=", pm.active_modes(), ")")
	pl.chakra = 2.0
	await _wait(1.0)
	print("after empty: eyes=", pm.eyes.active if pm.eyes else null, " sage=", pm.sage, " raiton=", Buffs.has("raiton_armor"), " n=", pm.active_modes(), " chakra=", pl.chakra)
	get_tree().quit()
