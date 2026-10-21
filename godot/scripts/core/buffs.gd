extends Node
## Oyuncu üzerindeki geçici etkiler (autoload "Buffs"): Raiton zırhı, Henge, asker hapı, Sennin modu...

var active = {}  # ad -> {t, mods}


func add(name: String, dur: float, mods: Dictionary) -> void:
	active[name] = {"t": dur, "mods": mods}


func remove(name: String) -> void:
	active.erase(name)


func has(name: String) -> bool:
	return active.has(name)


func mod(key: String) -> float:
	var v = 1.0
	for b in active.values():
		if b["mods"].has(key):
			v *= float(b["mods"][key])
	return v


func _process(dt: float) -> void:
	if Game.paused:
		return
	for k in active.keys():
		active[k]["t"] -= dt
		if active[k]["t"] <= 0.0:
			if k == "henge" and Game.player:
				Jutsu.end_henge(Game.player)
			active.erase(k)
