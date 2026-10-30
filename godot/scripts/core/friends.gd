class_name Friends
extends Node
## Köydeki ninjalarla dostluk/düşmanlık ve takım (sıradan köylülerle değil): klan üyeleri (ClanResident), devriye/antrenman ninjaları.
## [F] -> "Kendini tanıt": adı, klanı, gözleri, rütbesi, ailesi ve görünümü profile kaydedilir.
## Bağ -100..100: sohbet / hediye / dostça düello artırır, laf sokmak ve köyden kaçmak düşürür.
##   ≤-60 Ezeli Düşman, ≤-30 Düşman, <0 Soğuk, <30 Tanıdık, <60 Arkadaş, 60+ Yakın Dost.
## Bağ 40'tan sonra takımına katılır (en fazla 2), kendi klan teknikleriyle seninle savaşır.
## Dinamik yaşam (birkaç dakikada bir): rütbe atlar (Genin -> Chūnin -> Jōnin -> Elit Jōnin), evlenir, çocuğu olur, uzun göreve
## çıkar, yaralanır, ailesinden birini kaybeder... Kırgın ya da yaslı olanlar köyden kaçıp Bingo Kitabı'na girebilir.
## Elit Jōnin dostların Kage bile olabilir (Kage.reign_tick). Köydeyken arada bir yanına uğrarlar. Liste: Tab > Görevler.

const PARTY_MAX := 2
const JOIN_BOND := 40
const TALK_CD := 600.0      # sn (gerçek zaman)
const GIFT_COST := 100
const RETURN_T := 60.0
const DEATH_P := 0.22     # takımdaki dost düşünce kalıcı ölme olasılığı
const RANKS := ["Genin", "Chūnin", "Jōnin", "Elit Jōnin"]
const NINJA_ROLES := ["patrol", "roof", "guard", "spar", "teacher"]
const ELS := ["katon", "suiton", "fuuton", "doton", "raiton"]
const CHAT := ["Bugün hava güzel, değil mi? Antrenman için ideal.", "Geçen gün pazarda harika bir dango buldum, sana da getiririm.",
	"Köyde senden bahsediyorlar. İyi şeyler, merak etme!", "Çocukken Hokage olmayı hayal ederdim. Sen?", "Sınırda yine hareketlilik varmış... dikkatli ol.",
	"Seninle konuşmak iyi geliyor.", "Bir gün birlikte bir göreve çıkalım!", "Yeni bir teknik mi öğrendin? Göster bakalım!"]
const COLD := ["Ne istiyorsun?", "Meşgulüm.", "Seninle konuşacak havamda değilim.", "Hı."]
const HOSTILE := ["Gözüme görünme.", "Bir gün hesaplaşacağız, unutma.", "Senin gibileri köyden kovmak lazım.", "Yolumdan çekil."]

var members: Array = []    # [{"id", "node", "down"}]
var t := 0.0
var bond_t := 0.0
var life_t := 180.0
var visit_t := 90.0
var visitor: Node = null


static func pr() -> Dictionary:
	return Game.profile


static func all() -> Dictionary:
	var p = pr()
	if p.is_empty():
		return {}
	if not p.has("friends"):
		p["friends"] = {}
	return p["friends"]


static func level_name(b: int) -> String:
	if b <= -60:
		return "Ezeli Düşman"
	if b <= -30:
		return "Düşman"
	if b < 0:
		return "Soğuk"
	return "Yakın Dost" if b >= 60 else ("Arkadaş" if b >= 30 else "Tanıdık")


static func level_color(b: int) -> Color:
	if b <= -30:
		return Color(1.0, 0.4, 0.35)
	if b < 0:
		return Color(0.85, 0.7, 0.55)
	return Color(0.55, 1.0, 0.7) if b >= 30 else Color(0.85, 0.9, 0.95)


## Köyde, görevde değil, yaralı değil, kaçmamış
static func available(f: Dictionary) -> bool:
	var st = String(f.get("status", ""))
	if Time.get_unix_time_from_system() < float(f.get("away", 0.0)):
		return false
	if st == "kaçak":
		return Orgs.is_rogue()   # kaçak dostun yalnız sen de kaçakken yanına gelir
	return st == ""


static func player_gender() -> String:
	return String(pr().get("look", {}).get("gender", "m"))


## Sevgili / eş (oyuncunun)
static func romance_of(id: String) -> String:
	return String(all().get(id, {}).get("romance", ""))


static func spouse_id() -> String:
	return String(pr().get("spouse", ""))


static func party_ids() -> Array:
	var out = []
	var fs = all()
	for id in fs:
		if fs[id].get("party", false) and available(fs[id]):
			out.append(id)
	return out


static func _ser(look: Dictionary) -> Dictionary:
	var o = {}
	for k in look:
		var v = look[k]
		o[k] = [v.r, v.g, v.b, v.a, "c"] if v is Color else v
	return o


static func look_of(f: Dictionary) -> Dictionary:
	var o = {}
	var src: Dictionary = f.get("look", {})
	for k in src:
		var v = src[k]
		if v is Array and v.size() == 5 and String(v[4]) == "c":
			o[k] = Color(float(v[0]), float(v[1]), float(v[2]), float(v[3]))
		elif v is String and String(v).begins_with("("):
			o[k] = str_to_var("Color" + v)
		else:
			o[k] = v
	return o


static func log_event(f: Dictionary, text: String) -> void:
	if not f.has("log"):
		f["log"] = []
	f["log"].append(text)
	if (f["log"] as Array).size() > 6:
		f["log"].pop_front()


static func add_bond(id: String, n: int, quiet := false) -> void:
	var f: Dictionary = all().get(id, {})
	if f.is_empty():
		return
	var before = level_name(int(f["bond"]))
	f["bond"] = clampi(int(f["bond"]) + n, -100, 100)
	var after = level_name(int(f["bond"]))
	if after != before:
		Hud.banner(after.to_upper(), "%s ile aranız: %s" % [f["name"], after], level_color(int(f["bond"])))
	elif not quiet:
		Hud.msg("%s: bağ %+d (%d, %s)" % [f["name"], n, int(f["bond"]), after], level_color(int(f["bond"])))


# ------------------------------------------------------------------ konuşma
static func is_ninja(v: Node) -> bool:
	if v is ClanResident:
		return String(v.look.get("age", "adult")) != "child"
	return v.role in NINJA_ROLES and not v.interior and v.display_override == ""


## Köylüye / klan üyesine [F]: konuşma seçenekleri (Villager.talk, ClanResident.talk)
static func options_for(v: Node) -> Array:
	if pr().is_empty():
		return []
	var id = String(v.get_meta("friend_id", ""))
	if id != "" and all().has(id):
		return _friend_opts(id, v)
	if not is_ninja(v):
		return []   # sıradan köylüler, çocuklar, özel kişiler (Kage, hocalar) dost/takım olmaz
	return [{"label": "Kendini tanıt", "cb": func(): _meet(v)}]


## Selamlama (bağa ve son habere göre)
static func greeting(id: String) -> String:
	var f: Dictionary = all()[id]
	var b = int(f["bond"])
	if b <= -30:
		return HOSTILE.pick_random()
	if b < 0:
		return COLD.pick_random()
	var news = String(f.get("news", ""))
	if news != "":
		f["news"] = ""
		return news
	return "Ooo, %s! %s" % [String(pr().get("name", "")), CHAT.pick_random()]


static func _friend_opts(id: String, v: Node) -> Array:
	var f: Dictionary = all()[id]
	var b = int(f["bond"])
	var opts = []
	var now = Time.get_unix_time_from_system()
	var can_talk = now - float(f.get("last_talk", 0.0)) >= TALK_CD
	if b < 0:
		if can_talk:
			opts.append({"label": "Özür dile, arayı düzelt", "cb": func():
				f["last_talk"] = Time.get_unix_time_from_system()
				var ok = randf() < (0.75 if b > -60 else 0.35)
				Hud.dialog(String(f["name"]), "...Peki. Bir şans daha." if ok else "Özrün de sen de umurumda değil.", [])
				add_bond(id, 12 if ok else 2)})
	elif can_talk:
		opts.append({"label": "Sohbet et", "cb": func():
			f["last_talk"] = Time.get_unix_time_from_system()
			Hud.dialog(String(f["name"]), CHAT.pick_random(), [])
			add_bond(id, 8)})
	opts.append({"label": "Hediye ver (%d Ryō)" % GIFT_COST, "cb": func():
		if int(pr().get("ryo", 0)) < GIFT_COST:
			Hud.msg("Yeterli Ryō yok.", Color(1, 0.5, 0.4))
			return
		Progress.add_ryo(-GIFT_COST)
		Hud.dialog(String(f["name"]), "Bunu bana mı aldın? Çok teşekkürler!" if b >= 0 else "...Bununla beni satın alamazsın. Ama sağ ol.", [])
		add_bond(id, 15 if b >= 0 else 8)})
	if b > -60:
		opts.append({"label": "Laf sok / kışkırt", "cb": func():
			Hud.dialog(String(f["name"]), ["Ne dedin sen?!", "Bunu unutmayacağım.", "Hadi oradan!"].pick_random(), [])
			add_bond(id, -14)})
	opts.append_array(_romance_opts(id))
	if f.get("party", false):
		opts.append({"label": "Takımdan ayrıl (köyde bekle)", "cb": func(): set_party(id, false)})
	elif b >= JOIN_BOND:
		opts.append({"label": "Takımıma katıl", "cb": func():
			if set_party(id, true) and v != null and is_instance_valid(v) and v.has_method("vanish"):
				v.vanish()})
	elif b >= 0:
		opts.append({"label": "Takım (bağ %d gerekir, şu an %d)" % [JOIN_BOND, b], "cb": func():
			Hud.msg("%s seni daha iyi tanımak istiyor: sohbet et, hediye ver, düello yap." % f["name"], Color(0.9, 0.85, 0.6))})
	return opts


## Karşı cinsle aşk: bağ 60+ çıkma teklifi, sevgiliyken 80+ evlilik, evliyken çocuk (eşin klanıyla melez)
static func _romance_opts(id: String) -> Array:
	var f: Dictionary = all()[id]
	var b = int(f["bond"])
	var opts = []
	if String(f["look"].get("gender", "m")) == player_gender() or not available(f):
		return opts
	var rm = romance_of(id)
	if rm == "" and b >= 60 and (spouse_id() == "" or spouse_id() == id) and not all().keys().any(func(k): return romance_of(k) == "sevgili"):
		opts.append({"label": "Çıkma teklif et ♥", "cb": func():
			if randf() < clampf((b - 40) / 45.0, 0.2, 0.95):
				f["romance"] = "sevgili"
				log_event(f, "Seninle sevgili oldu")
				Hud.dialog(String(f["name"]), "...Ben de uzun zamandır bunu düşünüyordum. Evet!", [])
				Hud.banner("SEVGİLİ", "%s ile artık birliktesiniz ♥" % f["name"], Color(1, 0.55, 0.7))
				add_bond(id, 10, true)
			else:
				Hud.dialog(String(f["name"]), "Seni çok seviyorum ama... henüz hazır değilim. Biraz zaman ver.", [])
				add_bond(id, -4, true)})
	elif rm == "sevgili":
		if b >= 80 and spouse_id() == "":
			opts.append({"label": "Evlenme teklif et 💍", "cb": func(): _marry(id)})
		opts.append({"label": "Ayrıl", "cb": func():
			f["romance"] = ""
			log_event(f, "Ondan ayrıldın")
			Hud.dialog(String(f["name"]), "...Anlıyorum. Yolun açık olsun.", [])
			add_bond(id, -40)})
	elif rm == "eş":
		var due = float(pr().get("baby_due", 0.0))
		if due <= 0.0:
			opts.append({"label": "Çocuk sahibi olalım", "cb": func():
				pr()["baby_due"] = Time.get_unix_time_from_system() + randf_range(480.0, 900.0)
				Hud.dialog(String(f["name"]), "Bir çocuk... Bizim çocuğumuz. Evet, hazırım.", [])})
		opts.append({"label": "Boşan", "cb": func():
			f["romance"] = ""
			pr()["spouse"] = ""
			pr()["baby_due"] = 0.0
			log_event(f, "Senden boşandı")
			add_bond(id, -60)})
	return opts


static func _marry(id: String) -> void:
	var f: Dictionary = all()[id]
	if randf() > clampf((int(f["bond"]) - 60) / 30.0, 0.35, 0.97):
		Hud.dialog(String(f["name"]), "Bu çok büyük bir adım... Biraz daha düşünmem lazım.", [])
		return
	f["romance"] = "eş"
	f["party"] = f.get("party", false)
	pr()["spouse"] = id
	log_event(f, "Seninle evlendi")
	f["news"] = "Evliliğimizin ilk günü! Köyde herkes bizden bahsediyor."
	Hud.banner("DÜĞÜN", "%s ile evlendiniz! Köy halkı tören için toplandı ♥" % f["name"], Color(1, 0.6, 0.75))
	add_bond(id, 15, true)


## Oyuncunun çocuğu doğar: eşinin klanıyla melez olabilir
static func _baby_tick() -> void:
	var due = float(pr().get("baby_due", 0.0))
	if due <= 0.0 or Time.get_unix_time_from_system() < due or spouse_id() == "" or not all().has(spouse_id()):
		return
	pr()["baby_due"] = 0.0
	var sp: Dictionary = all()[spouse_id()]
	var fem = randf() < 0.5
	var my_clan = String(pr().get("clan", "none"))
	var sp_clan = String(sp.get("clan", ""))
	var sur = ClanWorld.clan_name(my_clan) if my_clan != "none" else (ClanWorld.clan_name(sp_clan) if sp_clan != "" else String(Missions.BB_FAMILY.pick_random()))
	var kid = {"name": "%s %s" % [sur, (ClanWorld.GIVEN_F if fem else ClanWorld.GIVEN_M).pick_random()], "gender": "f" if fem else "m",
		"clans": [my_clan, sp_clan].filter(func(c): return c != "" and c != "none"), "born": Time.get_unix_time_from_system()}
	if not pr().has("children"):
		pr()["children"] = []
	pr()["children"].append(kid)
	var mix = " (%s melezi)" % " × ".join(kid["clans"].map(func(c): return ClanWorld.clan_name(c))) if (kid["clans"] as Array).size() >= 2 and kid["clans"][0] != kid["clans"][1] else ""
	log_event(sp, "%s adında bir %s oldu (seninle)" % [kid["name"], "kızınız" if fem else "oğlunuz"])
	Hud.banner("BİR %s OLDU!" % ("KIZINIZ" if fem else "OĞLUNUZ"), "%s%s dünyaya geldi ♥" % [kid["name"], mix], Color(1, 0.75, 0.8))


static func _family(clan: String, female: bool, rank: int) -> Array:
	var sur = ClanWorld.clan_name(clan) if clan != "" else String(Missions.BB_FAMILY.pick_random())
	var nm = func(fem: bool) -> String:
		return "%s %s" % [sur, (ClanWorld.GIVEN_F if fem else ClanWorld.GIVEN_M).pick_random()]
	var fam = [{"rel": "Babası", "name": nm.call(false), "alive": randf() < 0.85}, {"rel": "Annesi", "name": nm.call(true), "alive": randf() < 0.85}]
	if randf() < 0.6:
		var sf = randf() < 0.5
		fam.append({"rel": "Kız kardeşi" if sf else "Erkek kardeşi", "name": nm.call(sf), "alive": true})
	if rank >= 1 and randf() < 0.35:
		fam.append({"rel": "Kocası" if female else "Karısı", "name": "%s %s" % [String(Missions.BB_FAMILY.pick_random()), (ClanWorld.GIVEN_M if female else ClanWorld.GIVEN_F).pick_random()], "alive": true})
		if randf() < 0.5:
			var kf = randf() < 0.5
			fam.append({"rel": "Kızı" if kf else "Oğlu", "name": nm.call(kf), "alive": true})
	return fam


static func _meet(v: Node) -> void:
	var fs = all()
	var female = String(v.look.get("gender", "m")) == "f"
	var given = (ClanWorld.GIVEN_F if female else ClanWorld.GIVEN_M).pick_random()
	var clan = ""
	var eye = [0, 0]
	if v is ClanResident:
		given = String(v.given)
		clan = String(v.clan)
		eye = [int(v.eye_kind), int(v.eye_lvl)]
	var age = String(v.look.get("age", "adult"))
	var rank = 0 if age == "teen" else (2 if v.role in ["teacher", "guard"] else (1 if v.look.get("vest") != null else randi_range(0, 1)))
	var id = "f%d" % (int(pr().get("friend_seq", 0)) + 1)
	pr()["friend_seq"] = int(pr().get("friend_seq", 0)) + 1
	var lk: Dictionary = v.look.duplicate()
	lk.erase("age")
	# köydeki itibarın ilk bakışı belirler (kötü şöhretliysen soğuk başlar)
	var rep = int(pr().get("rep", {}).get(Progress.home(), 0))
	var start = clampi(10 + rep / 8, -25, 35)
	fs[id] = {"name": given, "role": v.role, "ninja": true, "look": _ser(lk), "bond": start, "village": Progress.home(), "party": false,
		"last_talk": Time.get_unix_time_from_system(), "element": ELS.pick_random(), "clan": clan, "eye": eye, "rank": rank,
		"family": _family(clan, female, rank), "status": "", "log": [], "news": "",
		"title": ("%s klanı" % ClanWorld.clan_name(clan)) if clan != "" else String(v.display)}
	if clan != "" and String(v.vid) != "":
		fs[id]["village"] = String(v.vid)
	v.set_meta("friend_id", id)
	v.display = given
	v.display_override = given
	Hud.dialog(given, "Ben %s, %s. Tanıştığımıza memnun oldum! Bir gün birlikte savaşırız belki." % [given, RANKS[rank]], [])
	Hud.msg("Yeni tanıdık: %s (Tab > Görevler > Arkadaşlar)" % given, Color(0.6, 1.0, 0.7))


static func set_party(id: String, on: bool) -> bool:
	var f: Dictionary = all().get(id, {})
	if f.is_empty():
		return false
	if on:
		if not available(f):
			Hud.msg("%s şu an köyde değil." % f["name"], Color(1, 0.7, 0.4))
			return false
		if party_ids().size() >= PARTY_MAX:
			Hud.msg("Takımın dolu (en fazla %d arkadaş). Önce birini köyde beklet." % PARTY_MAX, Color(1, 0.7, 0.4))
			return false
		f["party"] = true
		Hud.msg("%s takımına katıldı!" % f["name"], Color(0.6, 1.0, 0.7))
	else:
		f["party"] = false
		Hud.msg("%s köyde bekleyecek." % f["name"], Color(0.7, 0.9, 1.0))
	return true


## Oyuncu köyden kaçınca: herkes kırılır, takım dağılır
static func on_player_defect() -> void:
	for id in all():
		var f: Dictionary = all()[id]
		f["party"] = false
		add_bond(id, -35 if int(f["bond"]) < 60 else -20, true)
		log_event(f, "Köyden kaçmana çok kızdı")
	if not all().is_empty():
		Hud.msg("Köydeki dostların kaçışını duydu. Çoğu sana küstü.", Color(1, 0.55, 0.5), 5.0)


static func on_player_pardon() -> void:
	for id in all():
		add_bond(id, 10, true)


## Ninja dostun savaşçı arketipi: seviye oyuncuya ve rütbesine göre
static func arch(f: Dictionary) -> Dictionary:
	var lv = maxi(5, int(pr().get("level", 1)) - 2 + int(f.get("rank", 0)) * 4 + randi_range(-1, 1))
	var c = String(f.get("clan", ""))
	var a: Dictionary
	if c != "":
		a = ClanWorld.make_enemy(c, lv, {"outfit": "chunin", "village": String(f.get("village", "konoha")), "female": f["look"].get("gender", "m") == "f"})
		a["aggr"] = 0.6
	else:
		a = Enemy.archetype("genin_rival", 0)
		a["no_clan"] = true
		a["element"] = f.get("element", "katon")
		var auto = Enemy.auto_jutsu("genin_rival", String(a["element"]), lv)
		if not auto.is_empty():
			a["jutsu"] = auto
			a["auto_jutsu"] = auto.duplicate()
			a["auto_lv"] = lv
	a["name"] = "%s (%s)" % [f["name"], RANKS[int(f.get("rank", 0))]]
	a["respawn"] = false
	a["hp"] = 240.0 + lv * 16.0
	a["level"] = lv
	a["power"] = 0.9 + lv * 0.011
	a["xp"] = 0
	a["ryo"] = 0
	var L: Dictionary = a["look"]
	L.merge(look_of(f), true)
	var hi = Progress.home_info()
	L["band"] = hi["band"]
	L["band_style"] = "head"
	L["village"] = Progress.home()
	if int(f.get("rank", 0)) >= 1:
		L["vest"] = hi["vest"]
	return a


# ------------------------------------------------------------------ dinamik yaşam
func _life_event() -> void:
	var fs = all()
	var home_ids = fs.keys().filter(func(k): return String(fs[k].get("status", "")) == "")
	if not home_ids.is_empty():
		var id = String(home_ids.pick_random())
		var f: Dictionary = fs[id]
		var now = Time.get_unix_time_from_system()
		var b = int(f["bond"])
		var rank = int(f.get("rank", 0))
		var fam: Array = f.get("family", [])
		var spouse = fam.any(func(m): return String(m["rel"]) in ["Karısı", "Kocası"])
		var defect_p = 0.03 + (0.1 if b < 0 else 0.0) + (0.08 if f.get("grief", false) else 0.0) - (0.025 if b >= 60 else 0.0)
		var r = randf()
		if r < defect_p:
			_defect(id)
		elif r < defect_p + 0.3 and rank < 3 and randf() < [0.9, 0.6, 0.35][rank]:
			f["rank"] = rank + 1
			log_event(f, "%s oldu" % RANKS[rank + 1])
			f["news"] = "Duydun mu? Artık %s oldum! Yeleği giyince insan bir tuhaf oluyor." % RANKS[rank + 1]
			Hud.msg("Haber: %s %s oldu!" % [f["name"], RANKS[rank + 1]], Color(0.6, 1.0, 0.75), 5.0)
		elif r < defect_p + 0.42 and not spouse and rank >= 1 and romance_of(id) == "":
			var fem = String(f["look"].get("gender", "m")) == "f"
			# eş kimi zaman köyün başka bir klanından: çocukları melez olur
			var vclans: Array = []
			for c in Data.clans:
				if c != "none" and String(f.get("village", "konoha")) in Data.clans[c].get("villages", []) and not c in Progress.UNPLAYABLE_CLANS and c != String(f.get("clan", "")):
					vclans.append(c)
			var sc = String(vclans.pick_random()) if not vclans.is_empty() and randf() < 0.45 else ""
			var sp = ClanWorld.person_name(sc, not fem) if sc != "" else "%s %s" % [String(Missions.BB_FAMILY.pick_random()), (ClanWorld.GIVEN_M if fem else ClanWorld.GIVEN_F).pick_random()]
			fam.append({"rel": "Kocası" if fem else "Karısı", "name": sp, "alive": true, "clan": sc})
			log_event(f, "%s ile evlendi" % sp)
			f["news"] = "%s ile evlendim! Düğüne gelemedin ama hediyeni bekliyorum, haha." % sp
			Hud.msg("Haber: %s, %s ile evlendi." % [f["name"], sp], Color(1, 0.85, 0.6), 5.0)
		elif r < defect_p + 0.52 and spouse and fam.filter(func(m): return String(m["rel"]) in ["Oğlu", "Kızı"]).size() < 3:
			var kf = randf() < 0.5
			var sur = String(f["name"]).split(" ")[0] if " " in String(f["name"]) else String(Missions.BB_FAMILY.pick_random())
			var kn = "%s %s" % [sur, (ClanWorld.GIVEN_F if kf else ClanWorld.GIVEN_M).pick_random()]
			var sclan = ""
			for m2 in fam:
				if String(m2["rel"]) in ["Karısı", "Kocası"]:
					sclan = String(m2.get("clan", ""))
			var kid = {"rel": "Kızı" if kf else "Oğlu", "name": kn, "alive": true}
			if sclan != "" and String(f.get("clan", "")) != "" and sclan != String(f["clan"]):
				kid["mix"] = "%s × %s melezi" % [ClanWorld.clan_name(String(f["clan"])), ClanWorld.clan_name(sclan)]
			fam.append(kid)
			log_event(f, "%s adında bir %s oldu" % [kn, "kızı" if kf else "oğlu"])
			f["news"] = "Bir %s oldu! Adı %s. Bir gün akademiye gidecek." % ["kızım" if kf else "oğlum", kn]
			Hud.msg("Haber: %s'in bir %s oldu." % [f["name"], "kızı" if kf else "oğlu"], Color(1, 0.85, 0.6), 5.0)
		elif r < defect_p + 0.7:
			f["away"] = now + randf_range(300.0, 600.0)
			log_event(f, "Uzun bir göreve çıktı")
			f["news"] = "Görevden yeni döndüm. Sınırda işler karışık, haberin olsun."
			Hud.msg("Haber: %s uzun bir göreve çıktı." % f["name"], Color(0.7, 0.85, 1.0))
		elif r < defect_p + 0.8:
			f["away"] = now + 300.0
			log_event(f, "Görevde yaralandı, hastanede")
			f["news"] = "Hastaneden çıktım. Bir dahaki sefere kimseye sırtımı dönmeyeceğim."
			Hud.msg("Haber: %s görevde yaralandı, hastanede yatıyor." % f["name"], Color(1, 0.75, 0.5))
		elif r < defect_p + 0.84:
			f["status"] = "öldü"
			f["party"] = false
			log_event(f, "Bir görevde öldü")
			Hud.banner("KÖTÜ HABER", "%s bir görevden dönmedi. Köy onu kahraman olarak anıyor." % f["name"], Color(0.8, 0.8, 0.9))
		else:
			var alive = fam.filter(func(m): return m.get("alive", true) and String(m["rel"]) in ["Babası", "Annesi"])
			if not alive.is_empty():
				var m: Dictionary = alive.pick_random()
				m["alive"] = false
				f["grief"] = true
				log_event(f, "%s (%s) bir görevde öldü" % [m["name"], String(m["rel"]).to_lower()])
				f["news"] = "%s... bir görevden dönmedi. Bu köy için savaştı. Ben de öyle yapacağım... sanırım." % m["name"]
				Hud.msg("Haber: %s'in %s bir görevde hayatını kaybetti." % [f["name"], String(m["rel"]).to_lower().trim_suffix("ı").trim_suffix("i")], Color(0.8, 0.8, 0.9), 5.0)
	# köyden kimi zaman tanımadığın ninjalar da kaçar (Bingo Kitabı'na girer)
	if randf() < 0.12:
		var e: Dictionary = Missions._bb_new(["C", "B", "B", "A"].pick_random())
		var hv = Progress.home()
		e["village"] = hv
		e["look"]["village"] = hv
		e["crimes"].append("%s köyünden kaçtı" % Game.village(hv).get("name", hv))
		Missions._bingo()["list"].append(e)
		Hud.msg("Haber: köyden bir ninja kaçtı — %s (Bingo Kitabı)" % e["name"], Color(1, 0.6, 0.5), 5.0)


## Dost köyden kaçar: takımdan ayrılır, Bingo Kitabı'na girer (yakalarsan öldürmek ya da affettirmek sana kalmış değil: o artık kaçak)
func _defect(id: String) -> void:
	var f: Dictionary = all()[id]
	f["status"] = "kaçak"
	f["party"] = false
	var rank = int(f.get("rank", 0))
	var e: Dictionary = Missions._bb_new(["C", "B", "A", "S"][rank])
	e["name"] = String(f["name"])
	e["alias"] = ["Dönek", "Kayıp Gölge", "Kırık Bant", "Yalnız Kurt"].pick_random()
	e["village"] = String(f.get("village", Progress.home()))
	var lk = look_of(f)
	for k in lk:
		e["look"][k] = Missions._hex(lk[k]) if lk[k] is Color else lk[k]
	e["look"]["band_style"] = "slashed"
	e["look"]["village"] = e["village"]
	if String(f.get("clan", "")) != "":
		e["clan"] = f["clan"]
	else:
		e.erase("clan")
	e["crimes"] = ["%s köyünden kaçtı" % Game.village(e["village"]).get("name", e["village"]),
		"Eskiden senin %s idi" % level_name(maxi(0, int(f["bond"]))).to_lower()]
	if int(f["bond"]) <= -30:
		e["crimes"].append("Sana kin besliyor")
	e["friend_id"] = id
	Missions._bingo()["list"].append(e)
	log_event(f, "Köyden kaçtı — artık Bingo Kitabı'nda")
	Hud.banner("%s KÖYDEN KAÇTI" % String(f["name"]).to_upper(), "Bandını çizip gitti. Artık Bingo Kitabı'nda bir kaçak.", Color(1, 0.45, 0.4))


## Dost gözünün önünde öldü: kalıcı. Yakın dostsa ve 3 tomoe Sharingan'ın varsa acı Mangekyō'yu uyandırır.
func _die_in_battle(id: String, n: Node) -> void:
	var f: Dictionary = all()[id]
	f["status"] = "öldü"
	f["party"] = false
	log_event(f, "Senin yanında savaşırken öldü")
	Hud.banner("%s ÖLDÜ" % String(f["name"]).to_upper(), "Son nefesinde sana gülümsedi. %s onu asla unutmayacak." % Game.village(String(f.get("village", Progress.home()))).get("name", "Köy"), Color(0.85, 0.85, 0.95))
	if int(f["bond"]) >= 50 and n != null and is_instance_valid(n) and Game.player.combat and Game.player.combat.modes and Game.player.combat.modes.get("eyes"):
		Game.player.combat.modes.eyes.on_ally_died(n)


## Kaçak dostun Bingo durumu: "alive" / "dead" / ""
static func bingo_status(id: String) -> String:
	if Game.profile.is_empty() or not Game.profile.has("bingo"):
		return ""
	for e in Game.profile["bingo"].get("list", []):
		if String(e.get("friend_id", "")) == id:
			return String(e.get("status", ""))
	return ""


# ------------------------------------------------------------------ dünyada eşlik
func _active() -> bool:
	if pr().is_empty() or Game.player == null or not is_instance_valid(Game.player):
		return false
	if Exams.cur != "" or int(ChuninExam.stage) != 0:
		return false
	var life = get_parent().get_node_or_null("VillageLife")
	if life and life.interiors and life.interiors.inside != "":
		return false
	return true


func _despawn(m: Dictionary) -> void:
	var n = m.get("node")
	if n != null and is_instance_valid(n):
		FX.smoke_puff(n.global_position + Vector3.UP, 0.6, 8)
		n.queue_free()


func _spawn(id: String) -> Node:
	var f: Dictionary = all()[id]
	var e = Enemy.new()
	e.setup(arch(f))
	e.team = "player"
	e.set_meta("teammate", true)
	e.set_meta("respawn", false)
	e.set_meta("friend_id", id)
	get_tree().current_scene.add_child(e)
	if e.nameplate:
		e.nameplate.modulate = Color(0.55, 1.0, 0.75)
	var c = String(f.get("clan", ""))
	if c != "":
		var ek: Array = f.get("eye", [0, 0])
		if int(ek[0]) > 0:
			Eyes.give_enemy_eyes(e, int(ek[0]), maxi(1, int(ek[1])))
		var tr = ClanTrait.new()
		tr.name = "ClanTrait"
		tr.clan = c
		tr.eye_kind = int(ek[0])
		e.add_child(tr)
	var pp = Game.player.global_position
	var back = -Game.player.face_dir() if Game.player.has_method("face_dir") else Vector3.BACK
	var q = pp + back * 4.0 + back.cross(Vector3.UP) * randf_range(-3.0, 3.0)
	q.y = Game.ground_height(q.x, q.z)
	e.global_position = q
	e.home = q
	FX.smoke_puff(q + Vector3.UP, 0.8, 10)
	return e


## Köydeyken takımda olmayan bir dostun ara sıra seni görüp yanına gelir (düşmanların da gelir: laf atar)
func _visit(dt: float) -> void:
	visit_t -= dt
	if visitor != null and is_instance_valid(visitor):
		if visitor.global_position.distance_to(Game.player.global_position) > 90.0 or visit_t < -150.0:
			visitor.vanish()
			visitor = null
		elif visitor.global_position.distance_to(Game.player.global_position) > 3.5:
			visitor.goal = Game.player.global_position
		return
	if visit_t > 0.0:
		return
	visit_t = randf_range(120.0, 240.0)
	if Orgs.is_rogue():
		# kaçakken dostların (kaçak olanlar) sığınakta seni bulur
		if Game.player.global_position.distance_to(Orgs.hideout_pos()) > 70.0:
			return
	else:
		var v = Game.village(Progress.home())
		if v.is_empty() or Game.to_map(Game.player.global_position).distance_to(Vector2(v["x"], v["y"])) > float(v["r"]):
			return
	var cands = all().keys().filter(func(k): return not all()[k].get("party", false) and available(all()[k]))
	if cands.is_empty():
		return
	var id = String(cands.pick_random())
	var f: Dictionary = all()[id]
	var vg: Villager
	if String(f.get("clan", "")) != "":
		var r = ClanResident.new()
		r.clan = String(f["clan"])
		r.vid = String(f.get("village", "konoha"))
		r.given = String(f["name"])
		var ek: Array = f.get("eye", [0, 0])
		r.eye_kind = int(ek[0])
		r.eye_lvl = int(ek[1])
		r.lines_override = ClanWorld.LORE.get(r.clan, ["Köyümüzü korumak görevimiz."])
		vg = r
	else:
		vg = Villager.new()
	vg.role = "nurse"
	var lk = look_of(f)
	if int(f.get("rank", 0)) >= 1:
		lk["vest"] = Progress.home_info()["vest"]
	vg.look_extra = lk
	vg.display_override = String(f["name"])
	vg.set_meta("friend_id", id)
	get_parent().add_child(vg)
	var d = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * 16.0
	var q = Game.player.global_position + d
	q.y = Game.ground_height(q.x, q.z)
	vg.global_position = q
	vg.home = q
	vg.goal = Game.player.global_position
	visitor = vg
	visit_t = 0.0
	var b = int(f["bond"])
	Hud.msg(("%s seni gördü, yanına geliyor." if b >= 0 else "%s sana doğru geliyor... pek dostça görünmüyor.") % f["name"], level_color(b))


func _process(dt: float) -> void:
	if Game.paused:
		return
	if _active() and not all().is_empty():
		_visit(dt)
		_baby_tick()
		life_t -= dt
		if life_t <= 0.0:
			life_t = randf_range(240.0, 480.0)
			_life_event()
	t -= dt
	if t > 0.0:
		return
	t = 0.4
	var ids = party_ids() if _active() else []
	# takımdan çıkanları kaldır, yenileri ekle
	for m in members.duplicate():
		if not m["id"] in ids:
			_despawn(m)
			members.erase(m)
	for id in ids:
		if members.filter(func(m): return m["id"] == id).is_empty():
			members.append({"id": id, "node": null, "down": 0.0})
	if members.is_empty():
		return
	bond_t += 0.4
	if bond_t >= 90.0:
		bond_t = 0.0
		for m in members:
			if m["node"] != null:
				add_bond(m["id"], 1, true)
	var pp = Game.player.global_position
	var i = 0
	for m in members:
		var n = m["node"]
		if n != null and is_instance_valid(n) and not n.is_dead():
			var off = Vector3(cos(i * 2.4 + 0.6), 0, sin(i * 2.4 + 0.6)) * 4.0
			n.home = pp + off
			if n.global_position.distance_to(pp) > 60.0:
				var q = pp + off
				q.y = Game.ground_height(q.x, q.z)
				FX.smoke_puff(n.global_position + Vector3.UP, 0.6, 8)
				n.global_position = q
				n.target = null
				FX.smoke_puff(q + Vector3.UP, 0.6, 8)
			elif n.target == null:
				n.wander_to = pp + off
		elif n != null and (not is_instance_valid(n) or n.is_dead()):
			m["node"] = null
			m["down"] = RETURN_T
			var f: Dictionary = all()[m["id"]]
			if randf() < DEATH_P:
				_die_in_battle(m["id"], n)
			else:
				Hud.msg("%s yaralandı ve geri çekildi. Biraz sonra yanına döner." % f["name"], Color(1, 0.75, 0.5))
		elif float(m["down"]) > 0.0:
			m["down"] = float(m["down"]) - 0.4
		else:
			m["node"] = _spawn(m["id"])
		i += 1


## Takımdaki dostun yanında [F]
func _unhandled_input(ev: InputEvent) -> void:
	if not ev.is_action_pressed("interact") or Game.player == null or Game.paused:
		return
	for m in members:
		var n = m.get("node")
		if n != null and is_instance_valid(n) and not n.is_dead() and n.global_position.distance_to(Game.player.global_position) < 3.0:
			get_viewport().set_input_as_handled()
			var fid = String(m["id"])
			var opts = _friend_opts(fid, null)
			opts.append({"label": "İhanet et (saldır!)", "cb": func():
				var c = Crime.inst()
				if c:
					members.erase(m)
					c.betray(n, fid)})
			Hud.dialog(String(all()[fid]["name"]), greeting(fid), opts)
			return
