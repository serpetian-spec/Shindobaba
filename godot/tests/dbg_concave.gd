extends Node
## Konoha'daki ConcavePolygon şekillerini yüz sayısına göre say (hangi üretici çok şekil açıyor)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 98, "name": "T", "gender": "m", "clan": "none", "element": "katon", "hair_style": "s2", "hair": Color(0.2, 0.2, 0.2), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	var k = get_tree().current_scene.find_child("Konoha", true, false)
	var hist = {}
	var n = 0
	for cs in k.find_children("*", "CollisionShape3D", true, false):
		if cs.shape is ConcavePolygonShape3D:
			n += 1
			var f = (cs.shape as ConcavePolygonShape3D).get_faces().size() / 3
			hist[f] = hist.get(f, 0) + 1
	print("CONC total=", n)
	var keys = hist.keys()
	keys.sort_custom(func(a, b): return hist[a] > hist[b])
	for f in keys.slice(0, 12):
		print("CONC faces=%d count=%d" % [f, hist[f]])
	get_tree().quit()
