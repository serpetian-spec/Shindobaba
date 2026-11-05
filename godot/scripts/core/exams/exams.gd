extends Node
## Sınavlar ve terfiler (autoload "Exams"):
##  Akademi mezuniyeti (yazılı + sınav odasında Bunshin/Henge + bahçede Kawarimi ve atış), takım sınavı (Parşömen Kapma),
##  Jōnin terfi değerlendirmesi (iki jōnin tavsiyesi + rehine krizi), Tokubetsu Jōnin uzmanlığı, ANBU seçmeleri (+ Kök teklifi).
##  Chūnin sınavı ChuninExam'da (events.gd); arena/takım arkadaşı yardımcıları buradan kullanılır.

signal exam_finished(id: String, passed: bool)

var _bell_greeted := false
var cur := ""            # aktif sınav: academy_written | academy_practical | academy_targets | bell
var data := {}
var nodes: Array = []
var _crisis_t := 0.0
var _spec_applied := false

const ACADEMY_Q := [
	["Ninjanın temel üç akademi tekniği hangisidir?", ["Bunshin, Henge, Kawarimi", "Rasengan, Chidori, Shunshin", "Kuchiyose, Katon, Suiton"], 0],
	["Temel el mühürleri kaç tanedir?", ["8", "12", "16"], 1],
	["Shinobi kuralı: Bir ninja ...", ["duygularını her zaman göstermelidir", "duygularını göreve karıştırmamalıdır", "hiçbir zaman görevden çekilmemelidir"], 1],
	["Chakra hangi iki enerjinin birleşimidir?", ["Fiziksel ve ruhsal enerji", "Doğa ve hayvan enerjisi", "Ateş ve rüzgar"], 0],
	["Kunai fırlatırken en önemli şey nedir?", ["Bilek ve göz hizası", "Bağırarak fırlatmak", "Gözleri kapatmak"], 0],
	["Beş büyük ülkenin gizli köylerinin liderine ne denir?", ["Daimyō", "Kage", "Jōnin Komutanı"], 1],
	["Yer değiştirme tekniği (Kawarimi) ne işe yarar?", ["Düşmanı yakmaya", "Saldırıdan bir nesneyle yer değiştirerek kaçmaya", "Chakrayı göstermeye"], 1],
	["D-rank görevler genelde nelerdir?", ["Suikast", "Kayıp kedi bulmak, tarla işleri", "Savaş"], 1],
	["Doğa dönüşümünde suyu yenen element hangisidir?", ["Toprak", "Ateş", "Yıldırım"], 0],
	["Bir takım genelde nasıl oluşur?", ["Bir jōnin hoca ve üç genin", "İki chūnin", "Beş genin"], 0],
	["Alın koruyucu neyi simgeler?", ["Köye bağlılığı", "Zenginliği", "Klan rütbesini"], 0],
	["Ağaca chakra ile tırmanmanın amacı nedir?", ["Chakra kontrolünü geliştirmek", "Ağacı kesmek", "Kaslanmak"], 0],
	["Görevde arkadaşını terk eden ninja için ne söylenir?", ["Kahramandır", "Kural çiğneyenden de beterdir", "Akıllıdır"], 1],
	["Henge no Jutsu'nun mühür sırası hangisidir?", ["Köpek - Domuz - Koç", "Kaplan - Yılan - Ejderha", "Kuş - Maymun - At"], 0],
]

const SPECIALTIES := [
	{"id": "sorgu", "title": "Sorgu ve İşkence Birimi", "icon": "eye", "desc": "Zihin okuma, sorgu ustalığı. Bingo Kitabı muhbirleri ücretsiz, düşmanlar seni gördüğünde tereddüt eder (+%8 yakın dövüş).", "mods": {"melee": 1.08}},
	{"id": "bariyer", "title": "Bariyer Takımı", "icon": "seal", "desc": "Köyün kalkanı. Alınan hasar kalıcı olarak −%10.", "mods": {"armor": 0.9}},
	{"id": "sensor", "title": "Sensör Birliği", "icon": "target", "desc": "Chakra algısı: yazılı sınavlarda güvenli kopya, menzil +%10, gizlilikte düşmanları uzaktan sezersin.", "mods": {"reach": 1.1}},
	{"id": "zehir", "title": "Zehir ve İlaç Uzmanı", "icon": "potion", "desc": "Silahlarına zehir sürersin: yakın dövüş +%12.", "mods": {"melee": 1.12}},
	{"id": "silah", "title": "Silah Ustası", "icon": "sword", "desc": "Her türlü ninja aletinde ustalık: yakın dövüş +%10, hız +%4.", "mods": {"melee": 1.1, "speed": 1.04}},
	{"id": "egitmen", "title": "Akademi Eğitmeni", "icon": "book", "desc": "Yeni nesli yetiştirirsin. Ustalık gelişimi +%15 (Kage olunca akademi takımları daha güçlü).", "mods": {}},
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func p() -> Dictionary:
	return Game.profile


func flags() -> Dictionary:
	if not p().has("flags"):
		p()["flags"] = {}
	return p()["flags"]


func _clear_nodes() -> void:
	for n in nodes:
		if is_instance_valid(n):
			n.queue_free()
	nodes.clear()


## Ev köyünde türü verilen etkileşim noktası (akademi, antrenman, ANBU ...) — yoksa köy merkezi
func find_point(kinds: Array, vid := "") -> Vector3:
	if vid == "":
		vid = Progress.home()
	var v = Game.village(vid)
	var c = Vector2(float(v.get("x", 0)), float(v.get("y", 0)))
	var best = null
	var bd = 1e12
	for it in Interact.items:
		if not (String(it.get("kind", "")) in kinds or String(it.get("alias", "")) in kinds) or it.get("interior", false):
			continue
		var d = Game.to_map(it["pos"]).distance_to(c)
		if d < bd and d < float(v.get("r", 300)) * 1.6:
			bd = d
			best = it["pos"]
	if best != null:
		return best
	return Game.from_map(c)


# ================================================================== ortak: takım arkadaşları + arena
const TEAMMATE_NAMES := [["Hayato", "m", "diken"], ["Sayuri", "f", "uzun"], ["Kenta", "m", "kase"], ["Mio", "f", "atkuyruğu"], ["Daichi", "m", "kısa"], ["Aoi", "f", "uzun"]]


## Oyuncuyu izleyen ve onunla savaşan iki genin takım arkadaşı
func spawn_teammates(at: Vector3, n := 2, level := 8) -> Array:
	var out = []
	var names = TEAMMATE_NAMES.duplicate()
	names.shuffle()
	var hi = Progress.home_info()
	# Genin takımın varsa (Zil Testi'nden beri) sınava o iki arkadaşınla girersin
	var own = int(p().get("rank", 0)) <= 1 and String(p().get("squad", {}).get("state", "active")) == "active"
	for i in n:
		var e = Enemy.new()
		var a = Enemy.archetype("genin_rival", i)
		var nm: Array = names[i]
		if own and i < 2:
			a = GeninSquad.mate_arch(i, level)
			nm = [String(a["name"]).replace(" (takım)", ""), a["look"]["gender"], a["look"]["hair_style"]]
		a["name"] = "%s (takım)" % nm[0]
		a["respawn"] = false
		a["no_level"] = true
		a["hp"] = 220.0 + level * 12.0
		a["level"] = level
		# takım arkadaşı = rakip genin ile aynı ayar (eskiden sabit 0.9: rakipler 1.3-1.55 vururken arkadaşlar hiçbir şey yapamıyordu)
		var rp = 0.0
		for r in ChuninExam.RIVALS:
			rp += float(r["power"])
		a["power"] = rp / ChuninExam.RIVALS.size() * 0.95
		var js: Array = (a.get("jutsu", []) as Array).duplicate()
		for x in Enemy.auto_jutsu("rogue", String(a.get("element", "")), level):   # rakipler gibi seviyesine göre ek jutsu
			if not x in js and js.size() < 4:
				js.append(x)
		a["jutsu"] = js
		a["aggr"] = maxf(float(a.get("aggr", 0.5)), 0.75)
		a["xp"] = 0
		a["ryo"] = 0
		a["look"]["gender"] = nm[1]
		a["look"]["hair_style"] = nm[2]
		a["look"]["band"] = hi["band"]
		a["look"]["village"] = Progress.home()
		a["look"]["age"] = Player.age_for_rank(int(p().get("rank", 1)))   # sınav takım arkadaşları oyuncuyla yaşıt
		e.setup(a)
		e.team = "player"
		e.set_meta("teammate", true)
		get_tree().current_scene.add_child(e)
		if e.nameplate:
			e.nameplate.modulate = Color(0.55, 1.0, 0.6)
		var q = at + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
		q.y = Game.ground_height(q.x, q.z)
		e.global_position = q
		e.home = q
		out.append(e)
		nodes.append(e)
	return out


## Takım arkadaşlarını oyuncunun yanında tut
func follow_player(team: Array) -> void:
	if Game.player == null:
		return
	var pp = Game.player.global_position
	for i in team.size():
		var e = team[i]
		if not is_instance_valid(e) or e.is_dead():
			continue
		var off = Vector3(cos(i * 2.4) * 3.5, 0, sin(i * 2.4) * 3.5)
		e.home = pp + off
		if e.global_position.distance_to(pp) > 40.0:
			var q = pp + off
			q.y = Game.ground_height(q.x, q.z)
			e.global_position = q
		elif e.target == null:
			e.wander_to = pp + off


## Basit dövüş arenası (stadyumu olmayan köyler / kule): taş zemin, halka duvar, tribün basamakları
func make_arena(center: Vector3, r := 34.0, stands := true) -> Node3D:
	var root = Node3D.new()
	root.name = "ExamArena"
	get_tree().current_scene.add_child(root)
	var g = Game.ground_height(center.x, center.z)
	root.global_position = Vector3(center.x, g, center.z)
	var mb = MB.new()
	mb.add("cyl", Vector3(0, 0.12, 0), Vector3(r * 2.0, 0.3, r * 2.0), Color(0.72, 0.68, 0.58), Vector3.ZERO, 40)
	mb.add("cyl", Vector3(0, 0.3, 0), Vector3(r * 1.2, 0.06, r * 1.2), Color(0.62, 0.58, 0.5), Vector3.ZERO, 40)
	var seg = 36
	for k in seg:
		var a = TAU * k / seg
		var d = Vector3(sin(a), 0, cos(a))
		mb.add("box", d * (r + 1.0) + Vector3(0, 2.2, 0), Vector3(2 * PI * r / seg + 0.3, 4.4, 1.2), Color(0.55, 0.5, 0.42), Vector3(0, rad_to_deg(a), 0))
		if stands:
			for t in 4:
				mb.add("box", d * (r + 3.0 + t * 2.2) + Vector3(0, 4.6 + t * 1.6, 0), Vector3(2 * PI * (r + 3 + t * 2.2) / seg + 0.3, 0.6, 2.0), Color(0.68, 0.6, 0.48), Vector3(0, rad_to_deg(a), 0))
	var mi = MeshInstance3D.new()
	mi.mesh = mb.build(Props.toon())
	root.add_child(mi)
	# duvar çarpışması (halka)
	var sb = StaticBody3D.new()
	root.add_child(sb)
	for k in seg:
		var a = TAU * k / seg
		var cs = CollisionShape3D.new()
		var bx = BoxShape3D.new()
		bx.size = Vector3(2 * PI * r / seg + 0.4, 5.0, 1.2)
		cs.shape = bx
		cs.position = Vector3(sin(a), 0, cos(a)) * (r + 1.0) + Vector3(0, 2.5, 0)
		cs.rotation.y = a
		sb.add_child(cs)
	nodes.append(root)
	return root


## Tribünlere oturmuş seyirciler (sayı kadar köylü)
func spawn_audience(center: Vector3, r: float, n := 26, tiered := false) -> void:
	for i in n:
		var a = TAU * i / n + randf_range(-0.05, 0.05)
		var vg = Villager.new()
		vg.role = "sitter"
		vg.stay = true   # tribünde kalır (sahaya inmez)
		get_tree().current_scene.add_child(vg)
		var q = center + Vector3(sin(a), 0, cos(a)) * (r + 4.0 + (i % 3) * 2.2)
		q.y = Game.ground_height(center.x, center.z) + 5.2 + (i % 3) * 1.6
		if tiered:   # Stadium tribün basamakları
			var t = i % 5
			q = center + Vector3(sin(a), 0, cos(a)) * (Stadium.R_FIELD + 2.2 + t * 2.4)
			q.y = Game.ground_height(center.x, center.z) + 9.85 + t * 1.6
		vg.global_position = q
		vg.home = q
		vg.facing = atan2(sin(a), cos(a))
		nodes.append(vg)


# ================================================================== AKADEMİ MEZUNİYETİ
func academy_talk() -> void:
	var pr = p()
	var sensei = Progress.home_info()["s1"]
	var f = flags()
	if f.get("academy_passed", false):
		Hud.dialog(sensei, "Mezuniyet sınavını geçtin ama asıl sınav jōnin hocan %s'nin takım sınavı! Antrenman alanına git." % GeninSquad.sensei_name(),
			[{"label": "Takım sınavına başla", "cb": bell_start}])
		return
	if cur.begins_with("academy"):
		Hud.dialog(sensei, "Sınav devam ediyor, odaklan!", [])
		return
	Hud.dialog(sensei, "Mezuniyet sınavı üç bölüm: önce yazılı sınav; sonra sınav odasında, hocaların önünde Bunshin ve Henge; en son bahçede Kawarimi ve atış hedefleri. Toplamda %%60 başarı yeterli. Hazır mısın %s?" % pr["name"], [
		{"label": "Hazırım! (yazılı sınav)", "cb": academy_written},
		{"label": "Biraz daha çalışayım", "cb": func(): pass}])


func academy_written() -> void:
	cur = "academy_written"
	var pool = ACADEMY_Q.duplicate()
	pool.shuffle()
	data = {"written": 0.0, "practical": 0, "targets": 0}
	ExamUI.written({"title": "Akademi Mezuniyet Sınavı — Yazılı", "subtitle": "8 soru • 2 dakika • Kâğıdına odaklan.", "questions": pool.slice(0, 8), "time": 120.0, "cheat": 0}, func(r: Dictionary):
		data["written"] = float(r["correct"]) / float(r["total"])
		Hud.dialog(Progress.home_info()["s1"], "Kâğıtlar toplandı (%d/%d doğru). Şimdi sırayla sınav odasına çağıracağım. %s! Masanın önüne geç: Bunshin no Jutsu ile klonlarını göster. Mühürler: Koç - Yılan - Kaplan." % [r["correct"], r["total"], p()["name"]],
			[{"label": "Başla", "cb": academy_practical}]))


func academy_practical() -> void:
	cur = "academy_practical"
	data["task"] = "bunshin_no_jutsu"
	data["t"] = 0.0
	if not "bunshin_no_jutsu" in p()["learned"]:
		Progress.learn("bunshin_no_jutsu", false)
	if not "kawarimi_no_jutsu" in p()["learned"]:
		pass
	Hud.banner("UYGULAMA 1/3", "Bunshin no Jutsu: klon tekniğini kullan [jutsu slotundan]", Color(0.6, 0.85, 1))
	Hud.objective_progress("Bunshin no Jutsu'yu kullan")


func _practical_next(ok: bool) -> void:
	if ok:
		data["practical"] = int(data.get("practical", 0)) + 1
		Combat.popup_text(Game.player.global_position + Vector3.UP * 2.4, "Başarılı!", UI.GOOD)
	else:
		Combat.popup_text(Game.player.global_position + Vector3.UP * 2.4, "Başarısız", UI.BAD)
	match data["task"]:
		"bunshin_no_jutsu":
			data["task"] = "henge"
			data["t"] = 0.0
			Hud.banner("UYGULAMA 2/3", "Henge no Jutsu: hocanın kılığına gir", Color(0.6, 0.85, 1))
			Hud.objective_progress("Henge no Jutsu'yu kullan")
		"henge":
			academy_yard()
		"kawarimi":
			academy_targets()


## Bahçe bölümü: sınav odasından çıkılır; yardımcı hoca karşıda durur, gerçekten kunai fırlatır (görünür mermi).
## Kunai havadayken Kawarimi yapılırsa yer değiştirme kütüğü vurulur; geç kalınırsa kunai sana saplanır.
func academy_yard() -> void:
	cur = "academy_wait"
	var pl = Game.player
	if Interiors.inst and Interiors.inst.inside != "":
		Hud.banner("BAHÇEYE", "Sınavın devamı akademinin bahçesinde", Color(0.6, 0.85, 1))
		await get_tree().create_timer(1.2).timeout
		await Interiors.inst.exit()
		await get_tree().create_timer(0.5).timeout
	var fw: Vector3 = pl.face_dir()
	var at = Missions.open_ground(pl.global_position + fw * 10.0, 6.0)
	var t = Villager.new()
	t.role = "teacher"
	t.display_override = "Yardımcı Hoca"
	t.lines_override = ["Gözünü kunaiden ayırma!"]
	get_tree().current_scene.add_child(t)
	t.global_position = at
	t.home = at
	var dv = pl.global_position - at
	t.facing = atan2(-dv.x, -dv.z)
	t.stand_face = t.facing
	t.fixed_face = true
	nodes.append(t)
	FX.smoke_puff(at + Vector3.UP, 0.7, 8)
	data["task"] = "kawarimi"
	data["teacher"] = t
	data["tries"] = 0
	data["kw_ok"] = 0
	Hud.banner("UYGULAMA 3/3: KAWARIMI", "Yardımcı hoca kunai atacak — kunai havadayken yer değiştir [Q]", Color(0.6, 0.85, 1))
	Hud.objective_progress("Kawarimi: kunai havadayken [Q]  (3 atıştan 2'si)")
	cur = "academy_kawarimi"
	await get_tree().create_timer(2.5).timeout
	_kawarimi_throw()


func _kawarimi_throw() -> void:
	var t = data.get("teacher")
	var pl = Game.player
	if cur != "academy_kawarimi" or t == null or not is_instance_valid(t) or pl == null:
		return
	data["tries"] = int(data["tries"]) + 1
	data["flying"] = true
	var dv = pl.global_position - t.global_position
	t.facing = atan2(-dv.x, -dv.z)
	t.model.rotation.y = t.facing
	t.model.play("throw", 0.1)
	await get_tree().create_timer(0.35).timeout   # kolun savrulduğu an kunai çıkar
	if not is_instance_valid(t) or cur != "academy_kawarimi":
		return
	var k = MeshInstance3D.new()
	var b = MB.new()
	b.add("box", Vector3(0, 0, -0.18), Vector3(0.05, 0.02, 0.32), Color(0.6, 0.62, 0.66))
	b.add("cyl", Vector3(0, 0, 0.08), Vector3(0.03, 0.18, 0.03), Color(0.2, 0.2, 0.22), Vector3(90, 0, 0), 6)
	b.add("torus", Vector3(0, 0, 0.2), Vector3(0.08, 0.08, 0.08), Color(0.3, 0.3, 0.32), Vector3(90, 0, 0), 8)
	k.mesh = b.build(Props.toon())
	get_tree().current_scene.add_child(k)
	var from: Vector3 = t.global_position + Vector3.UP * 1.4
	var to: Vector3 = pl.global_position + Vector3.UP * 1.1
	k.global_position = from
	k.look_at(to, Vector3.UP)
	Sfx.play("whoosh", from, 1.4)
	data["kunai"] = k
	var tw = k.create_tween()
	tw.tween_property(k, "global_position", to, 0.75)
	tw.tween_callback(func():
		if not data.get("flying", false):
			return
		data["flying"] = false
		if is_instance_valid(k):
			k.queue_free()
		Game.player.hp = maxf(1.0, Game.player.hp - 8.0)
		Combat.damage_number(Game.player.global_position + Vector3.UP * 2.0, 8.0, Color(1, 0.4, 0.35))
		Combat.popup_text(Game.player.global_position + Vector3.UP * 2.4, "Geç kaldın!", UI.BAD)
		_kawarimi_after())


func _kawarimi_dodged() -> void:
	data["flying"] = false
	data["kw_ok"] = int(data["kw_ok"]) + 1
	var k = data.get("kunai")
	var pl = Game.player
	# kunai yer değiştirme kütüğüne saplanır (Kawarimi kendi kütüğünü bırakır; kunai orada durur)
	if k != null and is_instance_valid(k):
		var kt = k.create_tween()
		kt.tween_property(k, "global_position", k.global_position.lerp(pl.global_position + Vector3.UP, 0.5), 0.12)
		kt.tween_interval(1.5)
		kt.tween_callback(k.queue_free)
	Combat.popup_text(pl.global_position + Vector3.UP * 2.4, "Kawarimi!", UI.GOOD)
	_kawarimi_after()


func _kawarimi_after() -> void:
	if int(data["tries"]) >= 3 or int(data["kw_ok"]) >= 2:
		data["practical"] = int(data["practical"]) + (1 if int(data["kw_ok"]) >= 2 else 0)
		academy_targets()
		return
	Hud.objective_progress("Kawarimi: %d / %d başarılı (3 atış)" % [int(data["kw_ok"]), int(data["tries"])])
	await get_tree().create_timer(2.2).timeout
	_kawarimi_throw()


const TARGETS := 3   # akademi atış hedefi sayısı (6 idi; alet bekleme süresiyle yetişmiyordu)


func academy_targets() -> void:
	cur = "academy_wait"
	var pl = Game.player
	# akademi odası dünyanın üstünde kurulu: kuklalar aşağıdaki araziye düşüyordu (görünmez → sınav bitmiyordu).
	# parkur akademinin bahçesinde: önce dışarı çık
	if Interiors.inst and Interiors.inst.inside != "":
		await get_tree().create_timer(1.2).timeout
		await Interiors.inst.exit()
		await get_tree().create_timer(0.4).timeout
	# kanon (akademi atış dersi): hedefler yalnız kunai/shuriken atışıyla düşer; alet çantasına alıştırma kunaileri
	var inv: Dictionary = p()["inventory"]
	inv["kunai"] = maxi(int(inv.get("kunai", 0)), 20)
	inv["shuriken"] = maxi(int(inv.get("shuriken", 0)), 20)
	cur = "academy_targets"
	data["t"] = 90.0   # atış bekleme süresi yüzünden 60 sn yetmiyordu
	data["broken"] = 0
	var c = pl.global_position
	for i in TARGETS:
		var a = TAU * i / float(TARGETS) + randf_range(-0.3, 0.3)
		var q = Missions.open_ground(c + Vector3(sin(a), 0, cos(a)) * randf_range(8, 14), 10.0)
		var d = TrainingDummy.new()
		d.set_meta("exam_target", true)
		d.set_meta("throw_only", true)
		d.position = q
		get_tree().current_scene.add_child(d)
		d.global_position = q
		nodes.append(d)
		FX.smoke_puff(q + Vector3.UP, 0.7, 8)
	Missions.target_marker = nodes.back().global_position if not nodes.is_empty() else c
	Hud.banner("ATIŞ HEDEFLERİ", "90 saniyede %d hedefi kunai/shuriken ile vur [R at, T değiştir]" % TARGETS, Color(1, 0.8, 0.4))


func _academy_results() -> void:
	cur = ""
	_clear_nodes()
	var w = float(data["written"])
	var pr_ok = int(data["practical"])
	var tg = int(data["broken"])
	var total = w * 0.4 + pr_ok / 3.0 * 0.35 + tg / float(TARGETS) * 0.25
	var passed = total >= 0.6
	var rows = [["Yazılı sınav", "%%%d" % int(w * 100), w >= 0.5], ["Bunshin / Henge / Kawarimi", "%d / 3" % pr_ok, pr_ok >= 2], ["Atış hedefleri", "%d / %d" % [tg, TARGETS], tg >= 2], ["Toplam", "%%%d" % int(total * 100), passed]]
	if passed:
		flags()["academy_passed"] = true
		Progress.add_xp(120)
		ExamUI.scorecard("Akademi Mezuniyet Sınavı", rows, "MEZUN OLDUN! Ama alın koruyucuyu hak etmek için bir sınav daha var: jōnin hocan %s'nin takım sınavı. Antrenman alanına git." % GeninSquad.sensei_name(), true, func():
			Missions.target_marker = find_point(["training"])
			Missions.has_marker = true
			Missions.target_name = "Antrenman Alanı (Takım Sınavı)")
		exam_finished.emit("academy", true)
	else:
		ExamUI.scorecard("Akademi Mezuniyet Sınavı", rows, "Bu sefer olmadı. Biraz daha çalış ve hocanla tekrar konuş.", false, func(): pass, "Tamam")
		exam_finished.emit("academy", false)


# ================================================================== TAKIM SINAVI (Parşömen Kapma)
## Zil Testi Kakashi'ye özgüydü; her jōnin kendi sınavını yapar. Bu hocanın sınavı: antrenman alanındaki kütüğün üstünde mühürlü
## bir parşömen; hoca onu korur (yenilmez). Parşömene 2.5 sn kesintisiz dokunan alır — hoca parşömene yaklaşanı hedefler, yani
## biri hocayı oyalamadan alınamaz (takım arkadaşları hocaya saldırdıkça hoca onlarla uğraşır). Süre ortasında hoca bir arkadaşı
## bağlar: onu çözmeden [F] parşömeni alan sınavı kaybeder ("arkadaşını terk eden ninja"). İsimler eski kayıtlarla uyumlu: bell_*.
func bell_start() -> void:
	Hud.close_dialog()
	_clear_nodes()
	var pl = Game.player
	var at = find_point(["training"])
	if pl.global_position.distance_to(at) > 60.0:
		Missions.target_marker = at
		Missions.has_marker = true
		Missions.target_name = "Antrenman Alanı (Takım Sınavı)"
		Hud.msg("Takım sınavı antrenman alanında. Pusulayı takip et ve hocanla konuş.", Color(1, 0.85, 0.5))
		data = {"bell_wait": true}
		cur = "bell_wait"
		return
	cur = "bell"
	var hi = Progress.home_info()
	# parşömen: kütüğün üstünde
	var sp = Missions.open_ground(at + Vector3(0, 0, -12), 6.0)
	var stump = MeshInstance3D.new()
	var b = MB.new()
	b.add("cyl", Vector3(0, 0.35, 0), Vector3(0.55, 0.7, 0.55), Color(0.45, 0.32, 0.2), Vector3.ZERO, 12)
	b.add("cyl", Vector3(0, 0.71, 0), Vector3(0.5, 0.02, 0.5), Color(0.72, 0.58, 0.4), Vector3.ZERO, 12)
	b.add("cyl", Vector3(0, 0.8, 0), Vector3(0.12, 0.42, 0.12), Color(0.92, 0.88, 0.75), Vector3(0, 0, 90), 10)
	b.add("cyl", Vector3(0, 0.8, 0), Vector3(0.13, 0.08, 0.13), Color(0.75, 0.15, 0.12), Vector3(0, 0, 90), 10)
	stump.mesh = b.build(Props.toon())
	get_tree().current_scene.add_child(stump)
	stump.global_position = sp
	nodes.append(stump)
	var s = Enemy.new()
	var a = Enemy.archetype("rogue", 0)
	a["name"] = GeninSquad.sensei_name()
	a["hp"] = 99999.0
	a["level"] = 40
	a["power"] = 0.25
	a["guard"] = 0.55
	a["sub"] = 0.45
	a["aggr"] = 0.55
	a["respawn"] = false
	a["xp"] = 0
	a["ryo"] = 0
	a["look"]["band_style"] = "head"
	a["look"]["band"] = hi["band"]
	a["look"]["vest"] = hi["vest"]
	a["look"]["village"] = Progress.home()
	GeninSquad.dress_sensei(a["look"])
	s.setup(a)
	s.set_meta("bell_sensei", true)
	get_tree().current_scene.add_child(s)
	var q = sp + Vector3(1.5, 0, 0)
	q.y = Game.ground_height(q.x, q.z)
	s.global_position = q
	s.home = q
	nodes.append(s)
	var team = spawn_teammates(pl.global_position, 2, 6)
	data = {"sensei": s, "team": team, "t": 150.0, "scroll": sp, "grab": 0.0, "bound": null, "bound_at": randf_range(55.0, 80.0), "together": 0.0}
	Hud.dialog(GeninSquad.sensei_name(), "Benim sınavım basit: şu kütüğün üstündeki parşömeni alın. 150 saniyeniz var, ben de onu koruyacağım. Tek başına gelen hiçbir şey alamaz. Başla!", [])
	Hud.banner("TAKIM SINAVI", "Parşömeni al! (2.5 sn dokun — hoca korurken olmaz, arkadaşların onu oyalasın)", Color(1, 0.75, 0.3))
	Missions.target_marker = sp
	Missions.has_marker = true
	Missions.target_name = "Mühürlü Parşömen"


func _bell_tick(dt: float) -> void:
	var s = data.get("sensei")
	if s == null or not is_instance_valid(s):
		_bell_end()
		return
	s.hp = s.max_hp  # hoca yenilmez
	data["t"] = float(data["t"]) - dt
	var pl = Game.player
	var sp: Vector3 = data["scroll"]
	# hoca parşömenden uzaklaşmaz; parşömene en yakın olanı hedefler (oyalayan arkadaş varsa ona takılır)
	s.home = sp + Vector3(1.5, 0, 0)
	var mates: Array = data["team"].filter(func(e): return is_instance_valid(e) and not e.is_dead())
	var busy_mate = null
	for e in mates:
		if e != data.get("bound") and e.global_position.distance_to(s.global_position) < 5.0:
			busy_mate = e
	if busy_mate != null and pl.global_position.distance_to(sp) < 4.0:
		s.target = busy_mate   # arkadaşın onu oyalıyor
	elif pl.global_position.distance_to(sp) < 8.0:
		s.target = pl
	# arkadaşlar: bağlı olan yerinde, diğerleri hocaya saldırır (oyalama)
	for e in mates:
		if e == data.get("bound"):
			e.velocity = Vector3.ZERO
			continue
		e.target = s
	if pl.global_position.distance_to(s.global_position) < 18.0 and mates.size() > 0:
		data["together"] = float(data["together"]) + dt
	# ortada: hoca bir arkadaşı bağlar
	if data.get("bound") == null and float(data["t"]) < 150.0 - float(data["bound_at"]) and mates.size() > 0:
		var m = mates[0]
		data["bound"] = m
		m.set_physics_process(false)
		FX.smoke_puff(m.global_position + Vector3.UP, 0.6, 8)
		Hud.banner("ARKADAŞIN BAĞLANDI", "%s tel ile kütüğe bağlandı — yanına git, [F] ile çöz" % String(m.display_name).replace(" (takım)", ""), Color(1, 0.5, 0.4))
	var bm = data.get("bound")
	if bm != null and is_instance_valid(bm) and not data.get("freed", false):
		if pl.global_position.distance_to(bm.global_position) < 2.2 and Input.is_action_just_pressed("interact"):
			data["freed"] = true
			bm.set_physics_process(true)
			Combat.popup_text(bm.global_position + Vector3.UP * 2.2, "Çözüldü!", UI.GOOD)
	# parşömeni alma: 2.5 sn kesintisiz (vurulursan sıfırlanır — Player.hit_t kullanılmıyor, hp düşüşüyle)
	var hp_now = pl.hp
	if pl.global_position.distance_to(sp) < 1.6:
		if hp_now < float(data.get("last_hp", hp_now)) - 0.5:
			data["grab"] = 0.0
		else:
			data["grab"] = float(data["grab"]) + dt
		if float(data["grab"]) >= 2.5:
			data["got"] = true
			_bell_end()
			return
	else:
		data["grab"] = maxf(0.0, float(data["grab"]) - dt * 2.0)
	data["last_hp"] = hp_now
	var bound_txt = ""
	if bm != null and not data.get("freed", false):
		bound_txt = "   •   ⚠ Bağlı arkadaş!"
	Hud.objective_progress("⏰ %d sn   •   Parşömen: %d%%%s" % [int(data["t"]), int(float(data["grab"]) / 2.5 * 100.0), bound_txt])
	if float(data["t"]) <= 0.0:
		_bell_end()


func _bell_end() -> void:
	cur = "bell_twist"
	var got = data.get("got", false)
	var left_mate = data.get("bound") != null and not data.get("freed", false)
	for e in data.get("team", []):
		if is_instance_valid(e):
			e.set_physics_process(true)
	_clear_nodes()
	Missions.has_marker = false
	Sfx.play("levelup", null, 1.6, 0.6)
	if got and not left_mate:
		_bell_result(true, "scroll")
	elif got and left_mate:
		_bell_result(false, "abandon")
	elif not left_mate and float(data.get("together", 0.0)) >= 40.0:
		_bell_result(true, "team")   # parşömen alınamadı ama takım birlikte savaştı ve kimse geride kalmadı
	else:
		_bell_result(false, "time")


func _bell_result(passed: bool, why: String) -> void:
	cur = ""
	var hi = Progress.home_info()
	if passed:
		var t = "Parşömeni aldınız — ve bunu birlikte yaptınız. GEÇTİNİZ." if why == "scroll" else "Parşömeni alamadınız, ama hiçbiriniz diğerini geride bırakmadı ve birlikte savaştınız. Aradığım buydu. GEÇTİNİZ."
		flags()["bell_passed"] = true
		Progress.promote(1)
		Progress.add_xp(200)
		Progress.add_ryo(200)
		Progress.set_story(4)
		Missions.has_marker = false
		Hud.dialog(GeninSquad.sensei_name(), t + "\n\nArtık %s'nin bir Genin'isin! Görevleri bundan sonra ben alacağım; takım olarak çıkacağız." % String(Game.village(Progress.home()).get("name", "Köy")), [])
		exam_finished.emit("bell", true)
	else:
		var why_t = {"abandon": "Parşömeni aldın ama arkadaşını bağlı bıraktın. Görevi tamamlamak için arkadaşını terk eden bir ninjayı takımımda istemem.",
			"time": "Süre doldu. Tek başına koştunuz, birbirinizi kollamadınız.",
			"dead": "Yere serildin; sınav bitti. Gerçek bir görevde bu ölüm demekti."}.get(why, "Olmadı.")
		Hud.dialog(GeninSquad.sensei_name(), why_t + " Yarın tekrar dene — benimle antrenman alanında konuş.", [])
		exam_finished.emit("bell", false)


# ================================================================== JŌNİN TERFİSİ
func jonin_offer() -> bool:
	var pr = p()
	if int(pr["rank"]) != 2:
		return false
	var lv = int(pr["level"])
	var a = int(pr["missions_done"].get("A", 0))
	var bb = int(pr["missions_done"].get("B", 0))
	var el = (pr["elements"] as Array).size()
	var kage = Progress.home_info()["kage"]
	if lv < 45 or a < 4 or bb < 6 or el < 2:
		Hud.dialog(kage, "Jōnin olmak için: Güç 45 (%d), 6 B-rank görev (%d), 4 A-rank görev (%d) ve ikinci bir chakra doğasında ustalık (%d/2) gerekli. İkinci doğa ninjutsu ustalığı 40 olunca açılır." % [lv, bb, a, el], [])
		return true
	if Missions.active().get("hook", "") == "Exams.jonin_done":
		return false
	Hud.dialog(kage, "Görev kayıtların göz dolduruyor. Jōnin terfi değerlendirmesine başlamak istiyor musun? İki kıdemli jōninin tavsiyesini alacak, ardından gerçek bir kriz senaryosunda liderliğini kanıtlayacaksın.", [
		{"label": "Değerlendirmeye başla", "cb": func(): Missions.accept(_jonin_mission())},
		{"label": "Daha hazır değilim", "cb": func(): pass}])
	return true


func _jonin_mission() -> Dictionary:
	var vid = Progress.home()
	var j1 = Missions._npc("jonin1", "Kıdemli Jōnin Akizuki", "ninja")
	var j2 = Missions._npc("jonin2", "Jōnin Komutanı Yamagata", "ninja")
	var host = Missions._npc("rehine", "Daimyō'nun Yeğeni Chiyo", "vip")
	var camp = Missions._spot(vid, 350, 800)
	var tp = Game.to_map(find_point(["training"]))
	var bp = Game.to_map(find_point(["mission_board"]))
	return {"title": "Jōnin Terfi Değerlendirmesi", "rank": "A", "village": vid, "hook": "Exams.jonin_done", "giver": Progress.home_info()["kage"],
		"brief": "İki kıdemli jōninin tavsiyesini al, ardından rehine krizini 4 dakika içinde çöz. Takımını ve rehineyi koru: lider olarak değerlendirileceksin.",
		"steps": [
			{"kind": "talk", "at": [tp.x + 8, tp.y], "npc": j1, "text": "Kıdemli Jōnin Akizuki ile konuş.", "say": "Bir görevde iki seçeneğin var: görevi tamamlarsan iki takım arkadaşın ölebilir; geri çekilirsen görev başarısız olur. Ne yaparsın?",
				"choices": [{"label": "Görevi yeniden planlar, kimseyi feda etmem", "ok": true, "vote": 1, "reply": "İyi. Görev önemlidir ama yoldaşlar her şeydir. Tavsiyemi alacaksın."},
					{"label": "Görev her şeyden önce gelir", "ok": false, "vote": 0, "reply": "Soğukkanlısın... ama bir jōnin, insanlarını sayıdan ibaret görmemeli."}]},
			{"kind": "talk", "at": [bp.x + 16, bp.y - 12], "npc": j2, "text": "Jōnin Komutanı Yamagata ile konuş.", "say": "Elinde sınırlı chakra var, düşman seni ve iki geninini kuşattı. İlk emrin ne olur?",
				"choices": [{"label": "Genin'leri geri çektirip düşmanı oyalarım", "ok": true, "vote": 1, "reply": "Lider en son çekilir. Tavsiye mektubunu yazıyorum."},
					{"label": "Hepimiz birden saldırırız", "ok": false, "vote": 0, "reply": "Cesur ama savruk. Yine de kriz sınavına gir, görelim."}]},
			{"kind": "kill", "at": camp, "enemy": "rogue", "n": 4, "camp": true, "night": true, "hostage": host,
				"boss": {"name": "Kaçak Jōnin Kurozame", "hp": 3200.0, "level": 48, "power": 2.8},
				"text": "KRİZ: 4 dakika içinde kaçak jōnini yen, rehineyi kurtar."},
			{"kind": "talk", "npc_id": "rehine", "text": "Rehineyi çöz.", "say": "Beni kurtardın! Amcam Daimyō bunu asla unutmayacak.", "then": "follow"},
			{"kind": "goto", "at": Missions._inside(vid, 0.0, 0.25), "r": 20.0, "followers": true, "name": "Kage Kulesi", "text": "Rehineyi köye getir ve rapor ver."}]}


func jonin_done(m: Dictionary, ok: bool) -> void:
	_crisis_t = 0.0
	if not ok:
		Hud.dialog(Progress.home_info()["kage"], "Değerlendirme başarısız. Dinlen, toparlan ve hazır hissettiğinde tekrar başvur.", [])
		return
	var votes = int(m.get("flags", {}).get("votes", 0))
	if votes >= 1:
		Progress.promote(3)
		Journal.add("Jōnin oldun. Artık başkalarının hayatı senin kararlarına bağlı.", "milestone")
		Gear.grant(p(), "set_jonin")
		Hud.dialog(Progress.home_info()["kage"], "İki jōninin tavsiyesi ve kriz yönetimin oybirliğiyle kabul edildi. Bugünden itibaren bir JŌNİN'sin. Artık bir Tokubetsu Jōnin uzmanlığı da seçebilirsin (Kage Kulesi).", [])
		exam_finished.emit("jonin", true)
	else:
		Hud.dialog(Progress.home_info()["kage"], "Krizi çözdün ama jōninler liderlik tercihlerinden emin değil. Biraz daha A-rank görev al ve tekrar başvur.", [])
		exam_finished.emit("jonin", false)


# ================================================================== TOKUBETSU JŌNİN UZMANLIĞI
func specialty_offer() -> void:
	if int(p()["rank"]) < 2 or int(p()["level"]) < 35:
		Hud.dialog("Uzmanlık", "Tokubetsu Jōnin uzmanlığı için en az Chūnin ve Güç 35 olmalısın.", [])
		return
	if p().get("specialty", "") != "":
		var s = _spec(p()["specialty"])
		Hud.dialog("Uzmanlık", "Uzmanlık alanın: %s.\n%s" % [s["title"], s["desc"]], [])
		return
	ExamUI.choose_cards("Tokubetsu Jōnin Uzmanlığı", "Tek bir alanda jōnin yeterliliği kazan. Seçtiğin birimin 3 aşamalı ustalık görevini tamamlarsan kalıcı yetenek kazanırsın.", SPECIALTIES, func(id):
		Missions.accept(_spec_mission(String(id))))


func _spec(id: String) -> Dictionary:
	for s in SPECIALTIES:
		if s["id"] == id:
			return s
	return SPECIALTIES[0]


func _spec_mission(id: String) -> Dictionary:
	var vid = Progress.home()
	var s = _spec(id)
	var mentor = Missions._npc("usta", "%s Şefi" % s["title"].split(" ")[0], "ninja")
	var spot = Missions._spot(vid, 250, 700)
	var steps = [{"kind": "talk", "at": Missions._inside(vid, 0.15, 0.4), "npc": mentor, "text": "%s şefiyle konuş." % s["title"], "say": "Uzmanlık ustalık sınavına hoş geldin. Üç aşama: bilgi, saha, ustalık."}]
	match id:
		"sorgu":
			var w1 = Missions._npc("tanik1", "Yakalanan Casus", "civ")
			steps.append({"kind": "talk", "at": Missions._inside(vid, 0.2, 0.5), "npc": w1, "text": "Yakalanan casusu sorgula.", "say": "Ben hiçbir şey bilmiyorum...",
				"choices": [{"label": "Sakin baskı: ailesini, korkularını konuş", "ok": true, "vote": 1, "reply": "...Tamam! Kampları kuzeydeki geçitte!"}, {"label": "Tehdit et", "ok": false, "reply": "Hiçbir şey söylemeyeceğim! (Bilgi yarım kaldı)"}]})
			steps.append({"kind": "kill", "at": spot, "enemy": "rogue", "n": 4, "camp": true, "text": "Casus ağını çökert."})
		"bariyer":
			steps.append({"kind": "defend", "at": spot, "enemy": "rogue", "waves": [3, 4, 4], "text": "Bariyer noktasını dalgalara karşı koru."})
			steps.append({"kind": "points", "at": spot, "n": 4, "spread": 12, "label": "[F] Bariyer mühürünü yerleştir", "fx": "tag", "text": "Dört bariyer mühürünü yerleştir."})
		"sensor":
			steps.append({"kind": "stealth", "at": spot, "enemy": "rogue", "n": 4, "goal": "Gizli Rapor", "text": "Algılanmadan kampa sız, raporu al [F]."})
			steps.append({"kind": "kill", "at": Missions._near_spot(spot, 200, 300), "enemy": "rogue", "n": 3, "text": "Sezdiğin pusucuları yakala."})
		"zehir":
			steps.append({"kind": "collect", "at": spot, "item": "zehirli bitki", "n": 5, "spread": 30, "guard": {"enemy": "bandit", "n": 2}, "text": "Zehirli bitki topla (5)."})
			steps.append({"kind": "kill", "at": Missions._near_spot(spot, 150, 250), "enemy": "bandit", "n": 4, "camp": true, "text": "Panzehiri test etmek için haydut kampını etkisiz bırak."})
		"silah":
			steps.append({"kind": "kill", "at": spot, "enemy": "samurai", "n": 1, "boss": {"name": "Gezgin Kılıç Ustası Tetsuo", "hp": 1400.0, "level": 30, "power": 2.3}, "text": "Kılıç ustasını düelloda yen."})
		"egitmen":
			var kid = Missions._npc("cocuk", "Akademi Öğrencisi Taro", "kid")
			steps.append({"kind": "babysit", "at": Missions._inside(vid, 0.2, 0.4), "npc": kid, "time": 60.0, "text": "Akademi öğrencilerine göz kulak ol (60 sn)."})
			steps.append({"kind": "talk", "npc_id": "cocuk", "text": "Öğrencine son dersi ver.", "say": "Sensei, bir ninja neden savaşır?",
				"choices": [{"label": "Sevdiklerini korumak için", "ok": true, "vote": 1, "reply": "Ben de herkesi koruyacağım!"}, {"label": "Güçlü olmak için", "ok": false, "reply": "Hmm... güç neden önemli ki?"}]})
	steps.append({"kind": "talk", "npc_id": "usta", "text": "Şefe dön.", "say": "Ustalığını kanıtladın. Tokubetsu Jōnin rozetini taşımaya hak kazandın."})
	return {"title": "Tokubetsu Jōnin: %s" % s["title"], "rank": "A", "village": vid, "hook": "Exams.specialty_done", "spec": id,
		"brief": s["desc"], "giver": s["title"], "steps": steps}


func specialty_done(m: Dictionary, ok: bool) -> void:
	if not ok:
		return
	var id = String(m.get("spec", "sorgu"))
	p()["specialty"] = id
	_spec_applied = false
	_apply_specialty()
	Hud.banner("TOKUBETSU JŌNİN", _spec(id)["title"], Color(0.9, 0.75, 0.4))
	exam_finished.emit("specialty", true)


func _apply_specialty() -> void:
	var id = String(p().get("specialty", ""))
	if id == "" or _spec_applied:
		return
	_spec_applied = true
	var mods: Dictionary = _spec(id)["mods"]
	if not mods.is_empty():
		Buffs.add("uzmanlik", 1e9, mods)


func xp_mult() -> float:
	return 1.15 if String(p().get("specialty", "")) == "egitmen" else 1.0


# ================================================================== ANBU SEÇMELERİ (+ Kök teklifi)
func anbu_offer() -> void:
	var pr = p()
	if int(pr["rank"]) >= 4:
		Orgs.anbu_hq()
		return
	if int(pr["rank"]) < 3 or int(pr["level"]) < 65 or int(pr["missions_done"].get("S", 0)) < 2 or int(pr["missions_done"].get("A", 0)) < 8:
		Hud.dialog("ANBU", "Burası yetkisiz girişe kapalı. ANBU seçmelerine yalnızca Jōnin + Güç 65 (%d) + 8 A-rank (%d) ve 2 S-rank görevi (%d) olanlar çağrılır." % [int(pr["level"]), int(pr["missions_done"].get("A", 0)), int(pr["missions_done"].get("S", 0))], [])
		return
	if Missions.active().get("hook", "") == "Exams.anbu_done":
		Hud.dialog("Maskeli Muhafız", "Seçmeler sürüyor. Görevine dön.", [])
		return
	Hud.dialog("Maskeli Muhafız", "Seni bekliyorduk. ANBU seçmeleri üç aşamadır: sızma, suikast ve sadakat. Kimliğin silinecek, adın kayıtlardan çıkacak. Kabul ediyor musun?", [
		{"label": "Kabul ediyorum", "cb": func(): Missions.accept(_anbu_mission())},
		{"label": "Şimdi değil", "cb": func(): pass}])


func _anbu_mission() -> Dictionary:
	var vid = Progress.home()
	var camp = Missions._spot(vid, 500, 1000)
	var hq = Game.to_map(find_point(["anbu"]))
	var root_agent = Missions._npc("kok", "Maskesiz Adam (Kök)", "ninja")
	root_agent["look"]["face_style"] = "anbu_kus"
	return {"title": "ANBU Seçmeleri", "rank": "S", "village": vid, "hook": "Exams.anbu_done", "giver": "ANBU Komutanlığı",
		"brief": "Sız, yok et, sadakatini kanıtla. Bir ANBU'nun yüzü yoktur; sadece köyü vardır.",
		"steps": [
			{"kind": "goto", "at": Missions._near_spot(camp, 80, 100), "r": 10.0, "name": "Hedef Bölge", "night": true, "text": "Gece olunca hedef bölgeye git."},
			{"kind": "stealth", "at": camp, "enemy": "rogue", "n": 5, "goal": "Şifreli Liste", "text": "Fark edilmeden şifreli listeyi al [F]."},
			{"kind": "kill", "at": Missions._near_spot(camp, 160, 240), "enemy": "rogue", "n": 2, "boss": {"name": "Hain Jōnin Sagiri", "hp": 4200.0, "level": 68, "power": 3.0, "flee": true}, "text": "Listedeki haini etkisiz hale getir."},
			{"kind": "talk", "at": [hq.x + 12, hq.y - 6], "npc": root_agent, "text": "Karargâhın gölgesinde biri seni bekliyor.",
				"say": "Seçmeleri geçtin. Ama ANBU'nun da göremediği bir kök vardır. Bize katıl: Kage'nin bile bilmediği görevler, köyü gölgeden koruyan ellerin olursun. Kimse bu konuşmayı bilmeyecek.",
				"choices": [{"label": "Kök'e gizlice katılıyorum", "ok": true, "vote": 100, "reply": "Akıllıca. Mühür dilinin altına işlendi; konuşursan dilin kilitlenir. Görevlerin sana ulaşacak."},
					{"label": "Reddediyorum ve bunu Kage'ye bildireceğim", "ok": true, "vote": 1, "reply": "...Sadakat. Öyle olsun. Ama gölgeler seni izleyecek."},
					{"label": "Reddediyorum, kimseye söylemem", "ok": true, "vote": 0, "reply": "Sessizlik de bir cevaptır. Kapımız açık."}]},
			{"kind": "goto", "at": [hq.x, hq.y], "r": 14.0, "name": "ANBU Karargâhı", "text": "ANBU karargâhına dön."}]}


func anbu_done(m: Dictionary, ok: bool) -> void:
	if not ok:
		Hud.dialog("ANBU Komutanı", "Seçmeleri geçemedin. Bir yıl sonra tekrar çağrılabilirsin.", [])
		return
	var votes = int(m.get("flags", {}).get("votes", 0))
	var f = flags()
	if votes >= 100:
		f["root_member"] = true
		Gear.grant(p(), "kok_maskesi")
	elif votes >= 1:
		f["root_reported"] = true
		Missions._rep(Progress.home(), 25)
	Progress.promote(4)
	Gear.grant(p(), "anbu_kurt")
	Journal.add("ANBU maskesini taktın. Adın artık gölgelerde.", "milestone")
	var t = "Maskeni tak. Artık bir ANBU'sun. ANBU Karargâhı'ndan özel görevler alabilirsin."
	if f.get("root_reported", false):
		t += " Kök'ü bildirdiğin için Kage sana özellikle güveniyor (+25 itibar)."
	elif f.get("root_member", false):
		t += " (Kök görevleri karargâhın gölgesinde seni bekliyor.)"
	Hud.dialog("ANBU Komutanı", t, [])
	exam_finished.emit("anbu", true)


# ================================================================== olay kancaları (Progress yönlendirir)
func on_technique(id: String) -> void:
	if cur == "academy_kawarimi" and "kawarimi" in id and data.get("flying", false):
		_kawarimi_dodged()
		return
	if cur == "academy_practical":
		if id == String(data.get("task", "")) or (data.get("task", "") == "bunshin_no_jutsu" and id in ["bunshin_no_jutsu", "bunshin", "oboro_bunshin_no_jutsu"]):
			if data["task"] == "kawarimi" and float(data.get("t", 0.0)) < 0.0:
				return  # kunai gelmeden yapılan kawarimi sayılmaz
			_practical_next(true)


func on_hit(t: Node) -> void:
	if false and cur == "bell" and is_instance_valid(t) and t.has_meta("bell_sensei"):
		data["hits"] = int(data["hits"]) + 1
		if int(data["hits"]) % 9 == 0 and int(data["bells"]) < 2:
			data["bells"] = int(data["bells"]) + 1
			Combat.popup_text(t.global_position + Vector3.UP * 2.5, "🔔 ZİL!", Color(1, 0.85, 0.3))
			Hud.banner("ZİL ALINDI", "%d / 2" % data["bells"], Color(1, 0.85, 0.3))
			Sfx.play("coin", null, 1.6)
			if int(data["bells"]) >= 2:
				data["t"] = minf(float(data["t"]), 3.0)


func on_dummy_broken(d: Node) -> void:
	if cur == "academy_targets" and is_instance_valid(d) and d.has_meta("exam_target") and not d.has_meta("counted"):
		d.set_meta("counted", true)
		data["broken"] = int(data["broken"]) + 1
		if int(data["broken"]) >= TARGETS:
			_academy_results()


func _process(dt: float) -> void:
	if Game.player == null or Game.profile.is_empty() or Game.paused:
		return
	if not _spec_applied and String(p().get("specialty", "")) != "":
		_apply_specialty()
	match cur:
		"academy_practical":
			data["t"] = float(data.get("t", 0.0)) + dt
			if float(data["t"]) > 45.0:
				_practical_next(false)
		"academy_targets":
			data["t"] = float(data["t"]) - dt
			Hud.objective_progress("Hedef: %d / %d   •   ⏰ %d sn" % [int(data["broken"]), TARGETS, int(data["t"])])
			if float(data["t"]) <= 0.0:
				_academy_results()
		"bell":
			_bell_tick(dt)
		"bell_wait":
			if Game.player.global_position.distance_to(find_point(["training"])) < 30.0:
				cur = ""
				bell_start()
		"":
			# kayıttan dönünce de çalışsın: mezun + adım 3 + antrenman alanına gelince hoca karşılar
			if Progress.story() == 3 and flags().get("academy_passed", false) and not Game.ui_open and Game.player:
				if Game.player.global_position.distance_to(find_point(["training"])) < 25.0:
					if not _bell_greeted:
						_bell_greeted = true
						var hi = Progress.home_info()
						Hud.dialog(GeninSquad.sensei_name(), "Geldin demek. Ben takımımı kendi sınavımla seçerim. Hazır mısın?",
							[{"label": "Takım sınavına başla", "cb": bell_start}, {"label": "Biraz sonra", "cb": func(): pass}])
				else:
					_bell_greeted = false
	# Jōnin krizi: 4 dakika sınırı (görevin 3. adımı)
	var m = Missions.active()
	if m.get("hook", "") == "Exams.jonin_done" and int(m.get("step", 0)) == 2:
		_crisis_t += dt
		Hud.objective_progress("KRİZ ⏰ %d sn" % maxi(0, int(240.0 - _crisis_t)))
		if _crisis_t > 240.0:
			_crisis_t = 0.0
			Missions.fail("Zaman doldu: rehine kaçırıldı.")
	elif _crisis_t > 0.0 and m.get("hook", "") != "Exams.jonin_done":
		_crisis_t = 0.0
