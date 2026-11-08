extends Node
## Ses varyantları yüklendi mi + kodda çağrılan her ad bir sese çözülüyor mu
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	var keys = Sfx.variants.keys()
	keys.sort()
	var tot = 0
	for k in keys:
		tot += (Sfx.variants[k] as Array).size()
	print("SFX variant keys=%d files=%d" % [keys.size(), tot])
	var miss = []
	for n in ["blade", "chakra", "smoke", "zap", "throw", "summon", "lightning", "charge", "pop", "pickup", "absorb", "slash", "hit", "heartbeat", "guard", "growl", "chain", "bite", "step_dirt1", "step_grass2", "step_snow", "punch", "fire", "water", "wind", "earth", "boom", "roar", "seal", "poof", "chidori", "genjutsu", "rasengan"]:
		if Sfx._pick(n) == null:
			miss.append(n)
	print("SFX unresolved: ", miss)
	var bad = []
	for k in Sfx.STYLE_TH:
		if Sfx._pick(String(Sfx.STYLE_TH[k][0])) == null:
			bad.append(k)
	var themed = 0
	var by = {}
	for id in Data.jutsu:
		var th = Sfx.theme_for_jutsu(id)
		if th != "":
			themed += 1
			by[th] = int(by.get(th, 0)) + 1
			if Sfx._pick(th) == null:
				bad.append(id)
	print("SFX style/theme unresolved: ", bad)
	print("SFX themed jutsu=%d %s" % [themed, str(by)])
	get_tree().quit()
