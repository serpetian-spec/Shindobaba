extends Node
## Uchiha gözü V ile aç/kapat döngüsü: Sharingan / Mangekyō / Ebedi — her basışta durum + modeldeki göz dokusu.
## Kullanım: --test=res://tests/test_eye_toggle.gd

var main: Node
var pl: Player


func _v() -> void:
	var ey = pl.combat.modes.eyes
	var a = InputEventAction.new()
	a.action = "dojutsu"; a.pressed = true
	Input.parse_input_event(a)
	await get_tree().create_timer(0.15).timeout
	var b = InputEventAction.new()
	b.action = "dojutsu"; b.pressed = false
	Input.parse_input_event(b)
	await get_tree().create_timer(1.6).timeout
	var em = pl.model.eye_mat
	print("   V -> active=%s ms_on=%s  model göz sağ=%s tomoe=%s sol=%s" % [ey.active, ey.ms_on, em.get_shader_parameter("dojutsu") if em else "?", em.get_shader_parameter("tomoe") if em else "?", em.get_shader_parameter("dojutsu_l") if em else "?"])


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12),
		"top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	pl = main.player
	await get_tree().create_timer(3.0).timeout
	print("klan=", Game.profile.get("clan"), " look gözler=", Game.profile["look"].get("eye_r"), " ", Game.profile["look"].get("eye_l"))
	for kind in [1, 4, 5]:
		Game.profile["look"]["eye_r"] = {"kind": kind, "lvl": 3, "origin": "dogustan"}
		Game.profile["look"]["eye_l"] = {"kind": kind, "lvl": 3, "origin": "dogustan"}
		pl.chakra = pl.max_chakra
		print("GÖZ türü ", kind)
		for i in 5:
			await _v()
	print("EYE BITTI")
	get_tree().quit()
