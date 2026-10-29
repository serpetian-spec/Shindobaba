extends Node
## Beceri deneme modu açılıyor mu: öğrenilen jutsu sayısı, gözler, canavarlar, kuklalar
var main: Node
func _ready() -> void:
	var sb = load("res://scripts/core/sandbox.gd").new()
	sb.set("main", main)
	add_child(sb)
	await get_tree().create_timer(12.0).timeout
	var pr = Game.profile
	print("SB learned=%d natures=%d held=%d contracts=%d susanoo=%d dummies=%d" % [pr["learned"].size(), pr["natures"].size(), TailedBeasts.held().size(), pr["contracts"].size(), Susanoo.max_tier(pr), get_tree().get_nodes_in_group("fighters").filter(func(x): return x.get("team") == "dummy").size()])
	await main.shot("sandbox")
	get_tree().quit()
