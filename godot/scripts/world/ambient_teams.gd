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
	# köyün kalıcı takımlarından biri (isimleri, görünüşleri, rütbeleri kayıtlı; tanışınca dost olurlar)
	var ros: Array = roster(vid)
	var busy = []
	for tm0 in teams:
		busy.append(tm0.get("key", ""))
	var free = []
	for k in ros.size():
		if not "%s:%d" % [vid, k] in busy:
			free.append(k)
	if free.is_empty():
		return
	var ti: int = free.pick_random()
	var team: Dictionary = ros[ti]
	var nodes = []
	var people: Array = team["people"]
	for pi in people.size():
		var person: Dictionary = people[pi]
		var fid = String(person.get("fid", ""))
		var f: Dictionary = Friends.all().get(fid, {})
		if not f.is_empty() and (String(f.get("status", "")) != "" or f.get("party", false)):
			continue   # ölmüş / kaçmış / senin takımında: bu yürüyüşte yok
		var rank = int(f.get("rank", person["rank"])) if not f.is_empty() else int(person["rank"])
		var look = Friends.look_of({"look": person["look"], "rank": rank})
		look["band"] = hi["band"]
		look["band_style"] = "head"
		look["village"] = vid
		look["age"] = "adult" if rank >= 1 else "teen"
		if rank >= 1:
			look["vest"] = hi["vest"]
		var n = EncounterNPC.new()
		n.team = "neutral"
		var nm = String(f.get("name", person["name"])) if not f.is_empty() else String(person["name"])
		n.display = "%s (%s)" % [nm, Friends.RANKS[clampi(rank, 0, 3)] if rank < 2 else "Jōnin"]
		n.mode = "march"
		n.speed = 4.0
		var lk = CharacterModel.default_look()
		lk.merge(look, true)
		n.look = lk
		n.line = String((SENSEI_LINES if rank >= 2 else LINES).pick_random())
		n.set_meta("vt", [vid, ti, pi])
		n.on_talk = _talk
		get_tree().current_scene.add_child(n)
		var q = start + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		q.y = Game.ground_height(q.x, q.z)
		n.global_position = q
		n.home = q
		n.goal = dest
		nodes.append(n)
	if nodes.is_empty():
		return
	teams.append({"nodes": nodes, "dest": dest, "key": "%s:%d" % [vid, ti]})


## Köyün kalıcı takımları (ilk görüldüğünde üretilir, kayda yazılır): 4 genin takımı (jōnin hoca + 3 genin) ve 1 chūnin üçlüsü
static func roster(vid: String) -> Array:
	var p = Game.profile
	if not p.has("vteams"):
		p["vteams"] = {}
	if p["vteams"].has(vid):
		return p["vteams"][vid]
	var out = []
	var used = {}
	for ti in 5:
		var chunin = ti == 4
		var people = []
		for i in (3 if chunin else 4):
			var female = randf() < 0.45
			var nm = ""
			for tries in 20:
				nm = ((GENIN_F if female else GENIN_M) as Array).pick_random()
				if not used.has(nm):
					break
			used[nm] = true
			var rank = 1 if chunin else (2 if i == 0 else 0)
			var look = {"gender": "f" if female else "m", "hair_style": ["kısa", "uzun", "kase", "dağınık", "topuz", "diken", "atkuyruğu"].pick_random(),
				"hair": Color(randf_range(0.05, 0.9), randf_range(0.05, 0.7), randf_range(0.05, 0.6)), "top": Color(randf_range(0.15, 0.8), randf_range(0.15, 0.7), randf_range(0.15, 0.7))}
			people.append({"name": nm, "rank": rank, "look": Friends._ser(look), "fid": ""})
		out.append({"people": people})
	p["vteams"][vid] = out
	return out


## Gezen takım üyesiyle konuşma: tanışmadıysan tanış (kalıcı dost kaydı), tanıştıysan dostluk seçenekleri
func _talk(n: Node) -> void:
	var vt: Array = n.get_meta("vt", [])
	if vt.is_empty():
		Hud.dialog(n.display, n.line, [])
		return
	var ros: Array = roster(String(vt[0]))
	var person: Dictionary = ros[int(vt[1])]["people"][int(vt[2])]
	var fid = String(person.get("fid", ""))
	if fid != "" and Friends.all().has(fid):
		var f: Dictionary = Friends.all()[fid]
		var opts = Friends._friend_opts(fid, null)
		opts.append({"label": "Nereye gidiyorsunuz?", "cb": func(): Hud.dialog(String(f["name"]), n.line, [])})
		Hud.dialog(String(f["name"]), Friends.greeting(fid), opts)
		return
	var nm = String(person["name"])
	Hud.dialog(n.display, n.line, [
		{"label": "Kendini tanıt", "cb": func():
			var lk = Friends.look_of({"look": person["look"], "rank": person["rank"]})
			lk["gender"] = String(lk.get("gender", "m"))
			var id = Friends.add_person(nm, lk, int(person["rank"]), "patrol", String(vt[0]), n.global_position, "%s takımı" % String(ros[int(vt[1])]["people"][0]["name"]))
			person["fid"] = id
			Hud.dialog(nm, "Ben %s, %s. Takımımla göreve gidiyoruz — köyde görürsen selam ver!" % [nm, Friends.RANKS[clampi(int(person["rank"]), 0, 3)]], [])},
		{"label": "Kolay gelsin.", "cb": func(): pass}])
