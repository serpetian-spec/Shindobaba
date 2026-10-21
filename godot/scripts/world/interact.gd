extends Node
## Etkileşim noktaları kaydı (autoload "Interact"): [F] ile konuşma, dükkân, görev masası vb.

var items: Array = []


func add(d: Dictionary) -> void:
	items.append(d)


func nearest(p: Vector3) -> Dictionary:
	var best = {}
	var bd = 1e9
	for it in items:
		var d: float = p.distance_to(it["pos"])
		if d < float(it["radius"]) and d < bd:
			bd = d
			best = it
	return best
