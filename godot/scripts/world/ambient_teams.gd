extends Node
## Çevrede gezen ninja takımları: bir jōnin + üç genin (bazen chūnin üçlüsü), köyler arası yollarda göreve gider ya da döner.
## Oyuncu büyüse de görünürler (dünya oyuncuya göre değil). Konuşulabilir: nereye gittiklerini, hangi rütbe görevde olduklarını söylerler.
## Aynı anda en fazla 2 takım; oyuncudan 260 m uzaklaşan takım dağılır (yerine bir süre sonra başkası çıkar).

const MAX_TEAMS := 2
const GENIN_M := ["Haruto", "Kaito", "Sōta", "Ren", "Daiki", "Yūma", "Takumi", "Riku", "Kenji", "Shin"]
const GENIN_F := ["Hina", "Mei", "Aiko", "Sakura", "Nanami", "Yui", "Rin", "Emi", "Kaede", "Mio"]
const LINES := ["D-rank bir işten dönüyoruz. Bütün gün bir kedinin peşindeydik...", "Hocamız bizi sınır karakoluna götürüyor. İlk C-rank görevimiz!",
	"Bir tüccarı yanındaki köye kadar koruyacağız.", "Chūnin Sınavı yaklaşıyor, her gün antrenman yapıyoruz.",
	"Takım olmak zormuş... ama birbirimizi bırakmıyoruz.", "Yolda kaçak izleri gördük, dikkatli ol."]
const SENSEI_LINES := ["Öğrencilerimle göreve gidiyoruz. Yolumuzdan sapma, genç.", "Bu üçünden iyi ninjalar çıkacak, göreceksin.",
	"Sınırda hareket var. Sen de gözünü açık tut."]

var teams: Array = []   # [{"nodes": [...], "dest": Vector3, "dir": Vector3}]
var t := 20.0


func _process(dt: float) -> void:
	if Game.paused or Game.player == null or Game.profile.is_empty():
		return
	var pp: Vector3 = Game.player.global_position
	# takımları yürüt: lider hedefe, diğerleri liderin arkasında üçgen dizilişte
	for tm in teams.duplicate():
		var ns: Array = tm["nodes"].filter(func(n): return is_instance_valid(n) and not n.dead)
		if ns.is_empty() or ns[0].global_position.distance_to(pp) > 260.0 or ns[0].global_position.distance_to(tm["dest"]) < 6.0:
			for n in tm["nodes"]:
				if is_instance_valid(n):
					n.queue_free()
			teams.erase(tm)
			continue
		var lead = ns[0]
		lead.goal = tm["dest"]
		var fw: Vector3 = (tm["dest"] - lead.global_position)
		fw.y = 0
		fw = fw.normalized() if fw.length() > 0.1 else Vector3.FORWARD
		var sd = fw.cross(Vector3.UP)
		for i in range(1, ns.size()):
			var off = -fw * (2.2 + 1.6 * int((i + 1) / 2)) + sd * (1.6 if i % 2 == 1 else -1.6) * (1.0 if i < 3 else 0.0)
			ns[i].goal = lead.global_position + off
			ns[i].speed = lead.speed * 1.15 if ns[i].global_position.distance_to(ns[i].goal) > 3.0 else lead.speed
	t -= dt
	if t > 0.0:
		return
	t = randf_range(50.0, 90.0)
	if teams.size() >= MAX_TEAMS or not _outdoors(pp) or int(ChuninExam.stage) != 0 or Exams.cur != "":
		return   # sınav sürerken gezen takım çıkmaz
	_spawn(pp)


func _outdoors(p: Vector3) -> bool:
	if Interiors.inst and Interiors.inst.inside != "":
		return false
	if p.y > Game.terrain_height(p.x, p.z) + 300.0 or Game.terrain_height(p.x, p.z) < -1.0:
		return false
	return true


func _spawn(pp: Vector3) -> void:
	# oyuncunun önünde, yanından geçecek bir rota: yan taraftan çıkıp karşıya doğru yürürler
	var fw: Vector3 = Game.player.face_dir() if Game.player.has_method("face_dir") else Vector3.FORWARD
	fw.y = 0
	var side = fw.cross(Vector3.UP).normalized() * (1.0 if randf() < 0.5 else -1.0)
	var start = pp + fw * randf_range(60.0, 100.0) + side * randf_range(50.0, 80.0)
	start = Missions.open_ground(start, 25.0)
	start.y = Game.ground_height(start.x, start.z)
	if Game.terrain_height(start.x, start.z) < -0.5:
		return
	var dest = start - side * randf_range(220.0, 320.0) + fw * randf_range(-40.0, 40.0)
	dest.y = Game.ground_height(dest.x, dest.z)
	var vid = Outfits.village_near(start)
	var hi: Dictionary = Progress.HOME_VILLAGES.get(vid, Progress.HOME_VILLAGES["konoha"])
	var chunin = randf() < 0.3   # bazen tek başına gezen chūnin üçlüsü
	var nodes = []
	var n_total = 3 if chunin else 4
	for i in n_total:
		var lead = i == 0 and not chunin
		var female = randf() < 0.45
		var nm = ((GENIN_F if female else GENIN_M) as Array).pick_random()
		var look = {"gender": "f" if female else "m", "hair_style": ["kısa", "uzun", "kase", "dağınık", "topuz", "diken", "atkuyruğu"].pick_random(),
			"hair": Color(randf_range(0.05, 0.9), randf_range(0.05, 0.7), randf_range(0.05, 0.6)), "top": Color(randf_range(0.15, 0.8), randf_range(0.15, 0.7), randf_range(0.15, 0.7)),
			"band": hi["band"], "band_style": "head", "village": vid, "age": "adult" if (lead or chunin) else "teen"}
		if lead or chunin:
			look["vest"] = hi["vest"]
		var n = EncounterNPC.new()
		n.team = "neutral"
		n.display = ("%s (Jōnin)" if lead else ("%s (Chūnin)" if chunin else "%s (Genin)")) % nm
		n.mode = "march"
		n.speed = 4.0
		var lk = CharacterModel.default_look()
		lk.merge(look, true)
		n.look = lk
		var lines = SENSEI_LINES if lead else LINES
		n.line = String(lines.pick_random())
		get_tree().current_scene.add_child(n)
		var q = start + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		q.y = Game.ground_height(q.x, q.z)
		n.global_position = q
		n.home = q
		n.goal = dest
		nodes.append(n)
	teams.append({"nodes": nodes, "dest": dest})
