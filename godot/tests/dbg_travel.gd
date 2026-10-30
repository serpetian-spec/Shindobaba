extends Node
## Hızlı seyahat süresi: Konoha -> Suna, Kumo (yükleme ekranı köy kurulana kadar)
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	for vid in ["suna", "kumo"]:
		var t0 = Time.get_ticks_msec()
		await main.fast_travel(vid)
		print("TRAVEL ", vid, " ", Time.get_ticks_msec() - t0, " ms")
		await get_tree().create_timer(1.0).timeout
		await main.shot("travel_" + vid)
	get_tree().quit()
