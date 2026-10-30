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


## Haritada gösterilecek önemli yerler: [ad, kısa harf, renk]
const LANDMARKS := {
	"weapon_shop": ["Silah Dükkânı", "S", Color(0.85, 0.85, 0.9)], "shop_weapons": ["Silah Dükkânı", "S", Color(0.85, 0.85, 0.9)],
	"pharmacy": ["Eczane", "E", Color(0.45, 0.95, 0.55)], "shop_items": ["Pazar / Eczane", "E", Color(0.45, 0.95, 0.55)],
	"tailor": ["Terzi", "T", Color(0.95, 0.6, 0.85)], "scrolls": ["Parşömenci", "P", Color(0.95, 0.8, 0.4)], "shop_scrolls": ["Parşömenci", "P", Color(0.95, 0.8, 0.4)], "bbq": ["Yakiniku", "Y", Color(1, 0.55, 0.3)], "ramen": ["Ramen", "R", Color(1, 0.75, 0.3)],
	"teahouse": ["Çay Evi", "Ç", Color(0.95, 0.7, 0.75)], "inn": ["Han", "H", Color(0.55, 0.75, 1)], "inn_sleep": ["Han", "H", Color(0.55, 0.75, 1)],
	"hospital": ["Hastane", "+", Color(1, 0.35, 0.35)], "graveyard": ["Mezarlık", "M", Color(0.75, 0.75, 0.85)], "hokage": ["Kage Kulesi / Görevler", "G", Color(1, 0.85, 0.2)], "kage": ["Kage Kulesi / Görevler", "G", Color(1, 0.85, 0.2)],
	"mission_board": ["Görev Masası", "G", Color(1, 0.85, 0.2)], "bounty_board": ["Aranıyor Panosu", "A", Color(1, 0.4, 0.3)],
	"academy": ["Akademi", "A", Color(0.6, 0.85, 1)], "training": ["Antrenman Alanı", "Ö", Color(0.7, 1, 0.6)],
	"trainer": ["Hoca", "Ö", Color(0.7, 1, 0.6)], "home_player": ["Evin", "⌂", Color(1, 1, 1)], "contract_keeper": ["Sözleşme Ustası", "Ç", Color(0.8, 0.6, 1)],
	"chunin_exam": ["Chūnin Sınavı", "C", Color(1, 0.6, 0.2)], "shrine": ["Tapınak", "⛩", Color(1, 0.5, 0.4)],
}


## Yakındaki önemli yerler: [{pos, name, glyph, col}] (kapı + etkileşim noktaları, iç mekânlar hariç, aynı yerdekiler birleşik)
func landmarks(center: Vector3, radius: float) -> Array:
	var out = []
	for it in items:
		if it.get("interior", false):
			continue
		var key = String(it.get("room", "")) if it.get("kind", "") == "enter" else String(it.get("kind", ""))
		if not LANDMARKS.has(key):
			continue
		var p: Vector3 = it["pos"]
		if Vector2(p.x - center.x, p.z - center.z).length() > radius:
			continue
		var dup = false
		for o in out:
			if o["glyph"] == LANDMARKS[key][1] and o["pos"].distance_to(p) < 25.0:
				dup = true
				break
		if not dup:
			out.append({"pos": p, "name": LANDMARKS[key][0], "glyph": LANDMARKS[key][1], "col": LANDMARKS[key][2]})
	return out
