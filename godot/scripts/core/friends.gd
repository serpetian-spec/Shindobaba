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
const JOIN_BOND := 55
const TALK_CD := 600.0      # sn (gerçek zaman)
const GIFT_COST := 100
const RETURN_T := 60.0
const DEATH_P := 0.06     # takımdaki dost düşünce kalıcı ölme olasılığı (ölüm nadir)
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
	if v.has_meta("grad_id"):
		return [{"label": "Kendini tanıt (yeni mezun)", "cb": func(): _meet_grad(v)}]
	if v.role == "teacher" and v.interior:
		return _teacher_opts()
	if v.has_meta("kage_vid") and String(v.get_meta("kage_vid")) == Progress.home():
		return _kage_teach_opts()
	if not is_ninja(v):
		return []   # sıradan köylüler, çocuklar, özel kişiler (Kage, hocalar) dost/takım olmaz
	return [{"label": "Kendini tanıt", "cb": func(): _meet(v)}]


## Sabit yerdeki NPC'ler (kapı nöbetçisi, hoca, klan sakini) bölgeye her girişte yeniden kurulur: konumları kalıcı anahtar
static func site_key(p: Vector3) -> String:
	return "%d:%d" % [roundi(p.x), roundi(p.z)]


## Bu sabit yerde tanıştığın biri varsa (köyde, sağ, kaçmamış): kimliği
static func at_site(key: String) -> String:
	var fs = all()
	for id in fs:
		var f: Dictionary = fs[id]
		if String(f.get("site", "")) == key and String(f.get("status", "")) == "" and not f.get("party", false) and String(f.get("kage", "")) == "":
			return String(id)
	return ""


## Başındaki isim etiketi: ad + rütbe, bağ rengiyle
static func tag(v: Node) -> void:
	var id = String(v.get_meta("friend_id", ""))
	if id == "" or not all().has(id) or not v.has_method("set_name_tag"):
		return
	var f: Dictionary = all()[id]
	v.set_name_tag("%s\n%s" % [f["name"], RANKS[int(f.get("rank", 0))]], level_color(int(f["bond"])).lerp(Color.WHITE, 0.3))


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


## Kişilik: sohbet konusu ve hediyeye tepkiyi belirler (3 sohbetten sonra öğrenirsin)
const TRAITS := {
	"ciddi": {"like": ["antrenman"], "hate": ["şaka", "dedikodu"], "desc": "Ciddi — antrenmandan konuşmayı sever, şakadan hoşlanmaz"},
	"neşeli": {"like": ["şaka", "dedikodu"], "hate": [], "desc": "Neşeli — şakaya ve köy dedikodusuna bayılır"},
	"utangaç": {"like": ["aile"], "hate": ["dedikodu", "övgü"], "desc": "Utangaç — ailesinden söz etmeyi sever, övülünce kızarır"},
	"gururlu": {"like": ["övgü", "antrenman"], "hate": ["şaka"], "desc": "Gururlu — övülmeyi ve güç konuşmayı sever"},
	"sıcakkanlı": {"like": ["aile", "şaka"], "hate": [], "desc": "Sıcakkanlı — herkesle iyi geçinir, aile sohbetini sever"},
	"alaycı": {"like": ["dedikodu"], "hate": ["övgü", "aile"], "desc": "Alaycı — dedikoduya bayılır, duygusal laflardan hoşlanmaz"},
}
const TOPICS := [["antrenman", "Antrenmandan, tekniklerden konuş"], ["aile", "Ailesini sor"], ["şaka", "Şaka yap"], ["dedikodu", "Köy dedikodusu anlat"], ["övgü", "Onu öv"]]
const REPLIES := {"like": ["Haha, tam da bunu konuşmak istiyordum!", "Seninle konuşmak gerçekten iyi geliyor.", "Beni iyi tanıyorsun."],
	"neutral": ["Hmm, olabilir.", "Anlıyorum.", "İlginç."], "hate": ["...Bunu konuşmasak?", "Pek hoşuma gitmedi bu.", "Ciddi misin?"]}
## Hediyeler: [ad, fiyat]; herkes birini sever, birinden hoşlanmaz
const GIFTS := [["Dango kutusu", 60], ["Kunai takımı", 160], ["Eski parşömen", 260], ["Çiçek demeti", 40], ["Ramen kuponu", 90], ["Sake", 120]]
const GIFT_CD := 1800.0
const TRAIN_CD := 1200.0


static func _ensure_persona(f: Dictionary) -> void:
	if not f.has("trait"):
		f["trait"] = TRAITS.keys().pick_random()
		var gs = range(GIFTS.size())
		gs.shuffle()
		f["gift_like"] = gs[0]
		f["gift_hate"] = gs[1]
		f["talks"] = 0
	if not f.has("loyalty"):
		# herkes iyi değildir: ~%20'si gizlice hain ruhlu
		f["loyalty"] = randi_range(5, 30) if randf() < 0.2 else randi_range(40, 100)
		f["ambition"] = FriendPlots.AMBITIONS.pick_random()
		f["love"] = 0


static func trait_known(f: Dictionary) -> bool:
	return int(f.get("talks", 0)) >= 3


## Oyuncunun rütbesi (0 Akademi, 1 Genin, 2 Chūnin, 3 Jōnin...) dostun rütbesinden düşükse takıma girmez
static func rank_ok(f: Dictionary) -> bool:
	return int(pr().get("rank", 0)) >= int(f.get("rank", 0))


static func _friend_opts(id: String, v: Node) -> Array:
	var f: Dictionary = all()[id]
	_ensure_persona(f)
	var b = int(f["bond"])
	var opts = []
	var now = Time.get_unix_time_from_system()
	var can_talk = now - float(f.get("last_talk", 0.0)) >= TALK_CD
	opts.append_array(FriendPlots.option(id))
	if b < 0:
		if can_talk:
			opts.append({"label": "Özür dile, arayı düzelt", "cb": func():
				f["last_talk"] = Time.get_unix_time_from_system()
				var ok = randf() < (0.6 if b > -60 else 0.25)
				Hud.dialog(String(f["name"]), "...Peki. Bir şans daha." if ok else "Özrün de sen de umurumda değil.", [])
				add_bond(id, 8 if ok else 0)})
	elif can_talk:
		opts.append({"label": "Sohbet et...", "cb": func(): _topic_dialog(id)})
	if now - float(f.get("last_gift", 0.0)) >= GIFT_CD:
		opts.append({"label": "Hediye ver...", "cb": func(): _gift_dialog(id)})
	if b >= 15 and now - float(f.get("last_train", 0.0)) >= TRAIN_CD:
		opts.append({"label": "Antrenman alanına gidip idman yapalım", "cb": func(): begin_activity(id, "train")})
	if b >= 25 and now - float(f.get("last_meal", 0.0)) >= TRAIN_CD:
		opts.append({"label": "Birlikte yemeğe gidelim (150 Ryō)", "cb": func():
			if int(pr().get("ryo", 0)) < 150:
				Hud.msg("Yeterli Ryō yok.", Color(1, 0.5, 0.4))
				return
			begin_activity(id, "meal")})
	if b > -60:
		opts.append({"label": "Laf sok / kışkırt", "cb": func():
			Hud.dialog(String(f["name"]), ["Ne dedin sen?!", "Bunu unutmayacağım.", "Hadi oradan!"].pick_random(), [])
			add_bond(id, -14)})
	opts.append_array(_romance_opts(id))
	if f.get("party", false):
		opts.append({"label": "Takımdan ayrıl (köyde bekle)", "cb": func(): set_party(id, false)})
	elif b >= JOIN_BOND and rank_ok(f):
		opts.append({"label": "Takımıma katıl", "cb": func():
			if set_party(id, true) and v != null and is_instance_valid(v) and v.has_method("vanish"):
				v.vanish()})
	elif b >= JOIN_BOND:
		opts.append({"label": "Takım (o bir %s, sen henüz değilsin)" % RANKS[int(f.get("rank", 0))], "cb": func():
			Hud.msg("%s: \"Bir %s rütbesi daha düşük birinin peşinden gitmez. Rütbe atla, sonra konuşuruz.\"" % [f["name"], RANKS[int(f.get("rank", 0))]], Color(0.9, 0.85, 0.6))})
	elif b >= 0:
		opts.append({"label": "Takım (bağ %d gerekir, şu an %d)" % [JOIN_BOND, b], "cb": func():
			Hud.msg("%s seni daha iyi tanımak istiyor: doğru konuları konuş, sevdiği hediyeyi bul, birlikte antrenman yap." % f["name"], Color(0.9, 0.85, 0.6))})
	return opts


## Sohbet: konu seç; kişiliğine uyan konu bağı artırır, uymayan düşürür
static func _topic_dialog(id: String) -> void:
	var f: Dictionary = all()[id]
	var opts = []
	for tp in TOPICS:
		var key = String(tp[0])
		opts.append({"label": tp[1], "cb": func():
			f["last_talk"] = Time.get_unix_time_from_system()
			f["talks"] = int(f.get("talks", 0)) + 1
			var tr: Dictionary = TRAITS[f["trait"]]
			var kind = "like" if key in tr["like"] else ("hate" if key in tr["hate"] else "neutral")
			var txt = REPLIES[kind].pick_random()
			if int(f["talks"]) == 3:
				txt += "\n\n(Onu artık daha iyi tanıyorsun: %s)" % tr["desc"]
			Hud.dialog(String(f["name"]), txt, [])
			add_bond(id, {"like": 3, "neutral": 1, "hate": -5}[kind])})
	Hud.dialog(String(f["name"]), "Ne hakkında konuşalım?" + (("\n(%s)" % TRAITS[f["trait"]]["desc"]) if trait_known(f) else ""), opts)


## Hediye: seç ve ver; sevdiği hediye çok, sevmediği eksi
static func _gift_dialog(id: String) -> void:
	var f: Dictionary = all()[id]
	var opts = []
	for gi in GIFTS.size():
		var g: Array = GIFTS[gi]
		var idx = gi
		var known = int(f.get("gift_known", -1)) == idx
		opts.append({"label": "%s (%d Ryō)%s" % [g[0], int(g[1]), "  ♥ sever" if known else ""], "cb": func():
			if int(pr().get("ryo", 0)) < int(g[1]):
				Hud.msg("Yeterli Ryō yok.", Color(1, 0.5, 0.4))
				return
			Progress.add_ryo(-int(g[1]))
			var tnow = Time.get_unix_time_from_system()
			f["last_gift"] = tnow
			var recent: Array = (f.get("gift_times", []) as Array).filter(func(x): return tnow - float(x) < 7200.0)
			recent.append(tnow)
			f["gift_times"] = recent
			var bnd = int(f["bond"])
			if recent.size() > 3:
				Hud.dialog(String(f["name"]), "Yine mi hediye? Beni satın almaya mı çalışıyorsun?", [])
				add_bond(id, -3)
				return
			var mult = [1.0, 1.0, 0.5, 0.25][recent.size() - 1]
			if idx == int(f["gift_like"]):
				f["gift_known"] = idx
				Hud.dialog(String(f["name"]), "%s! Bunu nasıl bildin? En sevdiğim!" % g[0], [])
				add_bond(id, maxi(1, int((6 if bnd >= 0 else 4) * mult)))
				f["love"] = mini(100, int(f.get("love", 0)) + int(4 * mult))
			elif idx == int(f["gift_hate"]):
				Hud.dialog(String(f["name"]), "...%s mi? Ben bundan hiç hoşlanmam aslında." % g[0], [])
				add_bond(id, -4)
			else:
				Hud.dialog(String(f["name"]), "Teşekkür ederim, düşünmen güzel." if bnd >= 0 else "...Sağ ol.", [])
				add_bond(id, maxi(0, int(2 * mult)))})
	Hud.dialog(String(f["name"]), "(Hangi hediyeyi vereceksin? Her hediyeden sonra bir süre beklemelisin.)", opts)


## Karşı cinsle aşk: bağ 60+ çıkma teklifi, sevgiliyken 80+ evlilik, evliyken çocuk (eşin klanıyla melez)
static func _romance_opts(id: String) -> Array:
	var f: Dictionary = all()[id]
	var b = int(f["bond"])
	var opts = []
	if String(f["look"].get("gender", "m")) == player_gender() or not available(f) or b < 35:
		return opts
	var rm = romance_of(id)
	var love = int(f.get("love", 0))
	var now = Time.get_unix_time_from_system()
	var taken = all().keys().any(func(k): return k != id and romance_of(k) in ["sevgili", "eş"])
	if rm in ["", "flört"] and not taken:
		# flört: gönül ölçeği (ayrı) iltifat ve gece yürüyüşüyle dolar; bağ tek başına yetmez
		if now - float(f.get("last_flirt", 0.0)) >= 600.0:
			opts.append({"label": "İltifat et ♡", "cb": func():
				f["last_flirt"] = Time.get_unix_time_from_system()
				var g = {"gururlu": 9, "utangaç": 7, "sıcakkanlı": 6, "neşeli": 5, "ciddi": 3, "alaycı": 1}.get(String(f.get("trait", "")), 4)
				if b < 50:
					g = int(g / 2)
				f["love"] = mini(100, love + g)
				Hud.dialog(String(f["name"]), ["Ah... sağ ol. Yüzüm kızardı mı?", "Bunu bana mı söyledin? Hehe.", "Dalga geçmiyorsun değil mi?"].pick_random(), [])
				Hud.msg("Gönül %+d (%d/100)" % [g, f["love"]], Color(1, 0.6, 0.75))
				_flirt_stage(id)})
		var night = Game.world and (Game.world.env.time_of_day < 0.24 or Game.world.env.time_of_day > 0.78)
		if b >= 50 and now - float(f.get("last_walk", 0.0)) >= 1200.0:
			if night:
				opts.append({"label": "Ay ışığında yürüyüşe çıkalım ♡", "cb": func(): begin_activity(id, "walk")})
		if rm == "flört":
			var need = []
			if love < 60:
				need.append("gönül %d/60" % love)
			if b < 65:
				need.append("bağ %d/65" % b)
			if need.is_empty():
				opts.append({"label": "Çıkma teklif et ♥", "cb": func():
					if randf() < clampf((love - 40) / 40.0, 0.3, 0.95):
						f["romance"] = "sevgili"
						f["since"] = Time.get_unix_time_from_system()
						log_event(f, "Seninle sevgili oldu")
						Hud.dialog(String(f["name"]), "...Ben de uzun zamandır bunu düşünüyordum. Evet!", [])
						Hud.banner("SEVGİLİ", "%s ile artık birliktesiniz ♥" % f["name"], Color(1, 0.55, 0.7))
					else:
						f["love"] = maxi(0, love - 8)
						Hud.dialog(String(f["name"]), "Senden hoşlanıyorum ama... biraz daha zaman ver.", [])})
			else:
				opts.append({"label": "Çıkma teklifi (henüz değil: %s)" % ", ".join(need), "cb": func():
					Hud.msg("Önce aranızdaki bağı ve gönlü büyüt: iltifat, gece yürüyüşü, sevdiği hediye, birlikte görev.", Color(1, 0.75, 0.8))})
	elif rm == "sevgili":
		var dating = now - float(f.get("since", now))
		var need2 = []
		if love < 85:
			need2.append("gönül %d/85" % love)
		if b < 85:
			need2.append("bağ %d/85" % b)
		if dating < 1800.0:
			need2.append("birlikte %d dk daha" % int((1800.0 - dating) / 60.0))
		if spouse_id() != "":
			need2.append("zaten evlisin")
		if need2.is_empty():
			opts.append({"label": "Evlenme teklif et 💍", "cb": func(): _marry(id)})
		else:
			opts.append({"label": "Evlilik (henüz değil: %s)" % ", ".join(need2), "cb": func():
				Hud.msg("Evlilik için sevgili olarak zaman geçirin; gönül ve bağ 85'e ulaşsın.", Color(1, 0.75, 0.8))})
		if now - float(f.get("last_walk", 0.0)) >= 1200.0:
			opts.append({"label": "Randevuya çıkalım ♡", "cb": func(): begin_activity(id, "date")})
		opts.append({"label": "Ayrıl", "cb": func():
			f["romance"] = ""
			f["love"] = int(love / 3)
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


static func _flirt_stage(id: String) -> void:
	var f: Dictionary = all()[id]
	if romance_of(id) == "" and int(f.get("love", 0)) >= 30:
		f["romance"] = "flört"
		log_event(f, "Aranızda bir şeyler başladı")
		Hud.banner("FLÖRT", "%s ile aranızda bir şeyler başlıyor..." % f["name"], Color(1, 0.65, 0.8))


static func _marry(id: String) -> void:
	var f: Dictionary = all()[id]
	if randf() > clampf((int(f.get("love", 0)) - 70) / 25.0, 0.4, 0.97):
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


static func _meet(v: Node, name_over := "") -> void:
	var fs = all()
	var female = String(v.look.get("gender", "m")) == "f"
	var given = (ClanWorld.GIVEN_F if female else ClanWorld.GIVEN_M).pick_random()
	var clan = ""
	var eye = [0, 0]
	if v is ClanResident:
		given = String(v.given)
		clan = String(v.clan)
		eye = [int(v.eye_kind), int(v.eye_lvl)]
	if name_over != "":
		given = name_over
	var age = String(v.look.get("age", "adult"))
	var rank = 0 if age == "teen" else (2 if v.role in ["teacher", "guard"] else (1 if v.look.get("vest") != null else randi_range(0, 1)))
	var id = "f%d" % (int(pr().get("friend_seq", 0)) + 1)
	pr()["friend_seq"] = int(pr().get("friend_seq", 0)) + 1
	var lk: Dictionary = v.look.duplicate()
	lk.erase("age")
	# köydeki itibarın ilk bakışı belirler (kötü şöhretliysen soğuk başlar)
	var rep = int(pr().get("rep", {}).get(Progress.home(), 0))
	var start = clampi(rep / 10, -25, 20)
	fs[id] = {"name": given, "role": v.role, "ninja": true, "look": _ser(lk), "bond": start, "village": Progress.home(), "party": false,
		"last_talk": Time.get_unix_time_from_system(), "element": ELS.pick_random(), "clan": clan, "eye": eye, "rank": rank,
		"family": _family(clan, female, rank), "status": "", "log": [], "news": "",
		"title": ("%s klanı" % ClanWorld.clan_name(clan)) if clan != "" else "%s ninjası" % String(Game.village(Progress.home()).get("name", "Köy"))}
	if v.has_meta("site_key"):
		fs[id]["site"] = String(v.get_meta("site_key"))   # aynı yerde (kapı, avlu) yeniden kurulunca yine o
	var hp: Vector3 = v.global_position
	fs[id]["home"] = [snappedf(hp.x, 0.1), snappedf(hp.y, 0.1), snappedf(hp.z, 0.1)]   # haritada bulmak için
	if clan != "" and String(v.vid) != "":
		fs[id]["village"] = String(v.vid)
	v.set_meta("friend_id", id)
	v.display = given
	v.display_override = given
	tag(v)
	Hud.dialog(given, "Ben %s, %s. Tanıştığımıza memnun oldum! Bir gün birlikte savaşırız belki." % [given, RANKS[rank]], [])
	Hud.msg("Yeni tanıdık: %s (Tab > İlişkiler)" % given, Color(0.6, 1.0, 0.7))


static func set_party(id: String, on: bool) -> bool:
	var f: Dictionary = all().get(id, {})
	if f.is_empty():
		return false
	if on:
		if not available(f):
			Hud.msg("%s şu an köyde değil." % f["name"], Color(1, 0.7, 0.4))
			return false
		if party_ids().size() >= party_max():
			Hud.msg("Takımın dolu (en fazla %d kişi). Önce birini köyde beklet." % party_max(), Color(1, 0.7, 0.4))
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
		_ensure_persona(f)
		if int(f.get("loyalty", 50)) < 30 and b < 70 and randf() < 0.3:
			_betrayal_event(id)
		elif r < defect_p:
			_defect(id)
		elif r < defect_p + 0.3 and rank < 3 and randf() < [0.9, 0.6, 0.35][rank]:
			f["rank"] = rank + 1
			log_event(f, "%s oldu" % RANKS[rank + 1])
			f["news"] = "Duydun mu? Artık %s oldum! Yeleği giyince insan bir tuhaf oluyor." % RANKS[rank + 1]
			Hud.msg("Haber: %s %s oldu!" % [f["name"], RANKS[rank + 1]], Color(0.6, 1.0, 0.75), 5.0)
		elif r < defect_p + 0.42 and not spouse and rank >= 1 and romance_of(id) == "" and not likes_you(f):
			var fem = String(f["look"].get("gender", "m")) == "f"
			# kimi zaman tanıdığın başka bir dostla evlenir (ikisi de bekâr, karşı cins, aynı köy, sana gönlü olmayan)
			var mates = fs.keys().filter(func(k): return k != id and String(fs[k].get("status", "")) == "" and int(fs[k].get("rank", 0)) >= 1 				and String(fs[k]["look"].get("gender", "m")) != String(f["look"].get("gender", "m")) and String(fs[k].get("village", "")) == String(f.get("village", "")) 				and romance_of(k) == "" and not likes_you(fs[k]) and not (fs[k].get("family", []) as Array).any(func(m): return String(m["rel"]) in ["Karısı", "Kocası"]))
			if not mates.is_empty() and randf() < 0.5:
				_wed(id, String(mates.pick_random()))
				return
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
			var kid = {"rel": "Kızı" if kf else "Oğlu", "name": kn, "alive": true, "born": now}
			if sclan != "" and String(f.get("clan", "")) != "" and sclan != String(f["clan"]):
				kid["mix"] = "%s × %s melezi" % [ClanWorld.clan_name(String(f["clan"])), ClanWorld.clan_name(sclan)]
			fam.append(kid)
			for m3 in fam:   # eşi de tanıdığınsa çocuk onun ailesine de yazılır (aynı kayıt)
				if String(m3["rel"]) in ["Karısı", "Kocası"] and fs.has(String(m3.get("fid", ""))):
					(fs[String(m3["fid"])]["family"] as Array).append(kid)
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
		elif r < defect_p + 0.81:
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


## Takım seninle gelir: dışarıda ve dövüş geçen iç mekânlarda (mağara / deney ini); dükkân ve evlerde kapıda bekler
func _party_ok() -> bool:
	if _active():
		return true
	if pr().is_empty() or Game.player == null or Exams.cur != "" or int(ChuninExam.stage) != 0:
		return false
	return Interiors.inst != null and Interiors.inst.inside.begins_with("lair_")


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
	q.y = Game.jutsu_floor(q.x, q.z)
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
	var d = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * 16.0
	visitor = _spawn_npc(id, Game.player.global_position + d, true)
	visit_t = 0.0
	var b = int(f["bond"])
	Hud.msg(("%s seni gördü, yanına geliyor." if b >= 0 else "%s sana doğru geliyor... pek dostça görünmüyor.") % f["name"], level_color(b))


## Dostu dünyada köylü olarak doğur (ziyaret / haritada bulma); walk: oyuncuya yürüsün
func _spawn_npc(id: String, at: Vector3, walk: bool) -> Villager:
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
	var q = at
	q.y = Game.ground_height(q.x, q.z)
	vg.global_position = q
	vg.home = q
	vg.goal = Game.player.global_position if walk else q
	if not walk:
		vg.wander_r = 3.0
	return vg


## Haritada bul: dostun bulunduğu yer (sabit yeri / tanıştığınız yer; kaçaksa Bingo bölgesi ya da sığınak)
static func where(id: String) -> Vector3:
	var f: Dictionary = all().get(id, {})
	if f.is_empty() or String(f.get("status", "")) == "öldü":
		return Vector3.INF
	if String(f.get("status", "")) == "kaçak":
		if Orgs.is_rogue():
			return Orgs.hideout_pos() + Vector3(6, 0, 6)
		for e in Game.profile.get("bingo", {}).get("list", []):
			if String(e.get("friend_id", "")) == id and String(e.get("status", "")) == "alive":
				var a: Array = e.get("area", e.get("hide", [0, 0]))
				return Game.from_map(Vector2(float(a[0]), float(a[1])))
		return Vector3.INF
	if String(f.get("kage", "")) != "" or String(f.get("status", "")) != "":
		return Vector3.INF
	return _job_pos(f)   # işine göre: kapıda nöbet, antrenman alanı, evi; görevdeyse köy dışında (bilinmez)


static func show_on_map(id: String) -> void:
	var p = where(id)
	if p == Vector3.INF:
		var ff: Dictionary = all().get(id, {})
		Hud.msg("%s görevde, köy dışında. Yolda karşılaşabilirsin." % ff.get("name", "") if job_of(ff) == "görev" and String(ff.get("status", "")) == "" else "Nerede olduğunu bilmiyorsun.", Color(1, 0.7, 0.4))
		return
	Game.profile["waypoint"] = [p.x, p.y, p.z, "Dost: %s" % all()[id]["name"]]
	Game.profile["track"] = "waypoint"
	Game.profile["find_friend"] = id
	Hud.msg("%s haritada işaretlendi (ışık sütunu)." % all()[id]["name"], Color(0.6, 1.0, 0.75))


## İşaretlenen dostun yerine varınca orada yoksa ortaya çıkar (seni bekler)
var _find_node: Node = null


func _find_tick() -> void:
	var id = String(Game.profile.get("find_friend", ""))
	if id == "" or not all().has(id):
		return
	var p = where(id)
	if p == Vector3.INF or Game.player.global_position.distance_to(p) > 45.0:
		return
	Game.profile.erase("find_friend")
	for n in get_tree().get_nodes_in_group("talkers"):
		if String(n.get_meta("friend_id", "")) == id:
			return   # zaten orada (sabit yer aktörü)
	if all()[id].get("party", false) or not available(all()[id]):
		Hud.msg("%s şu an burada değil (görevde ya da hastanede)." % all()[id]["name"], Color(1, 0.75, 0.5))
		return
	_find_node = _spawn_npc(id, p, false)


## ---------------------------------------------------------------- dinamik işler, yerler, olaylar
## İş: nöbet (köy kapısı), antrenman (köyün antrenman yeri), evde (yaşadığı yer), görev (köy dışında: yolda karşılaşılabilir)
const JOBS := [["nöbet", 25], ["antrenman", 25], ["evde", 30], ["görev", 20]]
const JOB_NAMES := {"nöbet": "Kapıda nöbette", "antrenman": "Antrenmanda", "evde": "Evde", "görev": "Görevde (köy dışında)"}
var present := {}   # id -> köylü düğümü (işinin başında duran dost)
var fights: Array = []   # [{fid, foes, ally, at, t, title}]
var _wt := 0.0
var _enc_t := 600.0
var _plot_t := 900.0


static func inst() -> Friends:
	var tree = Engine.get_main_loop() as SceneTree
	return tree.current_scene.find_child("Friends", true, false) if tree and tree.current_scene else null


static func job_of(f: Dictionary) -> String:
	return String(f.get("job", "evde"))


static func _job_pos(f: Dictionary) -> Vector3:
	var v = Game.village(String(f.get("village", Progress.home())))
	if v.is_empty():
		return Vector3.INF
	var c = Vector2(float(v["x"]), float(v["y"]))
	var r = float(v["r"])
	var seed_a = float(hash(String(f.get("name", ""))) % 1000) / 1000.0
	match job_of(f):
		"nöbet":
			var gates: Array = v.get("gates", [180.0])
			var g = float(gates[int(seed_a * 97.0) % maxi(1, gates.size())])
			var gp = c + Vector2(sin(deg_to_rad(g)), cos(deg_to_rad(g))) * (r * 0.9) + Vector2(seed_a * 10.0 - 5.0, 0)
			return Game.from_map(gp)
		"antrenman":
			return Game.from_map(c + Vector2(cos(seed_a * TAU), sin(seed_a * TAU)) * r * 0.35)
		"görev":
			return Vector3.INF
	var h = f.get("home")
	if h is Array and h.size() >= 3:
		return Vector3(float(h[0]), float(h[1]), float(h[2]))
	return Game.from_map(c)


func _world_tick(dt: float) -> void:
	_wt -= dt
	if _wt > 0.0:
		_fights_tick(dt)
		return
	_wt = 1.0
	_funeral_tick()
	var now = Time.get_unix_time_from_system()
	var pp = Game.player.global_position
	# işler değişir
	for id in all():
		var f: Dictionary = all()[id]
		if String(f.get("status", "")) != "" or f.get("party", false):
			continue
		if now >= float(f.get("job_until", 0.0)):
			var tot = 0
			for jb in JOBS:
				tot += int(jb[1])
			var r = randi() % tot
			for jb in JOBS:
				r -= int(jb[1])
				if r < 0:
					f["job"] = jb[0]
					break
			f["job_until"] = now + randf_range(360.0, 840.0)
	# işinin başında: yakınındaysan orada durur (sen gidersin; o sana gelmez)
	for id in present.keys():
		var n = present[id]
		if not is_instance_valid(n) or n.global_position.distance_to(pp) > 110.0 or not all().has(id) or not available(all()[id]) or all()[id].get("party", false):
			if is_instance_valid(n):
				n.queue_free()
			present.erase(id)
	var spawned = 0
	for id in all():
		if present.has(id) or spawned >= 1:
			continue
		var f: Dictionary = all()[id]
		if not available(f) or f.get("party", false):
			continue
		var p = where(id)
		if p == Vector3.INF or p.distance_to(pp) > 70.0:
			continue
		var here = false
		for n in get_tree().get_nodes_in_group("talkers"):
			if String(n.get_meta("friend_id", "")) == id:
				here = true
		if here:
			continue
		present[id] = _spawn_npc(id, p, false)
		spawned += 1
	# işaretlenen dosta varınca
	var fid = String(Game.profile.get("find_friend", ""))
	if fid != "" and all().has(fid):
		var fp = where(fid)
		if fp != Vector3.INF and pp.distance_to(fp) < 45.0:
			Game.profile.erase("find_friend")
			if not available(all()[fid]):
				Hud.msg("%s şu an burada değil (%s)." % [all()[fid]["name"], "görevde" if job_of(all()[fid]) == "görev" else "köyde yok"], Color(1, 0.75, 0.5))
	# yolda: görevdeki dost saldırıya uğramış (köy dışındaysan)
	_enc_t -= 1.0
	if _enc_t <= 0.0 and fights.is_empty():
		_enc_t = randf_range(600.0, 1000.0)
		if Crime._village_at(pp) == "":
			var onm = all().keys().filter(func(k): return String(all()[k].get("status", "")) == "" and job_of(all()[k]) == "görev" and not all()[k].get("party", false))
			if not onm.is_empty():
				var id2 = String(onm.pick_random())
				Hud.banner("YOLDA KARŞILAŞMA", "%s görevdeyken pusuya düşmüş! Yardım et." % all()[id2]["name"], Color(1, 0.6, 0.4))
				ambush(id2, ["bandit", "rogue"].pick_random(), randi_range(3, 5), "Yol pususu", true)
	# arka planda ilerleyen planlar
	_plot_t -= 1.0
	if _plot_t <= 0.0:
		_plot_t = randf_range(500.0, 900.0)
		_plot_tick()


## Planlar kendi kendine ilerler: dost planı kurar, sana açar; kötü planlar ANBU'ya yakalanabilir (Kage görevi verir),
## başarıya yaklaşırsa acil olay olur, kimi zaman da başarır.
func _plot_tick() -> void:
	var fs = all()
	var cands = fs.keys().filter(func(k): return String(fs[k].get("status", "")) == "" and not fs[k].has("plot"))
	if not cands.is_empty() and randf() < 0.35:
		var id = String(cands.pick_random())
		_ensure_persona(fs[id])
		FriendPlots.start(id)
		return
	for id in fs:
		var f: Dictionary = fs[id]
		var p: Dictionary = f.get("plot", {})
		if p.is_empty() or String(p.get("stage", "")) == "done" or String(f.get("status", "")) != "":
			continue
		var sc = FriendPlots.scenario(String(p["id"]))
		if sc.is_empty() or sc["good"]:
			# iyi planı sen dinlemezsen bir süre sonra kendi başına yapar
			if Time.get_unix_time_from_system() - float(p.get("t", 0.0)) > 1800.0:
				p["stage"] = "done"
				Friends.log_event(f, "%s planını kendi başına yürüttü" % sc.get("title", ""))
			continue
		if Time.get_unix_time_from_system() - float(p.get("t", 0.0)) < 600.0:
			continue
		var r = randf()
		if r < 0.35:
			p["stage"] = "done"
			_kage_order(id, sc, false)
		elif r < 0.55:
			p["stage"] = "done"
			_kage_order(id, sc, true)
		elif r < 0.72:
			p["stage"] = "done"
			FriendPlots._outcome(id, sc, false)
		return


## ANBU kötü planı fark etti: Kage sana durdurma görevi verir (acil = plan başarıya çok yakın)
func _kage_order(id: String, sc: Dictionary, urgent: bool) -> void:
	var f: Dictionary = all()[id]
	var vid = String(f.get("village", Progress.home()))
	var kt = Kage.kage_name(vid)
	var lv = int(pr().get("level", 1))
	var at = Missions._spot(vid, 250, 600)
	var m = {"title": ("ACİL: " if urgent else "") + "%s'i Durdur" % f["name"], "rank": "A" if not urgent else "S", "village": vid, "giver": kt,
		"hook": "Friends.order_done", "fid": id,
		"brief": "ANBU raporu: %s, '%s' adlı bir plan yürütüyor. %s Onu durdur — gerekirse zorla." % [f["name"], sc["title"], "Plan başarıya çok yakın, vakit yok!" if urgent else ""],
		"steps": [{"kind": "kill", "at": at, "enemy": "rogue", "n": 3 if not urgent else 4, "camp": true,
			"boss": {"name": "%s (hain)" % f["name"], "hp": 900.0 + lv * 40.0, "level": lv + 2, "power": 1.6 + lv * 0.02, "flee": false},
			"text": "%s ve adamlarını yen." % f["name"]}]}
	Hud.banner("ANBU RAPORU" if not urgent else "ACİL OLAY", "%s'in planı ortaya çıktı: %s" % [f["name"], sc["title"]], Color(1, 0.5, 0.35))
	if Missions.active().is_empty():
		Hud.dialog(kt, String(m["brief"]), [{"label": "Görevi kabul et", "cb": func(): Missions.accept(m)},
			{"label": "Reddet (ANBU halleder)", "cb": func(): _anbu_handles(id, sc, urgent)}])
	else:
		_anbu_handles(id, sc, urgent)


func _anbu_handles(id: String, sc: Dictionary, urgent: bool) -> void:
	var f: Dictionary = all()[id]
	if urgent and randf() < 0.5:
		FriendPlots._outcome(id, sc, false)   # yetişemediler: plan başarılı oldu (ya da patladı)
	else:
		f["status"] = "hapiste"
		f["party"] = false
		Friends.log_event(f, "ANBU tarafından tutuklandı")
		Hud.msg("ANBU %s'i tutukladı." % f["name"], Color(0.8, 0.85, 1.0), 5.0)


## Kage görevi bitti: hain dost yakalandı (canlı yakalanması zor: çoğu dövüşte düşer)
func order_done(m: Dictionary, ok: bool) -> void:
	var id = String(m.get("fid", ""))
	if not ok or not all().has(id):
		return
	var f: Dictionary = all()[id]
	f["status"] = "öldü" if randf() < 0.6 else "hapiste"
	f["party"] = false
	Friends.log_event(f, "Kage'nin emriyle onu durdurdun (%s)" % ("öldü" if f["status"] == "öldü" else "tutuklandı"))
	Missions._rep(String(f.get("village", Progress.home())), 25)


## Yakında dövüş: düşmanlar + (ally ise) dost yanında savaşır. Kazanırsan bağ, kaybedersen dost ölebilir.
func ambush(id: String, kind: String, n: int, title: String, ally: bool) -> void:
	if Game.player == null:
		return
	var f: Dictionary = all()[id]
	var pp = Game.player.global_position
	var dir = Vector3.FORWARD
	var cam = get_viewport().get_camera_3d()
	if cam:
		dir = -cam.global_transform.basis.z
		dir.y = 0.0
		dir = dir.normalized()
	var at = Missions.open_ground(pp + dir * 25.0, 25.0)   # önünde: görebileceğin yerde
	var foes = []
	var lv = int(pr().get("level", 1))
	for i in 1:   # 1v1: kalabalık yerine tek güçlü düşman
		var a = Enemy.archetype(kind, i)
		a["respawn"] = false
		a["level"] = maxi(3, lv + randi_range(-2, 2) + 4)
		a["hp"] = (120.0 + a["level"] * 14.0) * 2.0
		a["power"] = 1.0 + a["level"] * 0.025
		a["xp"] = 30 + a["level"] * 8
		a["ryo"] = 20 + a["level"] * 4
		Enemy.toughen(a, n, "B")
		var e = Enemy.new()
		e.setup(a)
		get_tree().current_scene.add_child(e)
		var q = Missions.open_ground(at + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8)), 20.0)
		e.global_position = q
		e.home = q
		foes.append(e)
	var al = null
	if ally:
		al = _spawn(id)
		al.global_position = Missions.open_ground(at, 20.0)
		al.home = al.global_position
		al.set_meta("teammate", true)
	Game.profile["waypoint"] = [at.x, at.y, at.z, "Olay: %s" % title]
	Game.profile["track"] = "waypoint"
	fights.append({"fid": id, "foes": foes, "ally": al, "at": at, "t": 0.0, "title": title})


func _fights_tick(dt: float) -> void:
	for fg in fights.duplicate():
		fg["t"] = float(fg["t"]) + dt
		var alive = (fg["foes"] as Array).filter(func(e): return is_instance_valid(e) and not e.is_dead())
		var al = fg["ally"]
		var ally_dead = al != null and (not is_instance_valid(al) or al.is_dead())
		var far = Game.player.global_position.distance_to(fg["at"]) > 250.0 and float(fg["t"]) > 60.0
		var id = String(fg["fid"])
		if not all().has(id):
			fights.erase(fg)
			continue
		var f: Dictionary = all()[id]
		if alive.is_empty() or ally_dead or far or float(fg["t"]) > 400.0:
			fights.erase(fg)
			if Game.profile.has("waypoint") and String(Game.profile["waypoint"][3]).begins_with("Olay:"):
				Game.profile.erase("waypoint")
			if alive.is_empty() and not ally_dead:
				add_bond(id, 10)
				Friends.log_event(f, "%s: birlikte kazandınız" % fg["title"])
				Hud.msg("%s: \"Sen olmasan bitmiştim. Borçluyum.\"" % f["name"], Color(0.6, 1.0, 0.75), 5.0)
			elif ally_dead or (far and randf() < 0.35):
				if randf() < 0.15:
					f["status"] = "öldü"
					Friends.log_event(f, "%s sırasında öldü" % fg["title"])
					Hud.banner("%s ÖLDÜ" % String(f["name"]).to_upper(), "%s sırasında hayatını kaybetti." % fg["title"], Color(0.85, 0.85, 0.95))
				else:
					f["away"] = Time.get_unix_time_from_system() + 600.0
					Friends.log_event(f, "%s: ağır yaralandı" % fg["title"])
			if is_instance_valid(al):
				FX.smoke_puff(al.global_position + Vector3.UP, 0.6, 8)
				al.queue_free()


## İhanet: dost sana saldırır (yanında 2 kiralık kaçakla)
func betray_attack(id: String) -> void:
	var f: Dictionary = all()[id]
	f["party"] = false
	f["bond"] = -100
	f["status"] = "kaçak"
	Friends.log_event(f, "Sana pusu kurdu")
	var e = _spawn(id)
	e.team = "enemy"
	e.set_meta("teammate", false)
	e.target = Game.player
	if e.nameplate:
		e.nameplate.modulate = Color(1, 0.4, 0.35)
	e.display_name = "%s (HAİN)" % f["name"]
	Hud.banner("İHANET", "%s sana arkadan saldırdı!" % f["name"], Color(1, 0.3, 0.25))


## Hain ruhlu dostların küçük ihanetleri (yaşam olayı)
func _betrayal_event(id: String) -> void:
	var f: Dictionary = all()[id]
	var r = randf()
	if f.get("party", false) and r < 0.35:
		betray_attack(id)
	elif r < 0.65:
		var amt = int(int(pr().get("ryo", 0)) * randf_range(0.1, 0.2))
		Progress.add_ryo(-amt)
		f["bond"] = mini(int(f["bond"]), -40)
		f["party"] = false
		Friends.log_event(f, "Kesenden %d Ryō çaldı" % amt)
		Hud.banner("HIRSIZLIK", "%s kesenden %d Ryō çalıp ortadan kayboldu!" % [f["name"], amt], Color(1, 0.5, 0.4))
	else:
		Missions._rep(Progress.home(), -15)
		if Crime.heat() > 0:
			Game.profile["flags"]["crime_heat"] = mini(100, Crime.heat() + 20)
		f["bond"] = mini(int(f["bond"]), -30)
		Friends.log_event(f, "Seni Kage'ye şikâyet etti")
		Hud.banner("İHBAR", "%s seni Kage'ye şikâyet etmiş (−15 itibar)." % f["name"], Color(1, 0.55, 0.45))


## Birlikte görev / öldürme bağı artırır (takımdakiler)
static func on_mission_done(rank: String) -> void:
	var risk: Array = {"D": [0.0, 0.03], "C": [0.005, 0.08], "B": [0.012, 0.12], "A": [0.025, 0.18], "S": [0.04, 0.22]}.get(rank, [0.01, 0.1])
	for id in party_ids():
		var f0: Dictionary = all()[id]
		if f0.get("student", false):
			f0["sm"] = int(f0.get("sm", 0)) + {"D": 1, "C": 1, "B": 2, "A": 3, "S": 4}.get(rank, 1)
			var need = [6, 20, 45]
			var rk = int(f0.get("rank", 0))
			if rk < 3 and int(f0["sm"]) >= int(need[rk]):
				f0["rank"] = rk + 1
				log_event(f0, "Senin eğitimin sayesinde %s oldu" % RANKS[rk + 1])
				Hud.banner("ÖĞRENCİN %s OLDU" % RANKS[rk + 1].to_upper(), "%s seninle çıktığı görevlerde büyüdü." % f0["name"], Color(0.7, 0.9, 1.0))
		var r = randf()
		if r < float(risk[0]):
			f0["status"] = "öldü"
			f0["party"] = false
			log_event(f0, "%s-rank görevde hayatını kaybetti" % rank)
			Hud.banner("%s ÖLDÜ" % String(f0["name"]).to_upper(), "Görevden dönemedi. Köye onun yerine yalnız bandı döndü.", Color(0.85, 0.85, 0.95))
			continue
		elif r < float(risk[0]) + float(risk[1]):
			injure(id, "görevde yaralandı")
			continue
		add_bond(id, {"D": 2, "C": 3, "B": 4, "A": 6, "S": 8}.get(rank, 3), true)
		var f: Dictionary = all()[id]
		f["love"] = mini(100, int(f.get("love", 0)) + 2) if romance_of(id) != "" else int(f.get("love", 0))
	if not party_ids().is_empty():
		Hud.msg("Takımdaki dostlarla bağınız güçlendi.", Color(0.6, 1.0, 0.75))


## Seninle flört/sevgili aşamasında olan başkasıyla evlenmez (diğerleri normal evlenir)
static func likes_you(f: Dictionary) -> bool:
	return String(f.get("romance", "")) != ""


## İki tanıdık dost birbiriyle evlenir
static func _wed(a: String, b: String) -> void:
	var fa: Dictionary = all()[a]
	var fb: Dictionary = all()[b]
	var a_fem = String(fa["look"].get("gender", "m")) == "f"
	if not fa.has("family"):
		fa["family"] = []
	if not fb.has("family"):
		fb["family"] = []
	fa["family"].append({"rel": "Kocası" if a_fem else "Karısı", "name": fb["name"], "alive": true, "clan": String(fb.get("clan", "")), "fid": b})
	fb["family"].append({"rel": "Karısı" if a_fem else "Kocası", "name": fa["name"], "alive": true, "clan": String(fa.get("clan", "")), "fid": a})
	log_event(fa, "%s ile evlendi" % fb["name"])
	log_event(fb, "%s ile evlendi" % fa["name"])
	fa["news"] = "%s ile evlendik! İkimizi de tanıyorsun, düğüne gelmeliydin!" % fb["name"]
	fb["news"] = "%s ile evlendik. Bize bir ziyarete gel." % fa["name"]
	Hud.banner("DÜĞÜN", "%s ile %s evlendi!" % [fa["name"], fb["name"]], Color(1, 0.85, 0.6))


## ---------------------------------------------------------------- birlikte etkinlik: gerçekten gidilir, yapılır
## meal: en yakın ramen tezgâhı / yakiniku / çay evi / han; train: antrenman alanında dostça idman maçı;
## walk: gece seyir noktasına yürüyüş; date: çay evi ya da ramen. Dost yanında yürür; varınca sahne oynanır.
var act := {}


static func begin_activity(id: String, kind: String) -> void:
	var me = inst()
	if me == null or Game.player == null:
		return
	if not me.act.is_empty():
		Hud.msg("Şu an zaten %s ile birliktesin." % all().get(String(me.act["id"]), {}).get("name", "biri"), Color(1, 0.75, 0.5))
		return
	var dest = me._dest_for(kind)
	if dest.is_empty():
		Hud.msg("Yakınlarda buna uygun bir yer yok.", Color(1, 0.75, 0.5))
		return
	var f: Dictionary = all()[id]
	var orig: Node = null
	for n in me.get_tree().get_nodes_in_group("talkers"):
		if String(n.get_meta("friend_id", "")) == id:
			orig = n
	var start = orig.global_position if orig else Game.player.global_position + Vector3(2, 0, 2)
	var comp = me._spawn_npc(id, start, true)
	comp.set_meta("act", true)
	comp.remove_meta("friend_id")   # yoldayken konuşma menüsü açılmasın
	if orig:
		orig.visible = false
		orig.remove_from_group("talkers")
	me.act = {"id": id, "kind": kind, "dest": dest, "node": comp, "orig": orig, "t": 0.0, "stage": "go"}
	var lbl = String(dest["name"])
	Game.profile["waypoint"] = [dest["pos"].x, dest["pos"].y, dest["pos"].z, "%s ile: %s" % [f["name"], lbl]]
	Game.profile["track"] = "waypoint"
	var lines = {"meal": "Acıktım zaten! %s'e gidelim, yol boyu anlatırım." % lbl, "train": "Antrenman alanına mı? Hadi, ısınarak gidelim!",
		"walk": "Gece yürüyüşü... Peki. Seyir yerine çıkalım mı?", "date": "Randevu mu? ...Tamam. %s olsun." % lbl}
	comp.say(String(lines.get(kind, "Hadi gidelim!")), 3.5)
	Hud.msg("%s seninle geliyor — %s (haritada işaretli)" % [f["name"], lbl], Color(0.6, 1.0, 0.75))


func _dest_for(kind: String) -> Dictionary:
	var pp = Game.player.global_position
	var best = {}
	var bd = 900.0
	match kind:
		"meal", "date":
			for it in Interact.items:
				var k = String(it.get("kind", ""))
				var ok = k == "ramen" or (k == "enter" and String(it.get("room", "")) in (["teahouse", "bbq"] if kind == "meal" else ["teahouse"])) or (kind == "meal" and k in ["inn", "inn_sleep"])
				if not ok or it.get("interior", false):
					continue
				var d = pp.distance_to(it["pos"])
				if d < bd:
					bd = d
					var nm = {"ramen": "Ramen tezgâhı", "inn": "Han", "inn_sleep": "Han"}.get(k, Interiors.TITLES.get(String(it.get("room", "")), "Lokanta"))
					best = {"pos": it["pos"], "type": k, "it": it, "name": nm}
			if best.is_empty() and kind == "date":
				return _dest_for("meal")
		"train":
			var tp = Exams.find_point(["training"])
			best = {"pos": tp, "type": "train", "name": "Antrenman Alanı"}
		"walk":
			var lp = Exams.find_point(["lookout"])
			if lp.distance_to(pp) > 900.0:
				lp = Exams.find_point(["training"])
			best = {"pos": lp, "type": "walk", "name": "Seyir yeri"}
	return best


func _act_tick(dt: float) -> void:
	if act.is_empty():
		return
	var n = act["node"]
	if not is_instance_valid(n) or not all().has(String(act["id"])):
		_act_end("")
		return
	act["t"] = float(act["t"]) + dt
	var pp = Game.player.global_position
	match String(act["stage"]):
		"go":
			# yanında yürür; geride kalırsa (yavaş yürür) arkana yetişir
			var side = Game.player.face_dir().cross(Vector3.UP) * 1.6
			n.goal = pp + side - Game.player.face_dir() * 1.2
			if n.global_position.distance_to(pp) > 16.0 and Interiors.inst and Interiors.inst.inside == "":
				var q = pp - Game.player.face_dir() * 5.0 + side
				q.y = Game.ground_height(q.x, q.z)
				n.global_position = q
				n.home = q
			if pp.distance_to(act["dest"]["pos"]) < 5.5:
				act["stage"] = "scene"
				act["t"] = 0.0
				_act_arrive()
			elif float(act["t"]) > 600.0 or pp.distance_to(n.global_position) > 300.0:
				_act_end("%s: \"Sen gelmedin... Başka zaman o zaman.\"" % all()[String(act["id"])]["name"])
		"spar":
			var e = act.get("e")
			var won = e == null or not is_instance_valid(e) or e.is_dead() or e.hp < e.max_hp * 0.25
			var lost = Game.player.hp < Game.player.max_hp * 0.3
			if won or lost or float(act["t"]) > 180.0:
				_spar_end(won and not lost)


func _act_arrive() -> void:
	var id = String(act["id"])
	var f: Dictionary = all()[id]
	var n = act["node"]
	var d: Dictionary = act["dest"]
	Game.profile.erase("waypoint")
	match String(act["kind"]):
		"meal", "date":
			if int(pr().get("ryo", 0)) < 150 and act["kind"] == "meal":
				_act_end("Kesende para kalmamış...")
				return
			if String(d["type"]) == "enter":
				# iç mekâna birlikte girilir; dost karşına oturur
				await Interiors.inst.enter(d["it"])
				await get_tree().create_timer(0.6).timeout
				if act.is_empty():
					return
				n = _spawn_npc(id, Game.player.global_position, false)
				n.remove_meta("friend_id")
				if is_instance_valid(act["node"]):
					act["node"].queue_free()
				act["node"] = n
				var fw = Vector3(0, 0, -1)
				n.reparent(Interiors.inst.room)
				n.global_position = Game.player.global_position + fw * 1.6
				Interiors.inst.npcs.append(n)
			elif String(d["type"]) == "ramen":
				var seats: Array = d["it"].get("seats", [])
				Progress._sit_at(seats)
				var my: Vector3 = Game.player.global_position
				var other = my + Vector3(0.9, 0, 0)
				for q in seats:
					if q.distance_to(my) > 0.5 and q.distance_to(my) < other.distance_to(my) + 0.5:
						other = q
				n.global_position = other
			else:
				n.global_position = Game.player.global_position + Game.player.face_dir() * 1.5
			n.home = n.global_position
			n.goal = n.global_position
			n.wander_r = 0.0
			n.wait = 30.0
			# oturur: tezgâhta tezgâha (oyuncuyla aynı yöne), masada karşına bakar; arada konuşur
			n.role = "customer"
			n.eat_mode = true
			n.fixed_face = true
			var to_p = Game.player.global_position - n.global_position
			n.facing = Game.player.facing if String(d["type"]) == "ramen" else atan2(-to_p.x, -to_p.z)
			n.stand_face = n.facing
			if n.model:
				n.model.rotation.y = n.facing
				n.model.play("sit", 0.2)
			Game.player.model.play("sit", 0.2)
			Game.player.input_locked = 13.0
			var date = act["kind"] == "date"
			var topic = String(f.get("news", "")) if String(f.get("news", "")) != "" else ["Geçen gün görevde öyle bir şey oldu ki...", "Akademideyken hep birinci olmak isterdim, biliyor musun?", "Bazen her şeyi bırakıp gezmek istiyorum."].pick_random()
			var seq = [[0.6, "İtadakimasu!"], [3.4, topic], [7.4, "Sen ne yapıyorsun bu aralar? Anlatsana." if not date else "Seninle böyle oturmak... iyi geliyor."],
				[10.6, "Bir dahakine ben ısmarlarım, söz!" if not date else "Bugün çok güzeldi."]]
			for s in seq:
				var tt = float(s[0])
				var txt = String(s[1])
				get_tree().create_timer(tt).timeout.connect(func():
					if not act.is_empty() and is_instance_valid(act["node"]):
						act["node"].say(txt, 3.2))
			get_tree().create_timer(3.0).timeout.connect(func():
				if Game.player:
					Game.player.hp = Game.player.max_hp
					Game.player.chakra = Game.player.max_chakra
					Hud.msg("Sıcak yemek... Can ve chakra doldu.", Color(1, 0.85, 0.55)))
			await get_tree().create_timer(13.0).timeout
			if act.is_empty():
				return
			f["last_meal" if not date else "last_walk"] = Time.get_unix_time_from_system()
			if not date:
				Progress.add_ryo(-150)
				add_bond(id, 4)
			else:
				f["love"] = mini(100, int(f.get("love", 0)) + 8)
				add_bond(id, 3, true)
				Hud.msg("Gönül +8 (%d/100)" % f["love"], Color(1, 0.6, 0.75))
			log_event(f, "Birlikte yemek yediniz" if not date else "Randevuya çıktınız")
			_act_end("")
		"walk":
			n.goal = n.global_position
			n.wait = 20.0
			Game.player.input_locked = 9.0
			var seq2 = [[0.5, "Buradan köy bambaşka görünüyor..."], [3.6, "Yıldızlara bak. Çocukken onları sayardım."], [6.8, "Seninle yürümek iyi geldi."]]
			for s in seq2:
				var txt2 = String(s[1])
				get_tree().create_timer(float(s[0])).timeout.connect(func():
					if not act.is_empty() and is_instance_valid(act["node"]):
						act["node"].say(txt2, 3.0))
			await get_tree().create_timer(9.5).timeout
			if act.is_empty():
				return
			f["last_walk"] = Time.get_unix_time_from_system()
			f["love"] = mini(100, int(f.get("love", 0)) + 10)
			Hud.msg("Gönül +10 (%d/100)" % f["love"], Color(1, 0.6, 0.75))
			log_event(f, "Gece birlikte yürüdünüz")
			_flirt_stage(id)
			_act_end("")
		"train":
			n.say("Hazır mısın? Gardını al — ama abartma, dostça!", 3.0)
			await get_tree().create_timer(2.5).timeout
			if act.is_empty() or not is_instance_valid(n):
				return
			var a = arch(f)
			a["xp"] = 0
			a["ryo"] = 0
			a["respawn"] = false
			a["power"] = float(a.get("power", 1.0)) * 0.8
			a["name"] = "%s (idman)" % f["name"]
			var e = Enemy.new()
			e.setup(a)
			e.set_meta("spar", true)
			get_tree().current_scene.add_child(e)
			e.global_position = n.global_position
			e.home = n.global_position
			e.target = Game.player
			n.visible = false
			act["e"] = e
			act["stage"] = "spar"
			act["t"] = 0.0
			Hud.banner("İDMAN MAÇI", "%s ile dostça dövüş — %%25 cana inen kaybeder" % f["name"], Color(0.9, 0.85, 0.55))


func _spar_end(won: bool) -> void:
	var id = String(act["id"])
	var f: Dictionary = all()[id]
	var e = act.get("e")
	var n = act["node"]
	if is_instance_valid(e):
		FX.smoke_puff(e.global_position + Vector3.UP, 0.7, 8)
		if is_instance_valid(n):
			n.global_position = e.global_position
		e.queue_free()
	if is_instance_valid(n):
		n.visible = true
		n.say("Pes ediyorum! Gelişmişsin." if won else "Hah! Bu sefer ben kazandım. Bir dahakine!", 3.5)
	Game.player.hp = maxf(Game.player.hp, Game.player.max_hp * 0.3)
	var lv = int(pr().get("level", 1))
	Progress.add_xp(25 + lv * 6 + (10 if won else 0))
	f["last_train"] = Time.get_unix_time_from_system()
	add_bond(id, 3 if TRAITS.get(String(f.get("trait", "")), {}).get("like", []).has("antrenman") else 2)
	log_event(f, "Antrenman alanında idman yaptınız (%s)" % ("sen kazandın" if won else "o kazandı"))
	act["stage"] = "done"
	await get_tree().create_timer(4.0).timeout
	_act_end("")


func _act_end(msg: String) -> void:
	if act.is_empty():
		return
	var n = act.get("node")
	var orig = act.get("orig")
	if msg != "":
		Hud.msg(msg, Color(0.9, 0.85, 0.7))
	if is_instance_valid(n):
		if n.has_method("vanish") and n.is_inside_tree() and (Interiors.inst == null or not Interiors.inst.npcs.has(n)):
			n.vanish()
		elif not (Interiors.inst and Interiors.inst.npcs.has(n)):
			n.queue_free()
	if is_instance_valid(orig):
		orig.visible = true
		orig.add_to_group("talkers")
	if Game.player:
		Game.player.input_locked = 0.0
	act = {}


## ---------------------------------------------------------------- ölüm, cenaze, mezarlık
## Dost ölünce ~4 dk sonra köyünün mezarlığında cenaze töreni; gelirsen tören oynar (rahip, aile, yas tutanlar, son sözler).
## Tören bitince ya da 40 dk geçince defnedilir: İlişkiler listesinden düşer, mezar taşında adı kalır.
const EPITAPHS := ["Ateşin İradesi onda yaşadı", "Son nefesine kadar savaştı", "Arkadaşlarını korurken düştü", "Huzur içinde uyu", "Gölgesi köyü korumaya devam ediyor"]
var graves := {}       # köy -> Graveyard düğümü
var funeral := {}      # süren tören


static func listed() -> Dictionary:
	var out = {}
	for id in all():
		if not all()[id].get("buried", false):
			out[id] = all()[id]
	return out


func _funeral_tick() -> void:
	var now = Time.get_unix_time_from_system()
	var pp = Game.player.global_position
	for id in all():
		var f: Dictionary = all()[id]
		if String(f.get("status", "")) != "öldü" or f.get("buried", false):
			continue
		if not f.has("died_t"):
			f["died_t"] = now
			f["funeral_t"] = now + 240.0
			f["epitaph"] = EPITAPHS.pick_random()
			var vn = Game.village(String(f.get("village", Progress.home()))).get("name", "Köy")
			if int(f.get("bond", 0)) >= 0:
				# ulak seni törene çağırır (isteğe bağlı)
				var gp = Graveyard.pos_of(String(f.get("village", Progress.home())))
				var nm = String(f["name"])
				Hud.dialog("Ulak", "%s hayatını kaybetti... Cenaze töreni birkaç dakika sonra %s mezarlığında. %s da konuşma yapacak. Ailesi seni de orada görmek istiyor." % [nm, vn, Kage.kage_name(String(f.get("village", Progress.home())))], [
					{"label": "Katılacağım", "cb": func():
						Game.profile["waypoint"] = [gp.x, gp.y, gp.z, "Cenaze: %s" % nm]
						Game.profile["track"] = "waypoint"
						Hud.msg("Mezarlık haritada işaretlendi.", Color(0.85, 0.85, 0.95))},
					{"label": "Katılamam", "cb": func(): Hud.msg("Tören sensiz yapılacak.", Color(0.8, 0.8, 0.85))}])
		elif funeral.is_empty() and now >= float(f.get("funeral_t", 0.0)):
			var gp2 = Graveyard.pos_of(String(f.get("village", Progress.home())))
			if gp2 != Vector3.INF and pp.distance_to(gp2) < 40.0:
				_start_funeral(id)
			elif now > float(f["died_t"]) + 2400.0:
				_bury(id, false)


## Yakındaki köylerin mezarlıkları kurulur / uzaktakiler kaldırılır (dostun olmasa da her köyde)
func _graves_tick() -> void:
	var pp = Game.player.global_position
	for v in Game.world_info.get("villages", []):
		var vid = String(v["id"])
		var near = Game.to_map(pp).distance_to(Vector2(float(v["x"]), float(v["y"]))) < float(v["r"]) + 600.0
		if near and not graves.has(vid):
			var g = Graveyard.new()
			get_tree().current_scene.add_child(g)
			g.build(vid)
			graves[vid] = g
		elif not near and graves.has(vid):
			if is_instance_valid(graves[vid]):
				graves[vid].queue_free()
			graves.erase(vid)


func _rebuild_grave(vid: String) -> void:
	if graves.has(vid) and is_instance_valid(graves[vid]):
		graves[vid].queue_free()
	graves.erase(vid)   # bir sonraki tikte adlı taşla yeniden kurulur


func _bury(id: String, attended: bool) -> void:
	var f: Dictionary = all()[id]
	f["buried"] = true
	f["party"] = false
	log_event(f, "Köyün mezarlığına defnedildi" + (" (törene katıldın)" if attended else ""))
	if Game.profile.has("waypoint") and String(Game.profile["waypoint"][3]).begins_with("Cenaze"):
		Game.profile.erase("waypoint")
	_rebuild_grave(String(f.get("village", Progress.home())))


func _start_funeral(id: String) -> void:
	var f: Dictionary = all()[id]
	var vid = String(f.get("village", Progress.home()))
	var gp = Graveyard.pos_of(vid)
	var people = []
	var monk = Villager.new()
	monk.role = "guard"
	monk.display_override = "Rahip"
	monk.look_extra = {"top_style": "kimono", "top": Color(0.85, 0.82, 0.75), "top2": Color(0.3, 0.28, 0.25), "pants": Color(0.3, 0.28, 0.25), "pants_style": "sivil",
		"hair_style": "kase", "hair": Color(0.1, 0.1, 0.1), "age": "adult", "gender": "m", "vest": null, "band": null}
	people.append([monk, Vector3(0, 0, -4.0), "Rahip"])
	# köyün Kage'si de gelir ve konuşur
	var kg = Villager.new()
	kg.role = "guard"
	kg.display_override = Kage.kage_name(vid)
	kg.look_extra = KageAttire.look(vid)
	kg.look_extra["village"] = vid
	people.append([kg, Vector3(2.2, 0, -3.6), "Kage"])
	var mourners = []
	for m in f.get("family", []):
		if m.get("alive", true) and String(m["rel"]) in ["Babası", "Annesi", "Karısı", "Kocası", "Oğlu", "Kızı"]:
			mourners.append([String(m["name"]), String(m["rel"])])
	while mourners.size() < 4:
		mourners.append(["%s %s" % [Missions.BB_FAMILY.pick_random(), ClanWorld.GIVEN_M.pick_random()], "Silah arkadaşı"])
	for i in mourners.size():
		var v = Villager.new()
		v.role = "guard"
		v.display_override = mourners[i][0]
		var fem = String(mourners[i][1]) in ["Annesi", "Karısı", "Kızı"]
		v.look_extra = {"top": Color(0.08, 0.08, 0.1), "top2": Color(0.08, 0.08, 0.1), "pants": Color(0.08, 0.08, 0.1), "top_style": "kimono" if fem else "uzun",
			"pants_style": "sivil", "gender": "f" if fem else "m", "vest": null, "age": "adult"}
		people.append([v, Vector3(-3.0 + i * 1.6, 0, 1.2 + (i % 2) * 0.8), mourners[i][0]])
	# köyün diğer ninjaları arka sıralarda: önce aynı köyden hayattaki dostların, kalanı köy üniformalı ninjalar
	var guests = []
	for oid in all():
		var o: Dictionary = all()[oid]
		if oid != id and String(o.get("status", "")) == "" and String(o.get("village", "")) == vid and not o.get("party", false) and available(o):
			guests.append([String(o["name"]), look_of(o)])
	guests.shuffle()
	guests = guests.slice(0, 4)
	while guests.size() < 7:
		var lk = Outfits.roll(["chunin", "chunin", "jonin"].pick_random(), vid)
		lk["gender"] = ["m", "m", "f"].pick_random()
		lk["age"] = "adult"
		guests.append(["%s ninjası" % String(Game.village(vid).get("name", "Köy")), lk])
	for i in guests.size():
		var gv = Villager.new()
		gv.role = "guard"
		gv.display_override = String(guests[i][0])
		gv.look_extra = guests[i][1]
		people.append([gv, Vector3(-4.5 + (i % 4) * 3.0 + (1.5 if i >= 4 else 0.0), 0, 4.2 + int(i / 4) * 1.6), guests[i][0]])
	for pz in people:
		var n = pz[0]
		get_tree().current_scene.add_child(n)
		if pz[2] == "Kage":
			KageAttire.hat(n.model, vid)
		var q = gp + pz[1]
		q.y = Game.ground_height(q.x, q.z)
		n.global_position = q
		n.home = q
		n.goal = q
		n.wander_r = 0.0
		n.fixed_face = true
		var to = (gp + Vector3(0, 0, 3.6)) - q
		n.facing = atan2(-to.x, -to.z) if to.length() > 0.5 else 0.0
		n.stand_face = n.facing
	funeral = {"id": id, "people": people.map(func(x): return x[0])}
	Hud.banner("CENAZE TÖRENİ", "%s son yolculuğuna uğurlanıyor" % f["name"], Color(0.8, 0.8, 0.9))
	var first_rel = mourners[0]
	var seq = [[0.5, monk, "Bugün %s'i uğurluyoruz. Köyü için yaşadı, köyü için düştü." % f["name"]],
		[4.5, kg, "%s bu köyün bir ninjasıydı. Onun fedakârlığı sayesinde çocuklarımız bu gece güvende uyuyacak." % f["name"]],
		[9.0, kg, "Onun iradesini taşımak bizim borcumuz. Köy onu asla unutmayacak."],
		[13.0, people[2][0], "%s... Seni hep yanımda sanırdım." % String(f["name"]).split(" ")[-1] if first_rel[1] != "Silah arkadaşı" else "Son görevinde yanında olmak isterdim."],
		[17.0, people[3][0], "Onun bıraktığı yeri biz dolduracağız."],
		[21.0, monk, "Ateşin İradesi onu taşıyanla ölmez. Huzur içinde uyu."]]
	for s in seq:
		var who = s[1]
		var txt = String(s[2])
		get_tree().create_timer(float(s[0])).timeout.connect(func():
			if is_instance_valid(who):
				who.say(txt, 4.0))
	get_tree().create_timer(25.0).timeout.connect(func():
		Hud.dialog("Cenaze — %s" % f["name"], "Herkes sessizce sırasını bekliyor. Sıra sana geldi.", [
			{"label": "Tütsü yak", "cb": func(): _end_funeral(id, "Mezarına tütsü yaktın")},
			{"label": "Son sözlerini söyle: \"Seni unutmayacağım.\"", "cb": func(): _end_funeral(id, "Mezarı başında ona söz verdin")},
			{"label": "Sessizce dua et", "cb": func(): _end_funeral(id, "Mezarı başında dua ettin")}]))


func _end_funeral(id: String, what: String) -> void:
	var f: Dictionary = all()[id]
	log_event(f, what)
	Hud.msg("Tören sona erdi. %s artık köyün mezarlığında yatıyor." % f["name"], Color(0.85, 0.85, 0.95), 6.0)
	var people: Array = funeral.get("people", [])
	funeral = {}
	_bury(id, true)
	get_tree().create_timer(12.0).timeout.connect(func():
		for n in people:
			if is_instance_valid(n):
				if n.has_method("vanish"):
					n.vanish()
				else:
					n.queue_free())


## Yaralanma: takımdan düşer, hastanede yatar (bir süre köyde değil)
const INJURIES := ["kolu kırıldı", "kaburgaları çatladı", "ağır yanık", "zehirlendi", "chakra tükenmesi", "derin kılıç yarası", "bacağı kırıldı"]


static func injure(id: String, why: String) -> void:
	var f: Dictionary = all()[id]
	var mins = randf_range(12.0, 30.0)
	f["away"] = Time.get_unix_time_from_system() + mins * 60.0
	f["injury"] = INJURIES.pick_random()
	f["inj_away"] = f["away"]
	f["party"] = false
	log_event(f, "%s (%s), hastaneye kaldırıldı" % [why, f["injury"]])
	Hud.banner("%s YARALANDI" % String(f["name"]).to_upper(), "%s — hastanede ~%d dk yatacak." % [String(f["injury"]).capitalize(), int(mins)], Color(1, 0.7, 0.45))


static func party_max() -> int:
	return 3 if pr().get("sensei", false) else PARTY_MAX


## ---------------------------------------------------------------- akademi döngüsü: mezuniyet, büyüyen çocuklar, öğretmenlik
const GRAD_EVERY := 1800.0    # ~30 dk oyunda bir mezuniyet
const CHILD_GROW := 5400.0    # çocuklar ~1.5 saatte akademi çağına gelir
const HAIRS := [Color(0.1, 0.1, 0.12), Color(0.35, 0.22, 0.12), Color(0.85, 0.7, 0.35), Color(0.75, 0.35, 0.2), Color(0.2, 0.25, 0.45), Color(0.6, 0.6, 0.62), Color(0.9, 0.55, 0.65)]
var _grad_nodes := {}
var _gt := 0.0


static func grads() -> Array:
	if not pr().has("grads"):
		pr()["grads"] = []
	return pr()["grads"]


func _grad_tick(dt: float) -> void:
	var p = pr()
	p["grad_t"] = float(p.get("grad_t", GRAD_EVERY * 0.4)) - dt
	if float(p["grad_t"]) <= 0.0:
		if Missions.active().is_empty() and not Game.ui_open:
			p["grad_t"] = GRAD_EVERY * randf_range(0.8, 1.3)
			graduation()
		else:
			p["grad_t"] = 60.0
	_gt -= dt
	if _gt > 0.0:
		return
	_gt = 1.0
	_graves_tick()
	# mezunlar akademi avlusunda: yaklaşınca belirir, uzaklaşınca gider
	var now = Time.get_unix_time_from_system()
	var gl = grads()
	gl.assign(gl.filter(func(g): return now < float(g.get("until", 0.0))))
	var ac = Exams.find_point(["academy"])
	var pp = Game.player.global_position
	var near = ac != Vector3.ZERO and ac.distance_to(pp) < 90.0
	for gid in _grad_nodes.keys():
		var n = _grad_nodes[gid]
		if not is_instance_valid(n) or not near or n.has_meta("friend_id"):
			if is_instance_valid(n) and not near:
				n.queue_free()
			_grad_nodes.erase(gid)
	if not near:
		return
	# kapının önünde (geldiğin tarafta) yarım çember: binanın içine/arkasına düşmesinler
	var out = pp - ac
	out.y = 0.0
	out = out.normalized() if out.length() > 0.5 else Vector3.BACK
	var sd = out.cross(Vector3.UP)
	var i = 0
	for g in gl:
		i += 1
		if _grad_nodes.has(g["gid"]):
			continue
		var k = float(i) - (gl.size() + 1) * 0.5
		_grad_nodes[g["gid"]] = _spawn_grad(g, ac + out * (6.0 + absf(k) * 0.8) + sd * k * 2.2)


static func _new_grad(vid: String, female: bool, clan: String, nm: String) -> Dictionary:
	if clan == "" and nm == "" and randf() < 0.45:
		var cs = ClanWorld._clans_of(vid)
		if not cs.is_empty():
			clan = String(cs.pick_random())
	if nm == "":
		nm = ClanWorld.person_name(clan, female) if clan != "" else "%s %s" % [Missions.BB_FAMILY.pick_random(), (ClanWorld.GIVEN_F if female else ClanWorld.GIVEN_M).pick_random()]
	var lk = ClanWorld.clan_look(clan, "genin", vid, female, "teen")
	if clan == "":
		lk["hair"] = HAIRS.pick_random()
		lk["hair_style"] = CharacterModel.HAIR_STYLES.keys().pick_random()
	return {"gid": "g%d" % randi(), "name": nm, "female": female, "clan": clan, "look": _ser(lk), "village": vid,
		"until": Time.get_unix_time_from_system() + 3600.0, "parent": "", "parent_id": ""}


## Mezuniyet töreni: rastgele yeni geninler + büyüyen çocuklar (seninkiler ve dostlarınınkiler)
func graduation() -> void:
	var vid = Progress.home()
	var now = Time.get_unix_time_from_system()
	var gl = grads()
	var names = []
	var cohort = []
	for kid in pr().get("children", []):
		if not kid.get("grad", false) and now - float(kid.get("born", now)) >= CHILD_GROW:
			kid["grad"] = true
			var fem = String(kid.get("gender", "m")) == "f"
			var cl: Array = kid.get("clans", [])
			var lk = ClanWorld.clan_look(String(cl[0]) if not cl.is_empty() else "", "genin", vid, fem, "teen")
			if randf() < 0.5:
				lk["hair"] = pr().get("look", {}).get("hair", lk["hair"])
			var id = _make_friend(String(kid["name"]), String(cl[0]) if not cl.is_empty() else "", lk, 80, "Senin %s" % ("kızın" if fem else "oğlun"))
			all()[id]["loyalty"] = 95
			all()[id]["family"] = [{"rel": "Ebeveyni", "name": "%s (sen)" % pr().get("name", ""), "alive": true}]
			log_event(all()[id], "Akademiden mezun oldu! Alın koruyucusunu sana gösterdi")
			names.append("%s (senin %s)" % [kid["name"], "kızın" if fem else "oğlun"])
	for id in all():
		var f: Dictionary = all()[id]
		for m in f.get("family", []):
			if String(m["rel"]) in ["Oğlu", "Kızı"] and m.get("alive", true) and not m.get("grad", false) \
					and now - float(m.get("born", now - CHILD_GROW)) >= CHILD_GROW and randf() < 0.5:
				m["grad"] = true
				var g = _new_grad(vid, m["rel"] == "Kızı", String(f.get("clan", "")), String(m["name"]))
				g["parent"] = "%s'in %s" % [f["name"], "kızı" if m["rel"] == "Kızı" else "oğlu"]
				g["parent_id"] = id
				gl.append(g)
				cohort.append(g)
				names.append("%s (%s)" % [g["name"], g["parent"]])
				log_event(f, "%s akademiden mezun oldu" % m["name"])
	for k in randi_range(2, 4):
		var g = _new_grad(vid, randf() < 0.5, "", "")
		gl.append(g)
		cohort.append(g)
		names.append(g["name"])
	var teach = pr().get("teacher", false) and int(pr().get("lessons", 0)) > 0
	for g in cohort:
		g["student"] = teach
	Hud.banner("AKADEMİ MEZUNİYETİ", "%d yeni genin alın koruyucusunu taktı. Bir saat boyunca akademi avlusundalar." % names.size(), Color(0.7, 0.9, 1.0))
	Hud.msg("Mezunlar: " + ", ".join(names.slice(0, 6)), Color(0.75, 0.9, 1.0), 8.0)
	if teach:
		pr()["lessons"] = 0
		Progress.add_ryo(250 * cohort.size())
		Missions._rep(vid, 5)
		Hud.msg("Ders verdiğin öğrenciler mezun oldu (+%d Ryō, +5 itibar). Seni hocaları olarak tanıyorlar." % (250 * cohort.size()), Color(0.7, 0.9, 1.0), 6.0)
	# Jōnin: isteğe bağlı genin takımı hocalığı
	if int(pr().get("rank", 0)) >= 3 and not pr().get("sensei", false) and cohort.size() >= 3:
		var team = cohort.slice(0, 3)
		Hud.dialog(Progress.home_info()["kage"], "Bu dönemin mezunlarından üçü bir jōnin hocaya ihtiyaç duyuyor: %s. Takımı sen alır mısın? (İsteğe bağlı; görevlerine seninle çıkarlar, büyüdükçe rütbe atlarlar.)" % ", ".join(team.map(func(g): return g["name"])), [
			{"label": "Takımı al (Jōnin hocası ol)", "cb": func(): _take_team(team)},
			{"label": "Şimdi değil", "cb": func(): pass}])


## Jōnin hocalığı: 3 genin öğrencin olur (dost listesine girer, takım sınırı 3)
static func _take_team(team: Array) -> void:
	pr()["sensei"] = true
	var nm = []
	for g in team:
		var sid = _make_friend(String(g["name"]), String(g["clan"]), look_of(g), 45, "Öğrencin")
		all()[sid]["student"] = true
		all()[sid]["family"] = _family(String(g["clan"]), bool(g["female"]), 0)
		log_event(all()[sid], "Senin genin takımına verildi")
		grads().erase(g)
		nm.append(g["name"])
	Hud.banner("JŌNİN HOCASI", "Genin takımın: %s. Takım sınırın 3 kişiye çıktı." % ", ".join(nm), Color(0.7, 0.9, 1.0))


## Kage'den istediğin zaman öğretmenlik görevi (isteğe bağlı): Chūnin -> akademi, Jōnin -> genin takımı
static func _kage_teach_opts() -> Array:
	var rk = int(pr().get("rank", 0))
	if rk < 2:
		return []
	var kt = Progress.home_info()["kage"]
	var opts = []
	if not pr().get("teacher", false):
		opts.append({"label": "Akademide öğretmenlik görevi istiyorum", "cb": func():
			pr()["teacher"] = true
			var ac = Exams.find_point(["academy"])
			Game.profile["waypoint"] = [ac.x, ac.y, ac.z, "Akademi (ders ver)"]
			Game.profile["track"] = "waypoint"
			Hud.dialog(kt, "Akademi senin gibi birine muhtaç. Sınıfa git, hocayla konuşup ders ver. Ders verdiğin dönem mezun olunca öğrencilerin olurlar.", [])})
	else:
		opts.append({"label": "Akademi öğretmenliğini bırakmak istiyorum", "cb": func():
			pr()["teacher"] = false
			Hud.dialog(kt, "Anlaşıldı. Sahada sana daha çok ihtiyaç var zaten.", [])})
	if rk >= 3:
		if not pr().get("sensei", false):
			opts.append({"label": "Bir genin takımı istiyorum (Jōnin hocası)", "cb": func():
				var team = grads().filter(func(g): return true).slice(0, 3)
				while team.size() < 3:
					team.append(_new_grad(Progress.home(), randf() < 0.5, "", ""))
				Hud.dialog(kt, "Akademinin son mezunlarından üçü hâlâ hocasız. Onlar artık senin sorumluluğunda.", [])
				_take_team(team)})
		else:
			opts.append({"label": "Genin takımımı bırakmak istiyorum", "cb": func():
				pr()["sensei"] = false
				for id in party_ids():
					if party_ids().size() > PARTY_MAX:
						all()[id]["party"] = false
				Hud.dialog(kt, "Öğrencilerin seni unutmayacak. Yine de görüşmeye devam edersiniz.", [])})
	return opts


static func _make_friend(nm: String, clan: String, lk: Dictionary, bond: int, title: String) -> String:
	var id = "f%d" % (int(pr().get("friend_seq", 0)) + 1)
	pr()["friend_seq"] = int(pr().get("friend_seq", 0)) + 1
	var l2 = lk.duplicate()
	l2.erase("age")
	all()[id] = {"name": nm, "role": "nurse", "ninja": true, "look": _ser(l2), "bond": bond, "village": Progress.home(), "party": false,
		"last_talk": 0.0, "element": ELS.pick_random(), "clan": clan, "eye": [0, 0], "rank": 0, "family": [], "status": "", "log": [], "news": "",
		"title": title}
	return id


func _spawn_grad(g: Dictionary, at: Vector3) -> Villager:
	var vg: Villager
	if String(g["clan"]) != "":
		var r = ClanResident.new()
		r.clan = String(g["clan"])
		r.vid = String(g["village"])
		r.given = String(g["name"])
		vg = r
	else:
		vg = Villager.new()
	vg.role = "nurse"
	vg.look_extra = look_of(g)
	vg.display_override = String(g["name"])
	vg.set_meta("grad_id", g["gid"])
	get_parent().add_child(vg)
	var q = Missions.open_ground(at, 4.0)
	vg.global_position = q
	vg.home = q
	vg.goal = q
	vg.wander_r = 4.0
	if vg.has_method("set_name_tag"):
		vg.set_name_tag("%s\n%s" % [g["name"], "Öğrencin • Yeni Genin" if g.get("student", false) else ("Yeni Genin" if g["parent"] == "" else g["parent"])], Color(0.7, 0.9, 1.0))
	return vg


static func _meet_grad(v: Node) -> void:
	var gid = String(v.get_meta("grad_id"))
	var g = {}
	for x in grads():
		if x["gid"] == gid:
			g = x
	if g.is_empty():
		return
	v.remove_meta("grad_id")
	_meet(v, String(g["name"]))
	var id = String(v.get_meta("friend_id", ""))
	if id == "":
		return
	var f: Dictionary = all()[id]
	f["rank"] = 0
	f["title"] = "Yeni mezun"
	if String(g["clan"]) != "":
		f["title"] = "%s klanı" % ClanWorld.clan_name(String(g["clan"]))
	if String(g.get("parent_id", "")) != "" and all().has(g["parent_id"]):
		var pf: Dictionary = all()[g["parent_id"]]
		f["family"] = [{"rel": "Annesi" if String(pf["look"].get("gender", "m")) == "f" else "Babası", "name": pf["name"], "alive": String(pf.get("status", "")) != "öldü"}]
		f["bond"] = maxi(int(f["bond"]), int(int(pf["bond"]) / 3))   # anne/babasıyla aran ona da yansır
	if g.get("student", false):
		f["student"] = true
		f["title"] = "Öğrencin"
		f["bond"] = maxi(int(f["bond"]), 30)
	grads().erase(g)
	tag(v)


## Akademi öğretmenliği (Chūnin+, isteğe bağlı): ders ver -> Ryō, itibar; ders verdiğin dönem mezun olunca öğrencilerin olur
static func _teacher_opts() -> Array:
	if int(pr().get("rank", 0)) < 2:
		return []
	var opts = []
	if not pr().get("teacher", false):
		opts.append({"label": "Akademide öğretmenlik yapmak istiyorum", "cb": func():
			pr()["teacher"] = true
			Hud.dialog("Akademi", "Bir chūnin'in ders vermesi çocuklara çok iyi gelir! Ders verdikçe sınıfın seni tanır; mezun olduklarında senin öğrencilerin olurlar.", [])
			Hud.banner("AKADEMİ ÖĞRETMENİ", "İstediğin zaman ders verebilir ya da bırakabilirsin.", Color(0.7, 0.9, 1.0))})
		return opts
	var left = 900.0 - (Time.get_unix_time_from_system() - float(pr().get("last_lesson", 0.0)))
	if left <= 0.0:
		for ls in [["Taijutsu dersi ver", "Çocuklarla temel duruşları ve yumruk serilerini çalıştın."], ["Ninjutsu dersi ver", "Mühür dizilerini ve Bunshin'i anlattın; biri ilk kez başardı!"], ["Strateji dersi ver", "Shōgi tahtasında pusu kurmayı ve geri çekilmeyi gösterdin."]]:
			var txt = String(ls[1])
			opts.append({"label": ls[0], "cb": func():
				pr()["last_lesson"] = Time.get_unix_time_from_system()
				pr()["lessons"] = int(pr().get("lessons", 0)) + 1
				var pay = 150 + int(pr().get("rank", 2)) * 100
				Progress.add_ryo(pay)
				Progress.add_xp(40 + int(pr().get("level", 1)) * 3)
				Missions._rep(Progress.home(), 2)
				Hud.dialog("Sınıf", txt + " Bu dönemin öğrencileri mezun olunca seni hocaları olarak anacak.", [])
				Hud.msg("Ders verildi: +%d Ryō, +2 itibar" % pay, Color(0.7, 0.9, 1.0))})
	else:
		opts.append({"label": "Ders ver (sonraki ders %d dk sonra)" % ceili(left / 60.0), "cb": func(): Hud.msg("Çocuklar teneffüste. Biraz sonra gel.", Color(0.8, 0.85, 1.0))})
	opts.append({"label": "Öğretmenliği bırak", "cb": func():
		pr()["teacher"] = false
		Hud.msg("Akademi öğretmenliğini bıraktın.", Color(0.8, 0.85, 1.0))})
	return opts


static func on_kill() -> void:
	var p = Game.profile
	p["fr_kills"] = int(p.get("fr_kills", 0)) + 1
	if int(p["fr_kills"]) % 5 == 0:
		for id in party_ids():
			add_bond(id, 1, true)


func _process(dt: float) -> void:
	if Game.paused:
		return
	if _active():
		_grad_tick(dt)
		_act_tick(dt)
	if _active() and not all().is_empty():
		_baby_tick()
		_world_tick(dt)
		life_t -= dt
		if life_t <= 0.0:
			life_t = randf_range(240.0, 480.0)
			_life_event()
	t -= dt
	if t > 0.0:
		return
	t = 0.4
	var ids = party_ids() if _party_ok() else []
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
				q.y = Game.jutsu_floor(q.x, q.z)   # mağarada oda zemini (arazi 1500 m aşağıda)
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
				injure(m["id"], "savaşta ağır yaralandı")
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
