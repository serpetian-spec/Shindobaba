extends Node
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	pl.model.play("sit", 0.2)
	pl.input_locked = 10.0
	for k in 6:
		await get_tree().create_timer(0.25).timeout
		print("SIT t=", k, " cur=", pl.model.current, " anim=", pl.model.anim.current_animation, " grounded=", pl.grounded, " busy=", pl.combat.busy() if pl.combat else "-")
	get_tree().quit()
