extends Node
## RPG ilerleme (autoload "Progress"): XP/seviye, rütbe, hikâye zinciri, hocalar, etkileşimler, öğrenme.

## Oyuncunun köyüne göre: Kage unvanı, hocalar, alın koruyucu/yelek rengi, önerilen element
const HOME_VILLAGES := {
	"konoha": {"kage": "Hokage", "s1": "Hoshino-sensei", "s2": "Kurogane-sensei", "band": Color(0.15, 0.22, 0.55), "vest": Color(0.38, 0.48, 0.28), "element": "katon", "lookout": "Hokage Kayası", "dir": "köyün kuzeybatısı"},
	"suna": {"kage": "Kazekage", "s1": "Takeru-sensei", "s2": "Saji-sensei", "band": Color(0.42, 0.33, 0.22), "vest": Color(0.72, 0.62, 0.45), "element": "fuuton", "lookout": "Gözetleme Kulesi", "dir": "köyün içindeki Akademi yerleşkesi"},
	"kiri": {"kage": "Mizukage", "s1": "Nagisa-sensei", "s2": "Shiozaki-sensei", "band": Color(0.2, 0.26, 0.38), "vest": Color(0.42, 0.5, 0.45), "element": "suiton", "lookout": "Sis Kulesi", "dir": "köyün içindeki Akademi yerleşkesi"},
	"kumo": {"kage": "Raikage", "s1": "Raizo-sensei", "s2": "Kumoji-sensei", "band": Color(0.12, 0.12, 0.14), "vest": Color(0.85, 0.85, 0.82), "element": "raiton", "lookout": "Bulut Kayası", "dir": "köyün içindeki Akademi yerleşkesi"},
	"iwa": {"kage": "Tsuchikage", "s1": "Ganseki-sensei", "s2": "Tsuchiya-sensei", "band": Color(0.45, 0.18, 0.15), "vest": Color(0.55, 0.25, 0.2), "element": "doton", "lookout": "Taş Kule", "dir": "köyün içindeki Akademi yerleşkesi"},
}

## Akademi başlangıcı (0..3) metinleri; sonrası serbest oyun (Journal). Köye göre {kage}, {vn}, {s1}... doldurulur.
const STORY_T := [
	"Ninja Akademisi'ne git ve hocan {s1} ile konuş. (Akademi, {dir})",
	"Akademi avlusundaki kuklalara 25 darbe vur, sonra hocana dön.",
	"Hocandan Henge no Jutsu'yu öğren ve bir kez kullan [slot 1].",
	"Mezuniyet Sınavı: hocanla konuş (yazılı + Bunshin/Henge/Kawarimi + hedef parkuru), ardından {s2} ile Zil Testi.",
	# 4: serbest oyun — sabit ana hikâye yok; metin Journal.objective_text() ile oyuncunun kendi hedeflerinden kurulur
	"Yolun açık.",
]
var STORY: Array = []


func _ready() -> void:
	refresh_story()


func home() -> String:
	var h = String(Game.profile.get("village", "konoha")) if not Game.profile.is_empty() else "konoha"
	return h if HOME_VILLAGES.has(h) else "konoha"


func home_info() -> Dictionary:
	return HOME_VILLAGES[home()]


func kage_title(vid: String) -> String:
	return HOME_VILLAGES.get(vid, {}).get("kage", "Köy Lideri")


## Hikâye metinlerini oyuncunun köyüne göre yeniden kurar (yeni oyun / kayıt yükleme)
func refresh_story() -> void:
	var info = home_info()
	var vn = String(Game.village(home()).get("name", "Konoha")) if Game.world_info.has("villages") else "Konoha"
	STORY.clear()
	for t in STORY_T:
		STORY.append(String(t).replace("{kage}", info["kage"]).replace("{vn}", vn).replace("{s1}", info["s1"]).replace("{s2}", info["s2"])
			.replace("{lookout}", info["lookout"]).replace("{dir}", info["dir"]))


## Yeni oyunda doğma noktası: akademinin önü (Konoha'da eski nokta)
func home_spawn() -> Vector3:
	var vid = home()
	var v = Game.village(vid)
	if vid == "konoha":
		return Game.from_map(Vector2(v["x"] - 120, v["y"] + 120))
	var c = Vector2(v["x"], v["y"])
	var best = {}
	var bd = 1e12
	for it in Interact.items:
		if it["kind"] == "academy":
			var d = Game.to_map(it["pos"]).distance_to(c)
			if d < bd:
				bd = d; best = it
	if not best.is_empty():
		return best["pos"] + Vector3(0, 0.5, 10)
	return Game.from_map(c + Vector2(0, -float(v["r"]) * 0.4))


func p() -> Dictionary:
	return Game.profile


func story() -> int:
	return int(p().get("story", 0))


func set_story(i: int) -> void:
	# hikâye adımı tamamlama ödülü (erken adımlar seviye atlatır)
	i = mini(i, Journal.FREE)
	var prev = int(p().get("story", 0))
	if i > prev:
		add_xp(80 + 60 * i)
	p()["story"] = i
	if i == Journal.FREE and prev < Journal.FREE:
		# mezuniyet: bundan sonrası oyuncunun kendi hikâyesi
		Journal.add("Akademiden mezun oldun ve alın koruyucunu taktın. Bundan sonrasını sen yazacaksın.", "milestone")
		Hud.banner("YOLUN AÇIK", "Sabit bir hikâye yok — Tab > Görevler > Yolun", Color(1, 0.85, 0.45))
	Hud.objective_changed()
	Sfx.play("levelup", null, 1.3, 0.5)
	Game.save_game()


## Rütbe için sayılan görevler: D ve üstü (Genin'ken yapılan C-rank'ler de sayılır)
func genin_missions() -> int:
	var md: Dictionary = p().get("missions_done", {})
	var n = 0
	for r in ["D", "C", "B", "A", "S"]:
		n += int(md.get(r, 0))
	return n


## Hikâye hedef metni + ilerleme sayacı (HUD ve Görevler sekmesi kullanır)
func objective_text() -> String:
	var s = story()
	if s >= Journal.FREE:
		return Journal.objective_text()
	var t: String = STORY[mini(s, STORY.size() - 1)] if not STORY.is_empty() else ""
	var pr = p()
	if s == 3 and pr.get("flags", {}).get("academy_passed", false):
		t = "Mezun oldun! Zil Testi: Antrenman Alanı'na git ve %s ile konuş (oku takip et)." % home_info()["s2"]
	elif s == 3:
		t = "Mezuniyet Sınavı: Akademi'de hocan %s ile konuş (Seviye %d/5)." % [home_info()["s1"], int(pr.get("level", 1))]
	return t


func new_profile(opts: Dictionary) -> Dictionary:
	var pr = {
		"slot": opts.get("slot", 1), "name": opts.get("name", "İsimsiz"), "gender": opts.get("gender", "m"),
		"clan": opts.get("clan", "none"), "elements": [opts.get("element", "katon")], "element_known": false,
		"look": opts.get("look", {}), "level": 1, "xp": 0, "rank": 0, "ryo": 150, "sp": 0, "skills": [],
		"learned": [], "slots": ["", "", "", "", "", ""], "inventory": {"kunai": 12, "shuriken": 6, "salve": 2},
		"throw_sel": "kunai", "summon": "kurbağa", "story": 0, "seed": randi(), "journal": [], "goals": [], "flags": {}, "missions_done": {"D": 0, "C": 0, "B": 0, "A": 0, "S": 0},
		"active_mission": {}, "visited": ["konoha", "suna", "kiri", "kumo", "iwa"], "stats": {"kills": 0}, "time": 0.32,
		"village": opts.get("village", "konoha"), "rep": {}, "bingo": {"list": [], "next": 1, "refresh": 900.0},
	}
	pr["look"]["village"] = pr["village"]
	# akademi öğrencisi: alın koruyucu yok
	pr["look"]["band"] = null
	return pr


# ------------------------------------------------------------------ XP / seviye
func add_xp(amount: int) -> void:
	var pr = p()
	amount = int(amount * Exams.xp_mult() * (1.0 + Stats.skill(pr, "xp")))
	pr["xp"] = int(pr["xp"]) + amount
	Hud.float_text("+%d XP" % amount, Color(0.7, 0.9, 1.0))
	if int(pr["level"]) >= Data.MAX_LEVEL:
		pr["xp"] = 0
		return
	while int(pr["level"]) < Data.MAX_LEVEL and int(pr["xp"]) >= Data.xp_for_level(int(pr["level"])):
		pr["xp"] = int(pr["xp"]) - Data.xp_for_level(int(pr["level"]))
		pr["level"] = int(pr["level"]) + 1
		# her seviye 1 puan, her 10 seviyede +2 bonus (yetenek ağacı: data/skills.json)
		var gain = int(Data.skills.get("sp_per_level", 1)) + (int(Data.skills.get("sp_milestone", 2)) if int(pr["level"]) % 10 == 0 else 0)
		pr["sp"] = int(pr["sp"]) + gain
		Hud.banner("SEVİYE %d" % pr["level"], "+%d yetenek puanı  [Tab > Yetenekler]" % gain, Color(1, 0.85, 0.35))
		Sfx.play("levelup")
		if Game.player:
			Game.player.apply_profile_stats()
			Game.player.hp = Game.player.max_hp
			Game.player.chakra = Game.player.max_chakra
			FX.aura(Game.player, Color(1, 0.85, 0.4), 1.4)
		_check_story_levels()
		clan_unlocks()


## Klan teknikleri: seviye şartı karşılanınca otomatik öğrenilir
## Seviye/klan/göz/doğa ile kendiliğinden açılan jutsular: klan hiden'leri, uyanmış kekkei genkai,
## takılı dōjutsu gözü teknikleri, sennin modu teknikleri. Seviye atlayınca ve ekipman değişince çağrılır.
func clan_unlocks(announce := true) -> void:
	var pr = p()
	if pr.is_empty():
		return
	_check_kg_awaken(announce)
	var lv = int(pr["level"])
	for jid in Data.jutsu.keys():
		if jid.begins_with("_") or jid in pr["learned"]:
			continue
		var j: Dictionary = Data.jutsu[jid]
		var lp = String(j.get("learn", ""))
		var ok = false
		if lp == "clan" or lp == "clan:" + String(pr.get("clan", "")):
			ok = lp != "clan" or j.get("clan", "") == pr.get("clan", "")
		elif lp.begins_with("kg:"):
			ok = has_nature(lp.substr(3))
		elif lp.begins_with("eye:"):
			ok = has_eye(lp.substr(4))
		elif lp == "sage:any":
			ok = "sage" in pr.get("skills", [])
		# göz teknikleri gözle gelir: rütbe şartı aranmaz (Rinnegan takılıyken teknikleri hiç açılmıyordu)
		if ok and lv >= int(j.get("level", 1)) and (lp.begins_with("eye:") or int(pr.get("rank", 0)) >= int(j.get("rank", 0))):
			learn(jid, announce)


# ------------------------------------------------------------------ doğalar (element + kekkei genkai) ve öğrenme şartları
const EYE_KINDS := {"sharingan": [1, 4, 5], "mangekyo": [4, 5], "ems": [5], "rinnegan": [6], "rinne_sharingan": [], "byakugan": [2],
	"tenseigan": [7], "jogan": [8], "ketsuryugan": [3], "kokugan": []}


## Temel chakra doğası ya da uyanmış kekkei genkai (mokuton, hyoton, yoton, ... shikotsumyaku)
func has_nature(n: String) -> bool:
	var pr = p()
	if pr.is_empty():
		return false
	if n in pr.get("elements", []) or n in pr.get("natures", []):
		return true
	return false


## Kekkei genkai görevi bitti (Missions hook)
func kg_quest_done(m: Dictionary, ok: bool) -> void:
	KgPaths.quest_done(m, ok)


## Kekkei genkai uyanışı (klan soyu, nadir olay ya da görev ödülü)
func awaken_nature(n: String, announce := true) -> void:
	var pr = p()
	if pr.is_empty() or has_nature(n):
		return
	if not pr.has("natures"):
		pr["natures"] = []
	pr["natures"].append(n)
	if announce:
		Hud.banner("KEKKEI GENKAI UYANDI", Elements.NAMES.get(n, n.capitalize()), Color(0.9, 0.75, 0.3))
		Sfx.play("levelup", null, 0.6)
	clan_unlocks(announce)


func _check_kg_awaken(announce: bool) -> void:
	var pr = p()
	var cl: Dictionary = Data.clans.get(pr.get("clan", "none"), {})
	for n in cl.get("kg_natures", []):
		if int(pr["level"]) >= int(cl.get("kg_level", 1)) and not has_nature(n):
			if not pr.has("natures"):
				pr["natures"] = []
			pr["natures"].append(n)
			if announce:
				Hud.banner("KEKKEI GENKAI UYANDI", Elements.NAMES.get(n, n.capitalize()), Color(0.9, 0.75, 0.3))


func has_eye(kind: String) -> bool:
	if kind == "rinne_sharingan":   # alında üçüncü göz (Rinnegan + Altı Yol evrimi)
		return bool(p().get("flags", {}).get("rinne_sharingan", false))
	var want: Array = EYE_KINDS.get(kind, [])
	for slot in ["sag_goz", "sol_goz"]:
		var g = Gear.equipped(p(), slot)
		if not g.is_empty() and int(Gear.item(g["id"]).get("eye", {}).get("kind", 0)) in want:
			return true
	return false


## Bir jutsuyu şu an öğrenebilir mi? "" = evet, değilse sebep
func can_learn(jid: String) -> String:
	var pr = p()
	var j: Dictionary = Data.jutsu.get(jid, {})
	if j.is_empty():
		return "Bilinmeyen jutsu"
	if jid in pr["learned"]:
		return "Zaten biliyorsun"
	if int(pr["level"]) < int(j.get("level", 1)):
		return "Seviye %d gerekli" % int(j.get("level", 1))
	if int(pr.get("rank", 0)) < int(j.get("rank", 0)):
		return "%s rütbesi gerekli" % Data.RANKS[int(j.get("rank", 0))]
	for el in j.get("elements", []):
		if not has_nature(el):
			return "%s doğası gerekli" % Elements.NAMES.get(el, el)
	var lp = String(j.get("learn", ""))
	if lp.begins_with("kg:") and not has_nature(lp.substr(3)):
		return "Kekkei genkai gerekli: %s" % lp.substr(3)
	if lp.begins_with("eye:") and not has_eye(lp.substr(4)):
		return "Göz gerekli: %s" % lp.substr(4)
	if lp.begins_with("clan:") and lp.substr(5) != pr.get("clan", ""):
		return "Klan tekniği"
	if lp == "sage:any" and not "sage" in pr.get("skills", []):
		return "Sennin modu gerekli"
	if lp in ["kinjutsu", "quest:signature", "quest:hiden", "quest:contract"]:
		return "Özel görevle öğrenilir"
	if lp.begins_with("path:"):
		return "Efsane Yolu: %s ustası öğretir" % LegendPaths.PATHS.get(lp.substr(5), {}).get("name", "bir yolun")
	return ""


## Eğitmen seçenekleri: kinds = ["konoha", "jonin", "taijutsu", ...] -> Hud.dialog seçenekleri
func trainer_options(kinds: Array, max_n := 8) -> Array:
	var pr = p()
	var list = []
	for jid in Data.jutsu.keys():
		if jid.begins_with("_"):
			continue
		var j: Dictionary = Data.jutsu[jid]
		var lp = String(j.get("learn", ""))
		if not lp.begins_with("trainer:") or not lp.substr(8) in kinds or jid in pr["learned"]:
			continue
		if can_learn(jid) != "":
			continue
		list.append(jid)
	list.sort_custom(func(a, b): return int(Data.jutsu[a].get("level", 1)) < int(Data.jutsu[b].get("level", 1)))
	var opts = []
	for jid in list.slice(0, max_n):
		var j: Dictionary = Data.jutsu[jid]
		var price = [150, 300, 600, 1200, 2200, 4000][clampi(int(j.get("tier", 2)), 0, 5)]
		opts.append({"label": "%s [%s] — %d Ryō" % [j["name"], j.get("canon_rank", "?"), price], "tip": j.get("desc", ""),
			"cb": func(): _buy_learn(jid, price)})
	return opts


## Köy eğitmeni: köyün element uzmanlığı + genel dallar (rütbeye göre)
func village_trainer_options(vid: String) -> Array:
	var kinds = [vid, "taijutsu", "genjutsu", "academy"]
	if int(p().get("rank", 0)) >= 2:
		kinds.append_array(["jonin", "fuin"])
	return trainer_options(kinds)


## Parşömenlerde yalnız temel beş element jutsusu satılır; klan, kekkei genkai, yol ve karakter imza teknikleri
## (kâğıt klonu, kurbağa yağı, kuzgun klonu, kum kolu, kılıç stilleri...) parşömenle değil kendi yollarıyla öğrenilir
const SCROLL_BASIC := ["katon", "suiton", "fuuton", "doton", "raiton"]
const SCROLL_BANNED := ["kusanagi_no_tsurugi_chidorigatana", "kumo_ryu_kaengiri", "nadeshiko_ryu_koha_reppuken", "mujin_meisai", "nezumi_kedama"]


static func scroll_sellable(jid: String) -> bool:
	var j: Dictionary = Data.jutsu.get(jid, {})
	var els: Array = j.get("elements", [])
	if j.is_empty() or els.is_empty() or jid in SCROLL_BANNED or String(j.get("clan", "")) != "":
		return false
	for el in els:
		if not el in SCROLL_BASIC:
			return false
	return true


## Dükkânda gösterilecek jutsu parşömenleri: oyuncunun doğasına uygun, seviyesine yakın
func scroll_shop_items(max_n := 10, extra_lv := 0) -> Array:
	var pr = p()
	var out = []
	for iid in Data.items.keys():
		var it: Dictionary = Data.items[iid]
		if it.get("kind", "") != "scroll":
			continue
		var jid = String(it.get("jutsu", ""))
		var j: Dictionary = Data.jutsu.get(jid, {})
		if not scroll_sellable(jid) or jid in pr["learned"] or int(j.get("level", 1)) > int(pr["level"]) + 4 + extra_lv:
			continue
		var natured = true
		for el in j.get("elements", []):
			if not has_nature(el):
				natured = false
		if natured:
			out.append(iid)
	out.sort_custom(func(a, b): return int(Data.jutsu[Data.items[a]["jutsu"]].get("level", 1)) > int(Data.jutsu[Data.items[b]["jutsu"]].get("level", 1)))
	return out.slice(0, max_n)


func add_ryo(amount: int) -> void:
	if amount > 0:
		amount = int(amount * (1.0 + Stats.skill(p(), "ryo")))
	p()["ryo"] = int(p()["ryo"]) + amount
	if amount > 0:
		Hud.float_text("+%d Ryō" % amount, Color(1, 0.85, 0.4))
		Sfx.play("coin")


func learn(jid: String, announce := true) -> bool:
	var pr = p()
	if jid in pr["learned"]:
		return false
	pr["learned"].append(jid)
	var slots: Array = pr["slots"]
	for i in slots.size():
		if slots[i] == "" or slots[i] == null:
			slots[i] = jid
			break
	if announce:
		Hud.banner("YENİ JUTSU", Data.jutsu[jid]["name"], Color(0.5, 0.85, 1.0))
		Sfx.play("levelup", null, 0.8)
	Game.save_game()
	return true


func promote(rank: int) -> void:
	var pr = p()
	pr["rank"] = rank
	var look: Dictionary = pr["look"]
	Gear.ensure(pr)
	var hi = home_info()
	match rank:
		1:
			Gear.grant(pr, "alin_koruyucu", "kafa", hi["band"])
			Gear.grant(pr, "alin_boyun", "", hi["band"])
			Hud.msg("Yeni ekipman: Alın Koruyucu  [Tab > Ekipman]", Color(0.6, 0.9, 1.0))
		2:
			var vest_id = "%s_yelek" % home()
			if home() == "konoha" or Gear.item(vest_id).is_empty():
				vest_id = "chunin_yelek"
			Gear.grant(pr, vest_id, "zirh", hi["vest"])
			Hud.msg("Yeni ekipman: Taktik Yelek  [Tab > Ekipman]", Color(0.6, 0.9, 1.0))
		3:
			var jid = "%s_jonin" % home()
			if Gear.item(jid).is_empty():
				jid = "konoha_jonin"
			Gear.grant(pr, jid, "dis")
			Hud.msg("Yeni ekipman: %s  [Tab > Ekipman]" % Gear.item(jid)["name"], Color(0.6, 0.9, 1.0))
		4:
			Gear.grant(pr, "anbu_zirh", "zirh")
			Hud.msg("Yeni ekipman: ANBU Zırhı  [Tab > Ekipman]", Color(0.6, 0.9, 1.0))
		5:
			Hud.msg("Kage adaylığın resmen ilan edildi.", Color(1, 0.85, 0.5))
		6:
			pass  # Kage.inaugurate cübbe ve şapkayı verir
	Gear.apply_look(pr)
	Hud.banner(Data.RANKS[rank].to_upper(), "Rütbe atladın!", Color(1, 0.6, 0.25))
	Sfx.play("levelup", null, 0.7)
	if Game.player:
		Game.player.rebuild_model()
	Game.save_game()


# ------------------------------------------------------------------ olay kancaları
func on_enemy_killed(e: Node) -> void:
	add_xp(kill_xp(e))
	add_ryo(int(e.ryo))
	p()["stats"]["kills"] = int(p()["stats"].get("kills", 0)) + 1
	Missions.on_kill(e)
	Orgs.on_enemy_killed(e)
	Journal.on_enemy_killed(e)


## Öldürme XP'si: düşmanın seviyesiyle büyür ama oyuncunun seviyesine göre sınırlıdır.
## (eskiden boss/Bingo XP'si hem seviye×30 hem de seviye çarpanıyla iki kez büyüyordu: tek kaçak = birkaç seviye)
func kill_xp(e: Node) -> int:
	var plv = int(p().get("level", 1))
	var elv = int(e.get("level")) if e.get("level") != null else 1
	var eff = mini(elv, plv + 4)   # çok üst seviye düşman da oyuncudan en fazla 4 seviye üstüymüş gibi sayılır
	var diff = clampf(1.0 + (elv - plv) * 0.05, 0.25, 1.4)   # zayıf düşmanlar az, güçlüler biraz fazla
	var xp = float(e.xp) * (1.0 + eff / 10.0) * diff
	var big = e.has_meta("bingo_id") or e.has_meta("boss_q") or e is Boss
	var cap = Data.xp_for_level(plv) * (0.6 if big else 0.18)   # tek öldürme: sıradan ≤ seviyenin %18'i, boss ≤ %60'ı
	return int(minf(xp, cap))


## Rinnegan uyanışı: iki gözde Ebedi Mangekyō ve Sv.70 → bir kez "Altı Yolun Mirası" görevi önerilir
var _rinne_t := 10.0


func _check_rinnegan_path(dt: float) -> void:
	_rinne_t -= dt
	if _rinne_t > 0.0:
		return
	_rinne_t = 8.0
	var pr = p()
	var f: Dictionary = pr.get("flags", {})
	if f.get("rinne_offer", false) or int(pr.get("level", 1)) < 70 or not Missions.active().is_empty():
		return
	for slot in ["sag_goz", "sol_goz"]:
		if String(Gear.equipped(pr, slot).get("id", "")) != "goz_ems":
			return
	f["rinne_offer"] = true
	var tomb = Missions._spot("ame", 1800, 3200)
	var t2 = [tomb[0] + 40.0, tomb[1] + 20.0]
	Hud.dialog("Gözlerindeki Ses", "Ebedi Mangekyō'nun derinliklerinde bir halka belirdi... Altı Yol'un Bilgesi'nin mirası seni çağırıyor. Mezarını bul, bekçilerini yen ve altı mühür taşını uyandır: gözlerin bir sonraki aşamaya geçecek.", [
		{"label": "Mezarı ara (S-rank görev)", "cb": func():
			Missions.accept({"title": "Altı Yolun Mirası", "rank": "S", "village": home(), "hook": "Progress.rinnegan_done", "giver": "Gözlerindeki Ses",
				"brief": "Altı Yol'un Bilgesi'nin unutulmuş mezarını bul. Mirasını koruyan bekçileri yen, altı yolun mühür taşlarını uyandır.",
				"steps": [
					{"kind": "goto", "at": tomb, "r": 30.0, "name": "Altı Yol Mezarı", "text": "Yağmur Ülkesi'nin ötesindeki unutulmuş mezarı bul."},
					{"kind": "kill", "at": tomb, "enemy": "rogue", "n": 4, "camp": true,
						"boss": {"name": "Mezar Bekçisi Ōgen", "hp": 9000.0, "level": 80, "power": 3.6, "style": "fuin"}, "text": "Mirası koruyan bekçileri yen."},
					{"kind": "points", "at": t2, "n": 6, "spread": 18, "label": "[F] Yolun mühür taşını uyandır", "fx": "seal", "text": "Altı yolun mühür taşlarını uyandır (6)."},
				]})},
		{"label": "Şimdi değil", "cb": func(): f["rinne_offer"] = false}])


func rinnegan_done(m: Dictionary, ok: bool) -> void:
	if not ok:
		p()["flags"]["rinne_offer"] = false
		return
	var pr = p()
	for slot in ["sag_goz", "sol_goz"]:
		var g = Gear.equipped(pr, slot)
		if not g.is_empty():
			pr["gear"].erase(g)
		Gear.grant(pr, "goz_rinnegan", slot, null, null, {"lvl": 3, "origin": "uyanis"})
	Gear.apply_look(pr)
	if Game.player:
		Game.player.rebuild_model()
		FX.aura(Game.player, Color(0.7, 0.6, 1.0), 2.0, Vector3(0, 0.9, 0), 3.0)
		FX.ring(Game.player.global_position + Vector3.UP, Color(0.8, 0.75, 1.0), 14.0, 0.8)
	Hud.banner("RINNEGAN UYANDI", "Altı Yol'un gözleri artık senin. Rinnegan teknikleri açıldı [Tab > Jutsu]", Color(0.75, 0.65, 1.0))
	Sfx.play("genjutsu", null, 0.6)
	Game.save_game()


func on_hit_landed(t: Node) -> void:
	Exams.on_hit(t)


func on_dummy_hit(_d: Node, _dmg: float) -> void:
	var pr = p()
	if story() == 1:
		pr["flags"]["dummy_hits"] = int(pr["flags"].get("dummy_hits", 0)) + 1
		Hud.objective_progress("Kukla darbeleri: %d/25" % pr["flags"]["dummy_hits"])
	if pr["flags"].get("grad_exam", false):
		pass


func on_dummy_broken(_d: Node) -> void:
	var pr = p()
	# antrenman: düşük seviyede kukla devirmek biraz XP verir (Sv.10'dan sonra vermez)
	if int(pr.get("level", 1)) < 10:
		add_xp(25)
	if story() == 3:
		pr["flags"]["grad_broken"] = int(pr["flags"].get("grad_broken", 0)) + 1
		Hud.objective_progress("Devrilen kukla: %d/3" % pr["flags"]["grad_broken"])
	Missions.on_dummy_broken()
	Exams.on_dummy_broken(_d)


func on_technique_used(id: String) -> void:
	Exams.on_technique(id)
	ChuninExam.on_technique(id)
	if story() == 2 and id == "henge":
		p()["flags"]["henge_used"] = true
		Hud.objective_progress("Henge kullanıldı! Hocana dön.")


func on_player_died() -> void:
	Journal.on_player_defeated()   # seni yenen kişi rakibin olur; bir gün geri döner
	var rogue = Orgs.is_rogue()
	Hud.banner("YENİLDİN", "Sığınağında, ateşin başında uyanıyorsun..." if rogue else "Hastanede uyanıyorsun...", Color(0.9, 0.3, 0.3))
	var pr = p()
	pr["ryo"] = int(int(pr["ryo"]) * 0.9)
	get_tree().create_timer(2.5).timeout.connect(func():
		# kaçak köy hastanesinde doğamaz: sığınağında uyanır
		var pos = Missions.open_ground(Orgs.hideout_pos() + Vector3(0, 0, 6), 20.0) if Orgs.is_rogue() else _hospital_pos()
		Game.player.respawn(pos))


func _process(_dt: float) -> void:
	if Game.player == null or Game.profile.is_empty():
		return
	Journal.tick(_dt)
	_check_rinnegan_path(_dt)
	# ziyaret edilen köyler (hızlı seyahat); büyük beş köy baştan açık (eski kayıtlar dahil)
	for big in ["konoha", "suna", "kiri", "kumo", "iwa"]:
		if not big in p()["visited"]:
			p()["visited"].append(big)
	var m = Game.to_map(Game.player.global_position)
	for v in Game.world_info["villages"]:
		if not v["id"] in p()["visited"] and m.distance_to(Vector2(v["x"], v["y"])) < float(v["r"]):
			p()["visited"].append(v["id"])
			Hud.banner(v["name"], "Keşfedildi — haritadan hızlı seyahat açıldı", Color(0.8, 0.95, 1.0))
			Journal.add("%s'ye ilk kez ayak bastın." % v["name"], "travel")
			add_xp(60)


## Evdeki notta oyuncunun kendi seçtiği hedefler (kanon karakterin hayali değil)
func _note_line() -> String:
	var gs = Journal.goals()
	if gs.is_empty():
		return "Yolumu kendim çizeceğim."
	return "Hedeflerim: " + ", ".join(gs.map(func(g): return String(Journal.GOALS[g]["name"])))


func _check_story_levels() -> void:
	var lv = int(p()["level"])
	var rk = int(p()["rank"])
	if story() >= Journal.FREE and rk == 1 and lv == 15:
		Hud.msg("Chūnin Sınavı'na başvurabilirsin (Stadyum ya da %s Kulesi) — istersen." % home_info()["kage"], Color(1, 0.8, 0.4))
	if rk == 2 and lv >= 45 and int(p()["missions_done"].get("A", 0)) >= 3:
		Hud.msg("Jōnin terfi değerlendirmesine başvurabilirsin (%s Kulesi)." % home_info()["kage"], Color(1, 0.8, 0.4))


# ------------------------------------------------------------------ etkileşimler [F]
func interact(it: Dictionary) -> void:
	var kind: String = it["kind"]
	var pr = p()
	match kind:
		"beast_seal", "beast_talk", "mind_exit":
			TailedBeasts.interact(it)
		"academy":
			_academy()
		"mission_board":
			_mission_board(it)
		"ramen":
			_sit_at(it.get("seats", []))
			_eat(50, "Sıcak bir kase miso chashu ramen... Can ve chakra doldu!", "Ramen Ustası")
		"enter":
			if Interiors.inst:
				Interiors.inst.enter(it)
		"exit":
			if Interiors.inst:
				Interiors.inst.exit()
		"bed":
			_sleep(0, "Futonuna uzanıp gözlerini kapattın... Sabah oldu. (Oyun kaydedildi)")
		"inn_sleep", "inn":
			Hud.dialog(it.get("title", "Han Sahibi"), "Hoş geldin yolcu! Sıcak yemek de var, yumuşak futon da.", [
				{"label": "Akşam yemeği ye (30 Ryō) — can + chakra", "cb": func(): _eat(30, "Pirinç, miso çorbası ve ızgara balık... Karnın doydu!", "Han Sahibi")},
				{"label": "Oda tut ve uyu (40 Ryō) — sabaha kadar, kaydet", "cb": func(): _sleep(40, "Han odasında rahat bir gece geçirdin. Sabah oldu! (Oyun kaydedildi)")},
			])
		"shrine":
			Buffs.add("shrine", 300.0, {"armor": 0.9, "melee": 1.05})
			Game.player.chakra = Game.player.max_chakra
			Game.save_game()
			Hud.dialog("Tapınak", "Ellerini birleştirip dua ettin. İçin huzurla doldu: 5 dakika boyunca alınan hasar -%10, güç +%5. Chakran yenilendi. (Oyun kaydedildi)", [respec_option()])
		"trainer":
			var vid: String = it.get("village", home())
			var topts = trainer_options(it["kinds"]) if it.has("kinds") else village_trainer_options(vid)
			topts.append_array(KgPaths.trainer_options())  # Doğa Dönüşümü (birleşik doğa)
			var ttxt = "Hangi tekniği öğrenmek istersin? Ryō karşılığında öğretirim." if not topts.is_empty() else "Şu an sana öğretebileceğim yeni bir teknik yok. Biraz daha güçlen, sonra gel."
			Hud.dialog(it.get("title", "Eğitmen"), ttxt, topts)
		"tailor":
			Hud.gear_shop("Terzi", Gear.shop_stock("c", String(it.get("village", home()))))
		"kg_site":
			KgPaths.interact_site(it)
		"path_mentor":
			LegendPaths.interact(it)
		"home_note":
			var lv = int(pr["level"])
			Hud.dialog("Notlar", "Kendi el yazınla: \"%s\"\nSeviye %d • %s • %d Ryō\nGörevler: D%d C%d B%d A%d S%d" % [_note_line(), lv, Data.RANKS[int(pr["rank"])], int(pr["ryo"]),
				pr["missions_done"]["D"], pr["missions_done"]["C"], pr["missions_done"]["B"], pr["missions_done"]["A"], pr["missions_done"]["S"]], [])
		"bbq":
			_eat(80, "Yakiniku! Can ve chakra doldu, 60sn boyunca +%20 güç.", "Garson")
			Buffs.add("bbq", 60.0, {"melee": 1.2})
		"hospital":
			Game.player.hp = Game.player.max_hp
			var opts = []
			if int(pr["level"]) >= 4 and not "shousen" in pr["learned"]:
				opts.append({"label": "Tıbbi ninjutsu öğren (200 Ryō)", "cb": func(): _buy_learn("shousen", 200)})
			opts.append_array(trainer_options(["hospital"], 5))
			# göz nakli: kavanozdaki gözler
			for g in pr.get("gear", []):
				if Gear.item(g["id"]).get("slot", "") == "goz" and not int(g["uid"]) in pr["equip"].values():
					for sl in [["sag_goz", "sağ"], ["sol_goz", "sol"]]:
						var uid = int(g["uid"])
						var slot = sl[0]
						opts.append({"label": "Göz nakli: %s → %s göz (500 Ryō)" % [Gear.item(g["id"])["name"], sl[1]], "cb": func():
							if int(pr["ryo"]) < 500:
								Hud.msg("Yeterli Ryō yok.", Color(1, 0.5, 0.4))
								return
							add_ryo(-500)
							Eyes.transplant(pr, uid, slot)
							Hud.msg("Nakil başarılı. Bir süre gözlerin ağrıyacak.", Color(0.7, 1, 0.7))})
			Hud.dialog("Hastane", "Yaraların sarıldı. Tamamen iyileştin.", opts)
		"training":
			_training_ground()
		"swing":
			Game.player.sit(it["pos"])
		"lookout":
			Game.save_game()
			Hud.dialog(home_info()["lookout"], "Köy ayaklarının altında. Köyünü koruma iraden güçleniyor... (Oyun kaydedildi)", [])
		"rogue_broker":
			Orgs.broker_dialog()
		"memorial":
			Hud.dialog("Anıt Taşı", "Köy için canını veren shinobilerin isimleri burada yazılı. Bir an saygıyla eğiliyorsun.", [])
		"gate":
			var gopts = []
			if Orgs.is_rogue():
				Orgs.pardon_prompt()
			else:
				if _in_home(it) and int(pr["rank"]) >= 1 and int(pr["rank"]) < 6:
					gopts.append({"label": "Köyü terk et (kaçak ninja ol)", "cb": Orgs.defect_prompt})
				Hud.dialog("Kapı Nöbetçisi", "Dışarısı tehlikeli genç ninja. Haritayı [M] aç, yolları takip et. Diğer köylere varınca hızlı seyahat açılır.", gopts)
		"shop_weapons":
			Hud.dialog("Silah Dükkânı", "Hoş geldin! Ne bakıyorsun?", [
				{"label": "Ninja aletleri", "cb": func(): Hud.shop("Silah Dükkânı", ["kunai", "shuriken", "senbon", "tag", "makibishi", "smoke"])},
				{"label": "Silahlar (sağ el / sol el) — stok yarım saatte bir değişir", "cb": func(): Hud.gear_shop("Silahçı", Gear.shop_stock("w", String(it.get("village", home()))))},
				{"label": "Kıyafetler ve zırhlar", "cb": func(): Hud.gear_shop("Terzi", Gear.shop_stock("c", String(it.get("village", home()))))},
			])
		"shop_weapons_old":
			Hud.shop("Silah Dükkânı", ["kunai", "shuriken", "tag", "smoke", "scroll_katon_housenka", "scroll_suiton_suijinheki", "scroll_fuuton_daitoppa", "scroll_doton_doryuheki"])
		"shop_items":
			Hud.shop("Eczane", ["salve", "pill", "smoke"])
		"shop_scrolls":
			var sc = scroll_shop_items(14)
			if sc.is_empty():
				Hud.dialog("Parşömenci", "Şu an doğana uygun yeni bir element parşömenim yok. Seviyen yükseldikçe ya da yeni bir doğa uyandırdıkça tekrar gel.", [])
			else:
				Hud.shop("Parşömenci — Element Jutsuları", sc)
		"chunin_exam":
			ChuninExam.apply()
		"fod_tower":
			ChuninExam.enter_tower()
		"quest", "bounty_board":
			pass  # Missions.on_interact ele alır
		"teahouse":
			_eat(20, "Sıcak yeşil çay ve dango... Dinlendin, can ve chakra doldu.", "Çay Evi Sahibi")
		"onsen":
			Game.player.hp = Game.player.max_hp
			Game.player.chakra = Game.player.max_chakra
			Hud.dialog("Kaplıca", "Sıcak su tüm yorgunluğunu aldı. Tamamen iyileştin.", [])
		"sage":
			_sage_falls()
		"contract_realm":
			Contracts.realm_interact(it)
		"contract_keeper":
			Contracts.keeper_interact(it)
		"valley":
			Hud.dialog("Sonun Vadisi", "İki dev heykelin arasında nehir köpürüyor. Burada bir zamanlar büyük bir savaş olmuş... (Sv.35'te gizli bir uyanış seni bekliyor)", [])
		"anbu":
			Exams.anbu_offer()
		_:
			Hud.dialog(it.get("label", "").replace("[F] ", ""), "Burada şimdilik yapacak bir şey yok.", [])
	Missions.on_interact(it)


func _in_home(it: Dictionary) -> bool:
	var v = Game.village(home())
	return Game.to_map(it["pos"]).distance_to(Vector2(v["x"], v["y"])) < float(v["r"]) * 1.6


func _hospital_pos() -> Vector3:
	var v = Game.village(home())
	var c = Vector2(v["x"], v["y"])
	var best = {}
	var bd = float(v["r"]) * 1.6
	for it in Interact.items:
		if it["kind"] == "hospital":
			var d = Game.to_map(it["pos"]).distance_to(c)
			if d < bd:
				bd = d; best = it
	if not best.is_empty():
		return best["pos"] + Vector3(0, 0.5, 4)
	if home() == "konoha":
		return Game.from_map(Vector2(v["x"] + 140, v["y"] + 60))
	return home_spawn()


## Tezgâhtaki en yakın tabureye oturt (ramen)
func _sit_at(seats: Array) -> void:
	var pl = Game.player
	if seats.is_empty() or pl == null:
		return
	var best: Vector3 = seats[0]
	for q in seats:
		if q.distance_to(pl.global_position) < best.distance_to(pl.global_position):
			best = q
	pl.global_position = best
	pl.velocity = Vector3.ZERO
	pl.reset_physics_interpolation()
	pl.facing = 0.0
	pl.model.rotation.y = 0.0
	pl.model.play("sit", 0.2)
	pl.input_locked = 3.5


## Uyu: sabaha atla, iyileş, kaydet (ekran kararır)
func _sleep(price: int, text: String) -> void:
	if price > 0 and int(p()["ryo"]) < price:
		Hud.dialog("Han Sahibi", "Bir gece %d Ryō, kusura bakma." % price, [])
		return
	if price > 0:
		add_ryo(-price)
	var pl = Game.player
	if Interiors.inst:
		await Interiors.inst._fade(1.0, 0.6)
	if Game.world:
		Game.world.env.time_of_day = 0.27
	pl.hp = pl.max_hp
	pl.chakra = pl.max_chakra
	Game.save_game()
	if Interiors.inst:
		await get_tree().create_timer(0.6).timeout
		await Interiors.inst._fade(0.0, 0.8)
	Hud.dialog("Uyku", text, [])


func _eat(price: int, text: String, who: String) -> void:
	if int(p()["ryo"]) < price:
		Hud.dialog(who, "Kusura bakma, %d Ryō lazım." % price, [])
		return
	add_ryo(-price)
	Game.player.hp = Game.player.max_hp
	Game.player.chakra = Game.player.max_chakra
	Game.player.model.play("eat", 0.1, 1.0, true)
	Hud.dialog(who, text, [])


func _buy_learn(jid: String, price: int) -> void:
	if int(p()["ryo"]) < price:
		Hud.msg("Yeterli Ryō yok.", Color(1, 0.5, 0.4))
		return
	add_ryo(-price)
	learn(jid)


func _academy() -> void:
	var s = story()
	var pr = p()
	var sensei = home_info()["s1"]
	var vn = String(Game.village(home()).get("name", "Konoha"))
	match s:
		0:
			Hud.dialog(sensei, "Hoş geldin %s! Bir ninja olmak için önce temeli sağlam atmalısın. Avludaki kuklalara 25 darbe vur [Sol tık], kombolarını çalış. Kawarimi [Q] ile kaçmayı da unutma!" % pr["name"], [])
			set_story(1)
		1:
			if int(pr["flags"].get("dummy_hits", 0)) >= 25:
				Hud.dialog(sensei, "Güzel taijutsu! Şimdi sana Akademi'nin üç temel tekniğinden birini öğreteceğim: Henge. Mühürler: Köpek - Domuz - Koç.", [])
				learn("henge")
				set_story(2)
			else:
				Hud.dialog(sensei, "Daha %d darbe kaldı. Tembellik yok!" % (25 - int(pr["flags"].get("dummy_hits", 0))), [])
		2:
			if pr["flags"].get("henge_used", false):
				Hud.dialog(sensei, "Mükemmel dönüşüm! Mezuniyet sınavına hazırsın: yazılı sınav, üç akademi tekniği ve hedef parkuru. Hazır olduğunda benimle konuş.", [])
				pr["flags"]["grad_broken"] = 0
				set_story(3)
			else:
				Hud.dialog(sensei, "Henge'yi [1] tuşuyla kullan ve bana göster.", [])
		3:
			Exams.academy_talk()
		_:
			var opts = []
			if int(pr["level"]) >= 3 and not "shunshin" in pr["learned"]:
				opts.append({"label": "Shunshin öğren (150 Ryō)", "cb": func(): _buy_learn("shunshin", 150)})
			if int(pr["level"]) >= 5 and not "narakumi" in pr["learned"]:
				opts.append({"label": "Genjutsu dersi: Narakumi (250 Ryō)", "cb": func():
					if not "genjutsu" in pr["skills"]:
						pr["skills"].append("genjutsu")
					_buy_learn("narakumi", 250)})
			Hud.dialog(sensei, "Seninle gurur duyuyorum %s. Yolun açık olsun — hangi yolu seçersen seç, temeli unutma." % pr["name"], opts)


## Yetenek ağacını sıfırlama (tapınak / antrenman alanı): puanlar geri verilir
func respec_option() -> Dictionary:
	var cost = int(Data.skills.get("respec_cost", 500)) * maxi(1, int(p()["level"]) / 10)
	return {"label": "Yeteneklerini sıfırla (%d Ryō)" % cost, "cb": func():
		var pr = p()
		if int(pr["ryo"]) < cost:
			Hud.msg("Yeterli Ryō yok.", Color(1, 0.5, 0.4))
			return
		add_ryo(-cost)
		var back = Stats.respec(pr)
		if Game.player:
			Game.player.apply_profile_stats()
		Hud.msg("Yetenekler sıfırlandı: %d puan geri döndü." % back, Color(0.7, 1, 0.7))}


func _training_ground() -> void:
	var pr = p()
	var s = story()
	if s == 3 and pr["flags"].get("academy_passed", false):
		Hud.dialog(home_info()["s2"], "Demek mezun oldun. Ama gerçek ninjalar bu testten sonra belli olur: Zil Testi. Hazır mısın?", [{"label": "Zil Testine başla", "cb": Exams.bell_start}, {"label": "Biraz sonra", "cb": func(): pass}])
		return
	# chakra kâğıdı testi: mezun olmuş ama doğasını bilmeyen herkes isteğe bağlı yapabilir
	if s >= Journal.FREE and not pr.get("element_known", false):
		var el: String = pr["elements"][0]
		var names = {"katon": "kâğıt yanıp kül oldu: ATEŞ (Katon)", "suiton": "kâğıt ıslandı: SU (Suiton)", "fuuton": "kâğıt ikiye bölündü: RÜZGAR (Fuuton)",
			"doton": "kâğıt ufalandı: TOPRAK (Doton)", "raiton": "kâğıt buruştu: YILDIRIM (Raiton)"}
		pr["element_known"] = true
		Hud.dialog(home_info()["s2"], "Chakra kâğıdına chakranı akıt... %s! İlk element tekniğini öğretiyorum." % names[el], [])
		var starter = {"katon": "katon_goukakyuu", "suiton": "suiton_suikoudan", "fuuton": "fuuton_shinkuu", "doton": "doton_doryuusou", "raiton": "raiton_nagashi"}[el]
		learn(starter)
		Journal.add("Chakra kâğıdı doğanı gösterdi: %s." % el.capitalize(), "milestone")
		return
	var opts = [respec_option()]
	if int(pr["rank"]) >= 2 and int(pr["level"]) >= 25 and "raiton" in pr["elements"] and not "raiton_chidori" in pr["learned"]:
		opts.append({"label": "Chidori eğitimi (800 Ryō)", "cb": func(): _buy_learn("raiton_chidori", 800)})
	if int(pr["rank"]) >= 2 and int(pr["level"]) >= 30 and "katon" in pr["elements"] and not "katon_karyuu" in pr["learned"]:
		opts.append({"label": "Karyuu Endan eğitimi (1200 Ryō)", "cb": func(): _buy_learn("katon_karyuu", 1200)})
	opts.append_array(village_trainer_options(home()))
	Hud.dialog("Antrenman Alanı 3", "Kuklalarla kombolarını çalışabilirsin. Chakra şarjı [C], blok [Sağ tık], Kawarimi [Q].", opts)


func _sage_falls() -> void:
	var pr = p()
	var opts = []
	if int(pr["rank"]) >= 2 and int(pr["level"]) >= 25 and not "rasengan" in pr["learned"]:
		opts.append({"label": "Rasengan eğitimi (3 aşama)", "cb": func(): RasenganTraining.start()})
	if int(pr["rank"]) >= 2 and int(pr["level"]) >= 22 and not "kuchiyose" in pr["learned"]:
		opts.append({"label": "Kurbağa sözleşmesini imzala", "cb": func(): Contracts.sign("kurbağa")})
	if int(pr["rank"]) >= 2 and int(pr["level"]) >= 40 and not "sage" in pr["skills"]:
		opts.append({"label": "Sennin eğitimi (doğa enerjisi meditasyonu)", "cb": func():
			if Game.player and Game.player.combat and Game.player.combat.modes:
				Game.player.combat.modes.start_sage_training("kurbağa")})
	Hud.dialog("Yaşlı Kurbağa Bilge", "Doğanın enerjisini dinle genç... Sabırlı olanlar burada güç bulur." if opts.is_empty() else "Hazırsın. Ne öğrenmek istersin?", opts)


func _mission_board(it: Dictionary) -> void:
	var pr = p()
	var s = story()
	if Orgs.is_rogue() and _in_home(it):
		Hud.dialog(home_info()["kage"] + " Kulesi", "Kaçak bir ninjaya bu köyde görev yok. Muhafızlar seni izliyor...", [])
		return
	if _in_home(it):
		var rk = int(pr["rank"])
		if rk >= 6:
			Hud.dialog(home_info()["kage"] + " Kulesi", "Masan seni bekliyor, %s." % home_info()["kage"], [
				{"label": "Kage masasına otur", "cb": func(): KageDesk.open()},
				{"label": "Görev panosuna bak", "cb": func(): Missions.open_board(it)}])
			return
		var opts = []
		if rk == 2 and int(pr["level"]) >= 45:
			opts.append({"label": "Jōnin terfi değerlendirmesi", "cb": func(): Exams.jonin_offer()})
		if rk >= 2 and int(pr["level"]) >= 35 and String(pr.get("specialty", "")) == "":
			opts.append({"label": "Tokubetsu Jōnin uzmanlığı seç", "cb": func(): Exams.specialty_offer()})
		if rk in [3, 4] and int(pr["level"]) >= 90:
			opts.append({"label": "%s adaylığı" % home_info()["kage"], "cb": func(): Kage.offer_candidacy()})
		if s >= Journal.FREE and int(pr["level"]) >= 15 and rk == 1:
			opts.append({"label": "Chūnin Sınavına başvur", "cb": func(): ChuninExam.apply()})
		if not opts.is_empty():
			opts.push_front({"label": "Görevleri göster" if it.has("giver") else "Görev panosu", "cb": func(): Missions.open_board(it)})
			if it.has("giver"):
				Hud.dialog(it["giver"], _kage_greet(it, true), opts)
			else:
				Hud.dialog(home_info()["kage"] + " Kulesi", "Ne için geldin?", opts)
			return
	# Kage ofisinde görevleri Kage'nin kendisi verir
	if it.has("giver"):
		Hud.dialog(it["giver"], _kage_greet(it, _in_home(it)), [
			{"label": "Görevleri göster", "cb": func(): Missions.open_board(it)},
			{"label": "Şimdilik bir şey yok", "cb": func(): pass}])
		return
	Missions.open_board(it)


## Kage'nin karşılaması: rütbeye ve köy aidiyetine göre
func _kage_greet(it: Dictionary, home_v: bool) -> String:
	var nm = String(p().get("name", "ninja"))
	if not home_v and int(p().get("rank", 0)) >= 6:
		return "Bir Kage'yi ofisimde ağırlamak onurdur, %s-dono. Köylerimiz arasındaki işler için masam her zaman açık." % nm
	if not home_v:
		var vn = String(Game.village(String(it.get("vid", ""))).get("name", "köyümüz"))
		return "%s'ye hoş geldin, yabancı ninja. Köyümüzün itibarını kazanmak istiyorsan, sana uygun işler var. Ama unutma: burada misafirsin." % vn
	var rk = int(p().get("rank", 0))
	var lines = []
	match rk:
		0, 1:
			lines = ["Ah, %s! Genç bir genin için her görev bir derstir — kayıp kedi bile." % nm,
				"Hevesini görüyorum %s. D-rank işler sıkıcı gelebilir ama köy onlarla ayakta durur." % nm,
				"Takımınla uyumun nasıl? Görevler sizi birbirinize bağlayacak, %s." % nm]
		2:
			lines = ["Chūnin %s. Artık sadece emir uygulamıyorsun; takımını da düşünmek zorundasın." % nm,
				"Sınırlarda hareketlilik var %s. Sana güvenebileceğim işler hazırladım." % nm]
		3, 4:
			lines = ["%s, köyün en güvendiğim ninjalarındansın. Zor bir dönemden geçiyoruz." % nm,
				"Masamdaki raporların yarısı senin adını taşıyor %s. Sıradaki görev daha da ağır." % nm]
		_:
			lines = ["%s, hoş geldin. Köyün geleceği senin gibilerin omzunda." % nm]
	return lines.pick_random()
