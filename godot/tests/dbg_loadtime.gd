extends Node
## Yükleme süresi: yeni oyun -> oyuncu hareket edebilir hale gelene kadar; aşamalar ms
var main: Node


func _ready() -> void:
	var t0 = Time.get_ticks_msec()
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	var t1 = Time.get_ticks_msec()
	main._start_new_game()
	var t2 = Time.get_ticks_msec()
	var frames = 0
	var worst = 0
	var last = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t2 < 15000:
		await get_tree().process_frame
		var now = Time.get_ticks_msec()
		worst = maxi(worst, now - last)
		last = now
		frames += 1
	print("LOAD boot=%d start_new_game=%d  15sn icinde kare=%d en_uzun_kare=%dms" % [t1 - t0, t2 - t1, frames, worst])
	get_tree().quit()
