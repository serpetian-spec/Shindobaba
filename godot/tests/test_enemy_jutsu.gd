extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	for k in ["bandit", "rogue", "genin_rival", "kiri", "kumo", "oto"]:
		for lv in [3, 8, 15, 30]:
			var a = Enemy.archetype(k, 0)
			var j = Enemy.auto_jutsu(k, String(a["element"]), lv) if k in Enemy.JUTSU_CAP else a["jutsu"]
			var names = j.map(func(x): return "%s[%s]" % [x, Data.jutsu[x].get("canon_rank", "?")])
			print("EJ ", k, " lv", lv, " ", a["element"], " -> ", names)
	get_tree().quit()
