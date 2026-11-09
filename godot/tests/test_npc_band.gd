extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	var cnt = {}
	for vid in ["konoha", "suna", "kiri", "kumo"]:
		for arch in ["genin", "chunin", "jonin", "rogue"]:
			for i in 60:
				var L = Outfits.roll(arch, vid)
				var k = "%s/%s:%s" % [vid, arch, str(L.get("band_wear", "-"))]
				cnt[k] = int(cnt.get(k, 0)) + 1
	var keys = cnt.keys()
	keys.sort()
	for k in keys:
		print("NB ", k, " ", cnt[k])
	get_tree().quit()
