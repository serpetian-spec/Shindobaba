extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	for rk in ["C", "B", "A", "S"]:
		var a = Enemy.archetype("rogue", 0)
		Missions._rank_scale(a, rk)
		var lv = int(a["level"])
		print("MS ", rk, " lv=", lv, " hp=", int(float(a["hp"]) * (0.75 + lv * 0.004)), " power=", snappedf(float(a["power"]), 0.01), " | oyuncu ayni guc hp=", int(Stats.ninja_hp(lv)), " power=", snappedf(Stats.npc_power(lv), 0.01), " n=", Missions.RANK_MIN_N.get(rk, 1), "-", Missions.RANK_MAX_N.get(rk, 1))
	get_tree().quit()
