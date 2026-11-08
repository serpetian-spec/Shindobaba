extends Node
## Senju hücresi: köy baskınındaki rastgele klan zarıyla Senju çıkan chūnin ölünce F hedefi olur, cesedi kalır,
## hücre kavanoza girer ve Kara Cerrah / tıbbi ninja seçeneklerinde "Senju hücresi nakli" görünür
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	pl.max_hp = 1e9; pl.hp = 1e9
	# baskın chūnin'i: Orgs._village_arch + rastgele klan yolu (clan_force = zarın Senju çıkması)
	var a = Orgs._village_arch("konoha", 0, "chunin")
	Stats.npc_ninja(a, 40, 1.1)
	a["clan_force"] = "senju"
	var e = Enemy.new()
	e.setup(a)
	get_tree().current_scene.add_child(e)
	e.global_position = pl.global_position + Vector3(0, 0, -2.0)
	print("SENJU clan=%s in_group=%s name=%s" % [e.arch.get("clan"), e.is_in_group("senju_bearers"), e.display_name])
	e.take_hit({"dmg": 1e9, "attacker": pl, "kind": "heavy"})
	await _w(5.0)
	var eyes = pl.combat.modes.eyes
	print("SENJU after 5s corpse_valid=%s dead=%s cell_target=%s" % [is_instance_valid(e), e.is_dead() if is_instance_valid(e) else false, eyes.cell_target == e])
	if eyes.cell_target == e:
		eyes._take_cells(e)
	var lbls = EyeSurgery.options("black").map(func(o): return o["label"])
	print("SENJU jar=%d black_opts=%s" % [int(Game.profile["flags"].get("senju_jar", 0)), str(lbls)])
	get_tree().quit()
