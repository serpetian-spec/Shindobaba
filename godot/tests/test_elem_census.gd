extends Node
## Element sayımı: kullanıcının kaydının kopyası (slot 7) yüklenir; çevredeki tüm dövüşçülerin elementi ve
## taşıdıkları jutsuların elementi sayılır; 60 sn boyunca atılan jutsular da sayılır.
var main: Node
var cast := {}

func _ready() -> void:
	await get_tree().process_frame
	main.load_slot(7)
	Game.profile["slot"] = 7
	await get_tree().create_timer(4.0).timeout
	Hud.close_dialog()
	for round in 4:
		var el := {}
		var jel := {}
		var kinds := {}
		for f in get_tree().get_nodes_in_group("fighters"):
			if f == main.player or not is_instance_valid(f):
				continue
			var e = String(f.get("element")) if f.get("element") != null else "?" + String(f.get_script().resource_path.get_file() if f.get_script() else f.get_class())
			el[e] = int(el.get(e, 0)) + 1
			var a = f.get("arch")
			if a is Dictionary:
				var k = String(a.get("kind", "?"))
				kinds[k] = int(kinds.get(k, 0)) + 1
				for jid in a.get("jutsu", []):
					var je = String(Data.jutsu.get(jid, {}).get("element", ""))
					jel[je] = int(jel.get(je, 0)) + 1
		print("CENSUS r%d fighters_el=%s jutsu_el=%s kinds=%s" % [round, el, jel, kinds])
		await get_tree().create_timer(15.0).timeout
	get_tree().quit()
