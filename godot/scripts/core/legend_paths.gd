class_name LegendPaths
extends Node
## Efsane Yolları: kanon ninjaların imza teknikleri, dünyada saklı özgün ustalardan öğrenilir (kanon karakter yok).
## Hikâyeye bağlı değil, isteğe bağlı keşif içeriği:
##   söylenti (seviye gelince) → inini bul (yaklaşınca) → ustanın sınav görevi → yola katıl (pasif bonus + ilk teknik)
##   → teknikleri seviyeye göre ustadan öğren (Ryō; bazıları ayrı görev, karanlık olanlar köy itibarı düşürür).
## Teknik verisi: tools/build_data.py NEW_PATH / PATH_TAG ("path:<id>"), uygulamalar: PathJutsu.
## Profil: profile["paths"][id] = {"s": durum, "q": ""}  durum: 0 bilinmiyor, 1 söylenti, 2 in bulundu, 3 sınavda, 4 yolda

enum {UNKNOWN, RUMOR, FOUND, TRIAL, JOINED}

const PATHS := {
	"yilan": {
		"name": "Yılan Yolu", "icon": "seal", "color": Color(0.7, 0.5, 0.9),
		"style": "Yılan elleri, Kusanagi, lanetli mühür ve yasak diriltme sanatları",
		"site": {"country": "sound", "off": Vector2(-1900, 1300), "kind": "snake", "clear": 52.0, "place": "Ryūchi İni (Ses Ülkesi dağları)"},
		"mentor": {"name": "Yamikage Jaen", "title": "Yılan Ustası",
			"look": {"gender": "m", "skin": Color(0.94, 0.91, 0.9), "hair": Color(0.07, 0.07, 0.1), "hair_style": "uzun", "eye": Color(0.9, 0.78, 0.15),
				"top": Color(0.88, 0.85, 0.78), "top2": Color(0.6, 0.5, 0.75), "pants": Color(0.28, 0.2, 0.38), "band": null, "vest": null, "age": "adult"}},
		"rumor_level": 8, "join_level": 10,
		"rumor": "Gezginler, Ses Ülkesi'nin sisli dağlarında yılanların bekçilik ettiği bir mağaradan söz ediyor. İçeride ölümsüzlüğü arayan solgun bir usta yaşarmış...",
		"intro": "Solgun usta sarı gözlerini sana dikiyor: \"Merak... ne güzel bir koku. Yılanlar yalnızca bedelini ödemeye hazır olanlara sırlarını açar. Sınavımı geçersen sana deri değiştirmeyi öğretirim.\"",
		"passive": {"poison_resist": 0.3, "speed": 0.04},
		"passive_desc": "Zehir direnci +%30, hız +%4",
		"order": ["sen_ei_jashu", "jagei_jubaku", "hebi_bunshin_no_jutsu", "sen_ei_tajashu", "kuchiyose_rashomon", "kusanagi_kuchi", "gogyo_fuin",
			"sen_ei_ranjashu", "ten_no_juin", "mandara_no_jin", "orochimaru_ryu_no_kawarimi_no_jutsu", "hakuja_sennin_modo", "juin_ni_no_dankai",
			"kuchiyose_sanju_rashomon", "yamata_no_jutsu", "kuchiyose_edo_tensei", "sojasosai_no_jutsu"],
		"quest": {"kusanagi_kuchi": "sword", "ten_no_juin": "curse"},
		"dark": {"ten_no_juin": 15, "juin_ni_no_dankai": 20, "kuchiyose_edo_tensei": 40, "sojasosai_no_jutsu": 30},
	},
	"silah": {
		"name": "Silah Ustası Yolu", "icon": "sword", "color": Color(0.95, 0.6, 0.35),
		"style": "Parşömenden silah çağırma, telli silah fırtınaları ve efsanevi araçlar",
		"site": {"country": "fire", "off": Vector2(-2840, 1300), "kind": "forge", "clear": 62.0, "place": "Tetsuyama Demirhanesi (Ateş Ülkesi tepeleri)"},
		"mentor": {"name": "Tetsuno Kanae", "title": "Silah Ustası Demirci",
			"look": {"gender": "f", "skin": Color(0.93, 0.78, 0.64), "hair": Color(0.28, 0.16, 0.1), "hair_style": "atkuyruğu", "eye": Color(0.35, 0.22, 0.12),
				"top": Color(0.82, 0.28, 0.22), "top2": Color(0.6, 0.18, 0.14), "pants": Color(0.18, 0.17, 0.2), "vest": Color(0.42, 0.28, 0.16),
				"band": Color(0.2, 0.2, 0.25), "age": "adult"}},
		"rumor_level": 5, "join_level": 6,
		"rumor": "Konoha'nın batısındaki tepelerde, örsünden kıvılcım eksik olmayan bir demirhane varmış. Ustası, parşömeninden yüz silahı aynı anda yağdırabiliyormuş.",
		"intro": "Demirci çekicini bırakıp alnını siliyor: \"Silah, onu tutanın iradesi kadar keskindir. Önce ellerinin işe yarar olduğunu göster, sonra parşömenlerimi açarım.\"",
		"passive": {"throw_dmg": 0.3, "w_all": 0.12},
		"passive_desc": "Atış hasarı +%30, tüm silahlar +%12",
		"order": ["buki_kuchiyose", "tesso_kusari", "soshoryu", "tekkosen", "ito_buki_arashi", "kuchiyose_tetsuzan",
			"bashosen_kaze_no_maki", "bashosen_hi_no_maki", "bashosen_rai_no_maki", "bashosen_mizu_no_maki"],
		"quest": {"soshoryu": "dragons", "bashosen_kaze_no_maki": "fan"},
		"dark": {},
	},
	"tip": {
		"name": "Şifacı Yolu (Tıbbi Ninja)", "icon": "potion", "color": Color(0.45, 0.9, 0.6),
		"style": "Mistik Avuç ile iyileştirme, chakra neşteri, zehir ve panzehir, yaşlanmayı durduran mühür",
		"site": {"country": "hotwater", "off": Vector2(900, -700), "kind": "clinic", "clear": 50.0, "place": "Yuge Şifa Tapınağı (Sıcak Su Ülkesi)"},
		"mentor": {"name": "Hōseki Rindō", "title": "Şifacı Usta",
			"look": {"gender": "f", "skin": Color(0.96, 0.84, 0.72), "hair": Color(0.85, 0.75, 0.45), "hair_style": "atkuyruğu", "eye": Color(0.55, 0.4, 0.2),
				"top": Color(0.92, 0.92, 0.9), "top2": Color(0.45, 0.75, 0.55), "pants": Color(0.3, 0.32, 0.36), "band": Color(0.2, 0.2, 0.25), "age": "adult"}},
		"rumor_level": 4, "join_level": 6,
		"rumor": "Sıcak Su Ülkesi'nde, buharı şifa veren bir tapınakta yaralı askerleri ölümden döndüren bir şifacı varmış. Öğrenci arıyormuş.",
		"intro": "Şifacı ellerini yeşil chakrayla ısıtıyor: \"Yıkmak kolay, onarmak zor. Chakra kontrolün yeterince ince mi? Önce yaralılara yetiş, sonra konuşuruz.\"",
		"passive": {"heal_power": 0.3, "chakra_regen": 0.15},
		"passive_desc": "İyileştirme gücü +%30, chakra yenilenmesi +%15",
		"order": ["shousen", "senpuku", "shikon_no_jutsu", "saikan_chushutsu_no_jutsu", "dokugiri", "ranshinsho", "chakura_no_mesu", "in_yu_shometsu", "sozo_saisei"],
		"quest": {"sozo_saisei": "seal"},
		"dark": {},
	},
	"kapi": {
		"name": "Sekiz Kapı Yolu", "icon": "hand", "color": Color(0.35, 0.85, 0.35),
		"style": "Bedenin sekiz chakra kapısını zorla açmak: Lotus, Sabah Tavuskuşu, Gündüz Kaplanı, Akşam Fili",
		"site": {"country": "fire", "off": Vector2(1500, 900), "kind": "dojo", "clear": 50.0, "place": "Seishun Dojosu (Ateş Ülkesi dağları)"},
		"mentor": {"name": "Kōtetsu Gōriki", "title": "Taijutsu Ustası",
			"look": {"gender": "m", "skin": Color(0.93, 0.78, 0.62), "hair": Color(0.08, 0.08, 0.1), "hair_style": "kase", "eye": Color(0.1, 0.1, 0.1),
				"top": Color(0.2, 0.5, 0.25), "top2": Color(0.2, 0.5, 0.25), "pants": Color(0.2, 0.5, 0.25), "vest": Color(0.38, 0.48, 0.28), "band": Color(0.75, 0.15, 0.15), "age": "adult"}},
		"rumor_level": 8, "join_level": 10,
		"rumor": "Ateş Ülkesi dağlarında, şafakta binlerce şınav çeken yeşil tulumlu bir ustanın dojosu varmış. Azmi olan her genci kabul ediyormuş.",
		"intro": "Usta tek elle amuda kalkmış: \"Gençliğin ateşi! Ninjutsu yoksa ne olmuş? Bedenin sekiz kapısı var ve onları açacak kadar azimliysen dünyayı yerinden oynatırsın!\"",
		"passive": {"gates": 0.3, "melee": 0.1},
		"passive_desc": "Kapı ustalığı +%30 (daha güçlü, daha az bedel), yakın dövüş +%10",
		"order": ["omote_renge", "ura_renge", "hachimon_tonko_no_jin", "asakujaku", "hirudora", "sekizo", "yagai"],
		"quest": {"hachimon_tonko_no_jin": "gates", "yagai": "gates"},
		"dark": {},
	},
}
## Sıradaki yollar (ROADMAP): kurbağa sennin, kil sanatı, kukla ustası, Hiraishin, köpekbalığı...

static var lairs := {}   # yol id -> [x, y] harita noktası (ustanın önü)
static var _node: LegendPaths = null
var _t := 0.0


# ------------------------------------------------------------------ durum
static func pr() -> Dictionary:
	return Game.profile


static func st_of(pid: String) -> Dictionary:
	var p = pr()
	if p.is_empty():
		return {"s": UNKNOWN}
	if not p.has("paths"):
		p["paths"] = {}
	if not p["paths"].has(pid):
		p["paths"][pid] = {"s": UNKNOWN}
	return p["paths"][pid]


static func state(pid: String) -> int:
	return int(st_of(pid).get("s", UNKNOWN))


static func set_state(pid: String, s: int) -> void:
	var d = st_of(pid)
	if int(d.get("s", 0)) < s:
		d["s"] = s


static func joined(pid: String) -> bool:
	return state(pid) >= JOINED


## Stats.skill eklentisi: katıldığın yolların pasif bonusları
static func passive(p: Dictionary, key: String) -> float:
	var v = 0.0
	var ps = p.get("paths", {})
	if not ps is Dictionary:
		return 0.0
	for pid in ps:
		if int(ps[pid].get("s", 0)) >= JOINED and PATHS.has(pid):
			v += float(PATHS[pid]["passive"].get(key, 0.0))
	return v


static func price(jid: String) -> int:
	return 100 + int(Data.jutsu.get(jid, {}).get("level", 1)) * 55


## Sıradaki adımın kısa metni (sekme ve diyalog)
static func next_step(pid: String) -> String:
	var P: Dictionary = PATHS[pid]
	match state(pid):
		UNKNOWN:
			return "Henüz bir söylenti duymadın (Sv.%d civarı)." % int(P["rumor_level"])
		RUMOR:
			return "Söylentinin peşine düş: %s. (İzi takip et)" % P["site"]["place"]
		FOUND:
			if int(pr().get("level", 1)) < int(P["join_level"]):
				return "Ustan seni Seviye %d olunca kabul edecek." % int(P["join_level"])
			return "%s ile konuş ve sınavını kabul et." % P["mentor"]["name"]
		TRIAL:
			return "Ustanın sınavını tamamla."
	for jid in P["order"]:
		if not jid in pr().get("learned", []):
			var lv = int(Data.jutsu.get(jid, {}).get("level", 1))
			var nm = String(Data.jutsu.get(jid, {}).get("name", jid)).split(" (")[0]
			if int(pr().get("level", 1)) < lv:
				return "Sıradaki teknik: %s (Seviye %d)." % [nm, lv]
			return "Ustana dön: %s öğrenmeye hazırsın." % nm
	return "Bu yolun bütün tekniklerini öğrendin. Usta artık seninle gurur duyuyor."


# ------------------------------------------------------------------ düğüm (keşif denetimi + görev kancası /root/LegendPaths)
static func node() -> LegendPaths:
	if _node == null or not is_instance_valid(_node):
		_node = LegendPaths.new()
		_node.name = "LegendPaths"
		var root = (Engine.get_main_loop() as SceneTree).root
		var old = root.get_node_or_null("LegendPaths")
		if old:
			old.queue_free()
			old.name = "LegendPaths_old"
		root.add_child.call_deferred(_node)
	return _node


func _process(dt: float) -> void:
	_t -= dt
	if _t > 0.0 or Game.profile.is_empty() or Game.player == null or Game.paused:
		return
	_t = 2.0
	var lv = int(pr().get("level", 1))
	for pid in PATHS:
		var P: Dictionary = PATHS[pid]
		var s = state(pid)
		if s == UNKNOWN and lv >= int(P["rumor_level"]):
			set_state(pid, RUMOR)
			Hud.banner("SÖYLENTİ: " + P["name"].to_upper(), P["site"]["place"], P["color"])
			Hud.msg(P["rumor"] + "  [Tab > Yollar]", P["color"].lightened(0.3), 8.0)
		if s < FOUND and lairs.has(pid):
			var lp = Game.from_map(Vector2(lairs[pid][0], lairs[pid][1]))
			if Vector2(lp.x - Game.player.global_position.x, lp.z - Game.player.global_position.z).length() < 70.0:
				set_state(pid, FOUND)
				Hud.banner("GİZLİ YER BULUNDU", P["site"]["place"], P["color"])
				Hud.msg("%s burada yaşıyor. Onunla konuş [F]." % P["mentor"]["title"], P["color"].lightened(0.3), 5.0)
				if Game.profile.get("waypoint") is Array and String(Game.profile["waypoint"][3]) == P["site"]["place"]:
					Game.profile.erase("waypoint")


## Görev kancası: Missions "LegendPaths.quest_done"
func quest_done(m: Dictionary, ok: bool) -> void:
	var pid: String = m.get("path", "")
	if pid == "" or not PATHS.has(pid):
		return
	var d = st_of(pid)
	d["q"] = ""
	if not ok:
		if int(d.get("s", 0)) == TRIAL:
			d["s"] = FOUND
		Hud.msg("Usta başarısızlığını sessizce izledi. Hazır olunca yeniden dene.", Color(0.9, 0.7, 0.6))
		return
	var P: Dictionary = PATHS[pid]
	if m.get("trial", false):
		d["s"] = JOINED
		Hud.banner("YOLA KATILDIN", "%s — %s" % [P["name"], P["passive_desc"]], P["color"])
		Sfx.play("levelup", null, 0.9)
		var first: String = P["order"][0]
		if not first in pr().get("learned", []):
			Progress.learn(first)
		if Game.player:
			Game.player.apply_profile_stats()
	var jid: String = m.get("teach", "")
	if jid != "":
		_teach(pid, jid, true)
	Game.save_game()


# ------------------------------------------------------------------ usta diyaloğu
static func interact(it: Dictionary) -> void:
	var pid: String = it.get("path", "")
	if not PATHS.has(pid):
		return
	var P: Dictionary = PATHS[pid]
	var M: Dictionary = P["mentor"]
	set_state(pid, FOUND)
	var title = "%s — %s" % [M["name"], M["title"]]
	var lv = int(pr().get("level", 1))
	var s = state(pid)
	if s < JOINED:
		if s == TRIAL or String(st_of(pid).get("q", "")) != "":
			Hud.dialog(title, "\"Sınavın bitmedi. Sözünü tut.\"", [])
			return
		if lv < int(P["join_level"]):
			Hud.dialog(title, P["intro"] + "\n\n\"Ama henüz çok zayıfsın. Seviye %d olunca gel.\"" % int(P["join_level"]), [])
			return
		var opts = []
		if Missions.active().is_empty():
			opts.append({"label": "Sınavı kabul et", "cb": func():
				st_of(pid)["s"] = TRIAL
				st_of(pid)["q"] = "trial"
				Missions.accept(_quest(pid, "trial", ""))})
		Hud.dialog(title, P["intro"] + ("" if Missions.active().is_empty() else "\n\n(Önce elindeki görevi bitir.)"), opts)
		return
	# yolda: teknik öğretme
	var opts = []
	var learned: Array = pr().get("learned", [])
	var shown = 0
	for jid in P["order"]:
		if jid in learned:
			continue
		var j: Dictionary = Data.jutsu.get(jid, {})
		var need = int(j.get("level", 1))
		var nm = String(j.get("name", jid)).split(" (")[0]
		var dark = int(P["dark"].get(jid, 0))
		var qk = String(P["quest"].get(jid, ""))
		var pc = price(jid)
		var tag = ("  ⚠ karanlık: köy itibarı -%d" % dark) if dark > 0 else ""
		if lv < need:
			opts.append({"label": "%s — Seviye %d gerekli" % [nm, need], "tip": j.get("desc", ""), "cb": func():
				Hud.msg("Bu teknik için Seviye %d olmalısın." % need, Color(1, 0.7, 0.4))})
		elif qk != "":
			var k = jid
			opts.append({"label": "%s — özel sınav (%d Ryō)%s" % [nm, pc, tag], "tip": j.get("desc", ""), "cb": func():
				if not Missions.active().is_empty():
					Hud.msg("Önce elindeki görevi bitir.", Color(1, 0.7, 0.4))
					return
				if int(pr()["ryo"]) < pc:
					Hud.msg("Yeterli Ryō yok.", Color(1, 0.5, 0.4))
					return
				Progress.add_ryo(-pc)
				st_of(pid)["q"] = k
				Missions.accept(_quest(pid, qk, k))})
		else:
			var k2 = jid
			opts.append({"label": "Öğren: %s (%d Ryō)%s" % [nm, pc, tag], "tip": j.get("desc", ""), "cb": func():
				if int(pr()["ryo"]) < pc:
					Hud.msg("Yeterli Ryō yok.", Color(1, 0.5, 0.4))
					return
				Progress.add_ryo(-pc)
				_teach(pid, k2, false)})
		shown += 1
		if shown >= 4:
			break
	var txt = "\"%s\"\n\n%s" % [["Bugün ne öğrenmeye geldin?", "Pratik yapmadan yeni teknik yok... ama sen çalışkansın.", "Göster bakalım ne kadar ilerledin."][lv % 3], next_step(pid)]
	if opts.is_empty():
		txt = "\"Sana öğretebileceğim her şeyi öğrendin. Artık kendi yolunu çiz.\""
	Hud.dialog(title, txt, opts)


static func _teach(pid: String, jid: String, from_quest: bool) -> void:
	var P: Dictionary = PATHS[pid]
	if jid in pr().get("learned", []):
		return
	Progress.learn(jid)
	if pid == "kapi" and not "gates" in pr().get("skills", []):
		pr()["skills"].append("gates")   # Sekiz Kapı modu (B) bu yolla açılır
		Hud.msg("Sekiz Kapı açıldı: B tuşuyla kapıları zorla.", Color(0.5, 1, 0.5))
	var dark = int(P["dark"].get(jid, 0))
	if dark > 0:
		Missions._rep(Progress.home(), -dark)
		Hud.msg("Yasak bir sanat öğrendin. Köyün seni şüpheyle izliyor (itibar -%d)." % dark, Color(0.85, 0.5, 0.9), 5.0)
	if Game.player:
		FX.aura(Game.player, P["color"], 1.4)
	Sfx.play("levelup", null, 1.2, 0.6)
	if not from_quest:
		Game.save_game()


# ------------------------------------------------------------------ görevler (Missions adım türleri)
static func _near(at: Array, d: float) -> Array:
	var a = randf() * TAU
	return [float(at[0]) + cos(a) * d, float(at[1]) + sin(a) * d]


static func _quest(pid: String, kind: String, teach: String) -> Dictionary:
	var at: Array = lairs.get(pid, [Game.to_map(Game.player.global_position).x, Game.to_map(Game.player.global_position).y])
	var base = {"rank": "B", "village": Progress.home(), "hook": "LegendPaths.quest_done", "path": pid, "teach": teach, "trial": kind == "trial"}
	var q = {}
	match pid + ":" + kind:
		"tip:trial":
			q = {"title": "Şifacının Sınavı", "rank": "C",
				"brief": "Dağ yolunda pusuya düşen bir kervanın yaralıları ölmek üzere. Haydutları dağıt, yaralıların yanına git ve şifa otlarını topla.",
				"steps": [
					{"kind": "kill", "at": _near(at, 380.0), "enemy": "bandit", "n": 4, "camp": true, "text": "Kervanı basan haydutları dağıt."},
					{"kind": "collect", "at": _near(at, 200.0), "item": "şifa otu", "n": 5, "spread": 24, "text": "Şifa otlarını topla (5)."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Yuge Şifa Tapınağı", "text": "Otlarla ustaya dön."}]}
		"tip:seal":
			q = {"title": "Yaradılış Mührü", "rank": "A",
				"brief": "Yaradılış Yenilenmesi için alnına yıllarca chakra biriktiren bir mühür gerekir. Beş şifa taşını uyandır ve mührü korurken gelen kaçakları püskürt.",
				"steps": [
					{"kind": "points", "at": _near(at, 40.0), "n": 5, "spread": 16, "label": "[F] Şifa taşına chakra ver", "fx": "seal", "text": "Beş şifa taşını uyandır (5)."},
					{"kind": "defend", "at": at, "enemy": "rogue", "waves": [3, 4], "text": "Mührü korurken saldıranları püskürt."}]}
		"kapi:trial":
			q = {"title": "Gençliğin Sınavı", "rank": "C",
				"brief": "Usta, dağın tepesine kadar koşmanı ve oradaki haydut çetesini yalnızca yumruklarınla dağıtmanı istiyor. Sonra geri koş!",
				"steps": [
					{"kind": "goto", "at": _near(at, 600.0), "r": 14.0, "name": "Dağın Tepesi", "text": "Dağın tepesine koş."},
					{"kind": "kill", "at": _near(at, 600.0), "enemy": "bandit", "n": 5, "camp": true, "text": "Haydut çetesini dağıt."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Seishun Dojosu", "text": "Dojoya geri koş."}]}
		"kapi:gates":
			var cliff = _near(at, 900.0)
			q = {"title": "Kapıların Bedeli", "rank": "A",
				"brief": "Kapıları açmak bedeni parçalar. Usta, seni bir şelalenin altında dayanıklılığını sınamaya ve ardından güçlü bir rakibi yenmeye gönderiyor.",
				"steps": [
					{"kind": "goto", "at": cliff, "r": 14.0, "name": "Şelale", "text": "Şelalenin altına git."},
					{"kind": "kill", "at": cliff, "enemy": "rogue", "n": 3, "camp": true, "boss": {"name": "Demir Yumruk Gōzan", "hp": 2400.0, "level": 26, "power": 2.6}, "text": "Demir Yumruk'u yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Seishun Dojosu", "text": "Dojoya dön."}]}
		"yilan:trial":
			var den = _near(at, 420.0)
			q = {"title": "Yılanın Sınavı", "rank": "B",
				"brief": "Usta, kabuk değiştiren dev yılanın izinden gidip o yılanı besleyen Ses ninjalarının inini dağıtmanı istiyor. Dönüşte yılanın döktüğü pulları getir.",
				"steps": [
					{"kind": "track", "from": at, "to": den, "text": "Kabuk değiştiren dev yılanın izini sür."},
					{"kind": "kill", "at": den, "enemy": "oto", "n": 4, "camp": true, "boss": {"name": "Zehirli Diş Kōja", "hp": 900.0, "level": 14, "power": 1.8}, "text": "Ses ninjalarının inini dağıt."},
					{"kind": "collect", "at": _near(at, 160.0), "item": "yılan pulu", "n": 5, "spread": 24, "text": "Dökülmüş yılan pullarını topla (5)."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Ryūchi İni", "text": "Pullarla ustaya dön."}]}
		"yilan:sword":
			var shrine = _near(at, 650.0)
			q = {"title": "Kılıcın Yuvası", "rank": "A",
				"brief": "Kusanagi'nin bir eşi, terk edilmiş bir tapınakta kılıç yutan bir muhafızın midesinde saklanıyor. Muhafızı yen; kılıcı yutmayı ustan öğretecek.",
				"steps": [
					{"kind": "goto", "at": shrine, "r": 14.0, "name": "Terk Edilmiş Tapınak", "text": "Terk edilmiş tapınağa git."},
					{"kind": "kill", "at": shrine, "enemy": "rogue", "n": 3, "camp": true, "boss": {"name": "Kılıç Yutan Muhafız", "hp": 1600.0, "level": 22, "power": 2.2}, "text": "Kılıç yutan muhafızı yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Ryūchi İni", "text": "Kılıçla ustaya dön."}]}
		"yilan:curse":
			q = {"title": "Lanetin Bedeli", "rank": "A",
				"brief": "Lanetli mühür, bedeni yanmayan beş mühür taşına bağlanmadan uyanmaz. Taşları uyandır ve mührün çektiği kaçak ninjalara karşı ayakta kal.",
				"steps": [
					{"kind": "points", "at": _near(at, 40.0), "n": 5, "spread": 16, "label": "[F] Mühür taşını uyandır", "fx": "seal", "text": "Beş mühür taşını uyandır (5)."},
					{"kind": "defend", "at": at, "enemy": "rogue", "waves": [3, 3, 4], "text": "Mührün çektiği kaçak ninjaları püskürt."}]}
		"silah:trial":
			q = {"title": "Demircinin Sınavı", "rank": "C",
				"brief": "Demirci, iyi çelik için tepedeki eski madenden cevher istiyor. Madeni haydutlar basmış. Cevheri getir ve demirhaneyi koru.",
				"steps": [
					{"kind": "collect", "at": _near(at, 220.0), "item": "demir cevheri", "n": 6, "spread": 30, "guard": {"enemy": "bandit", "n": 3}, "text": "Eski madenden demir cevheri topla (6)."},
					{"kind": "defend", "at": at, "enemy": "bandit", "waves": [2, 3], "text": "Demirhaneye saldıran haydutları püskürt."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Tetsuyama Demirhanesi", "text": "Ustaya dön."}]}
		"silah:dragons":
			q = {"title": "İkiz Ejderin Parşömenleri", "rank": "B",
				"brief": "Sōshōryū'nun iki ana parşömeni, ustanın eski rakibi olan kaçak bir ninja tarafından çalındı. Parşömenleri geri getir.",
				"steps": [
					{"kind": "collect", "at": _near(at, 520.0), "item": "ejderha parşömeni", "n": 2, "spread": 40, "guard": {"enemy": "rogue", "n": 4}, "text": "Çalınan ikiz ejderha parşömenlerini bul (2)."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Tetsuyama Demirhanesi", "text": "Parşömenleri ustaya getir."}]}
		"silah:fan":
			var far = _near(at, 1300.0)
			q = {"title": "Efsanevi Yelpaze", "rank": "A",
				"brief": "Palmiye yaprağından dokunmuş efsanevi yelpaze, dağ geçidindeki samuray kalesinde mühürlü. Bekçisini yen ve yelpazeyi kazan.",
				"steps": [
					{"kind": "track", "from": at, "to": far, "text": "Eski haritadaki dağ geçidine giden yolu izle."},
					{"kind": "kill", "at": far, "enemy": "samurai", "n": 4, "camp": true, "boss": {"name": "Yelpaze Bekçisi Hōkaze", "hp": 3500.0, "level": 32, "power": 2.6}, "text": "Yelpaze bekçisini yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Tetsuyama Demirhanesi", "text": "Yelpazeyle ustaya dön."}]}
	base.merge(q, true)
	return base


# ------------------------------------------------------------------ dünyaya yerleştirme (World.build -> Sites)
static func build_all(parent: Node3D) -> void:
	node()
	for pid in PATHS:
		var s: Dictionary = PATHS[pid]["site"]
		var c = {}
		for cc in Game.world_info["countries"]:
			if cc["id"] == s["country"]:
				c = cc
		if c.is_empty():
			continue
		var p = Vector2(float(c["x"]), float(c["y"])) + s["off"]
		# kara olmalı: denizdeyse ülke merkezine doğru kaydır
		for k in 6:
			if Game.terrain_height(p.x, -p.y) > 2.0:
				break
			p = p.lerp(Vector2(float(c["x"]), float(c["y"])), 0.3)
		var base = Game.terrain_height(p.x, -p.y)
		var b = Builder.new(parent, p.x, p.y, base, "Yol_%s" % pid)
		b.view_dist = 1800.0
		Roadside._add_clear(p.x, p.y, float(s.get("clear", 46.0)))   # inin çevresinde orman/ot açıklığı
		var front = PathLairs.build(String(s["kind"]), b, pid, p, base)
		b.finish()
		lairs[pid] = [p.x, p.y + front]   # ustanın önü (yerel kuzey = harita +y)


static func _mentor(b: Builder, pid: String, at: Vector3, yaw: float) -> void:
	var M: Dictionary = PATHS[pid]["mentor"]
	var look = CharacterModel.default_look()
	look.merge(M["look"], true)
	var m = CharacterModel.new()
	b.root.add_child(m)
	m.setup(look)
	m.global_position = b.w(at)
	m.rotation.y = yaw   # PI: yüzü güneye, meydana dönük
	m.play("idle", 0.0)
	var nl = Label3D.new()
	nl.text = "%s\n%s" % [M["name"], M["title"]]
	nl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nl.font_size = 34
	nl.outline_size = 8
	nl.pixel_size = 0.0045
	nl.modulate = PATHS[pid]["color"].lightened(0.35)
	nl.visibility_range_end = 26.0
	m.add_child(nl)
	nl.position = Vector3(0, 2.25, 0)
