extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	for vid in ["konoha", "suna", "kiri", "kumo", "iwa"]:
		var L = Outfits.roll("chunin", vid)
		print("VC ", vid, " set=", L.get("set_id"), " vest=", L.get("vest"), " vs=", L.get("vest_style"), " top_style=", L.get("top_style"), " outer=", L.get("outer_style"), " armor=", L.get("armor_style"))
		var P = {}
		Gear.preview_set_look(P, "set_%schunin" % ({"konoha": "", "suna": "suna_", "kiri": "kiri_", "kumo": "kumo_", "iwa": "iwa_"}[vid]))
		print("VC   player-set vs=", P.get("vest_style"), " top_style=", P.get("top_style"), " keys=", P.keys().size())
	get_tree().quit()
