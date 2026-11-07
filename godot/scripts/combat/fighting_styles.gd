class_name FightingStyles
extends RefCounted
## Dövüş tarzları: silahsızken düz vuruş kombosu klan/yol/bijūya göre değişir (KeyedCombos anahtar kombosu "style_<id>").
## Oyuncu Ustalık sekmesinde ◀ ▶ ile seçer (profile "fight_style"); düşman/NPC klanının tarzıyla dövüşür (aynı kombo, aynı etkiler).
## Kaynak: "clan:<id>" (o klandan olmak), ileride "path:<id>" (yolda ilerlemek), "jin:<bijū>" (jinchūriki).

## range: "yakın" / "orta" / "uzak" (animeye göre); stop: düşmanın rakibe yanaştığı mesafe (uzakçı yanaşmaz, oradan atar)
const STYLES := {
	"juken": {"name": "Jūken — Yumuşak Yumruk", "key": "style_juken", "src": "clan:hyuga", "range": "yakın", "stop": 1.6,
		"desc": "Açık avuç darbeleri ve tenketsu dürtüşleri: hasarı orta, her isabet rakibin chakrasını tıkar; bitiriş Hakke Kūshō hava basıncı."},
	"akimichi": {"name": "Baika Kenpō — Akimichi", "key": "style_akimichi", "src": "clan:akimichi", "range": "yakın (uzun kol)", "stop": 2.4,
		"desc": "Ağır ve yavaş: vuruş anında yumruk/avuç devleşir (Bubun Baika, Chō Harite); menzil ve savurma büyük, kurulum uzun."},
	"inuzuka": {"name": "Shikyaku — Dört Ayak", "key": "style_inuzuka", "src": "clan:inuzuka", "range": "yakın", "stop": 1.6,
		"desc": "Çömelik vahşi pençe tırmıkları, atılış ve dönen pençe; bitiriş Gatsūga matkap hücumu. Hızlı, yakın."},
	"kaguya": {"name": "Shikotsumyaku Dansları — Kaguya", "key": "style_kaguya", "src": "clan:kaguya", "range": "yakın + kemik mermisi", "stop": 2.0,
		"desc": "Avuçtan çıkan kemik kılıç (Tsubaki), dikenli dönüş (Yanagi), parmak kemiği mermileri (Teshi Sendan), bedenden diken fışkırması (Karamatsu)."},
	"uchiha": {"name": "Uchiha-ryū — Shishi Rendan", "key": "style_uchiha", "src": "clan:uchiha", "range": "yakın + ateş", "stop": 1.8,
		"desc": "Sharingan ile okunan tekme kombosu: yan tekme, havaya kaldıran ön tekme, peşinden sıçrayış, topuk inişi; bitiriş mühür + ağızdan Katon seli."},
	"hozuki": {"name": "Suika — Hōzuki", "key": "style_hozuki", "src": "clan:hozuki", "range": "orta", "stop": 4.5,
		"desc": "Orta mesafe: parmaktan su mermisi (Mizudeppō), su kırbacı; yakına gelene suyla şişen dev kol (Gōsuiwan). Hasarı orta, menzili geniş."},
	"aburame": {"name": "Kikaichū — Aburame", "key": "style_aburame", "src": "clan:aburame", "range": "uzak", "stop": 8.0,
		"desc": "Uzaktan: yenlerden fırlayan böcek sürüleri, böcek sütunu, böcek küresi; isabette chakra emer. Yakın dövüşte zayıf, rakibe yanaşmaz."},
	"jugo": {"name": "Senninka — Jūgo", "key": "style_jugo", "src": "clan:jugo", "range": "yakın (ağır)", "stop": 1.8,
		"desc": "Kol taş gibi dev balyoza dönüşür; dirsekten buhar jetiyle atılan yumruklar, yere çakış, dikenli kol saplaması, jetli aparkat. Yavaş ama çok sert."},
	"yuki": {"name": "Hyōton — Yuki", "key": "style_yuki", "src": "clan:yuki", "range": "orta", "stop": 5.0,
		"desc": "Çevik, sekerek: parmak arasından buz iğneleri, yakında donduran buz avucu, takip eden buz kırlangıçları (Tsubame Fubuki); bitiriş rakibin çevresinde beliren bin iğne (Sensatsu Suishō)."},
	"sabaku": {"name": "Suna — Sabaku", "key": "style_sabaku", "src": "clan:sabaku", "range": "uzak", "stop": 7.0,
		"desc": "Kıpırdamazsın, kum dövüşür: yerden kum yumruğu, kum shurikenleri, kum dalgası, rakibi saran Sabaku Kyū ve avucu kapatınca sıkıştıran Sōsō. Yakında yavaş."},
	"uzumaki": {"name": "Kongō Fūsa — Uzumaki", "key": "style_uzumaki", "src": "clan:uzumaki", "range": "orta", "stop": 4.5,
		"desc": "Gövdeden çıkan chakra zincirleri: kırbaç, mızrak gibi saplanan zincir, rakibi sarıp chakrasını mühürleyen bağ, çevreyi süpüren zincirler; bitiriş zincirle kaldırıp yere çarpma."},
	"yotsuki": {"name": "Raiton Nintai — Yotsuki", "key": "style_yotsuki", "src": "clan:yotsuki", "range": "yakın (atılış)", "stop": 1.6,
		"desc": "Raiton Chakra zırhıyla ezici hız ve güç: şimşekli yumruk, omuz dalışı, Lariat, Raigyaku Suihei el kılıcı, seri şimşek yumruklar; bitiriş Liger Bomb (kavra, kaldır, yere çak)."},
	"kurosuki": {"name": "Raikō — Kurosuki", "key": "style_kurosuki", "src": "clan:kurosuki", "range": "yakın + gök şimşeği", "stop": 2.2,
		"desc": "Raiga'nın ailesi: şimşekli el kılıçları, sise karışıp yanında belirme, çapraz düz şimşek çizgileri (Kuroi Jūji), göğe kalkan elle hedefe yıldırım (Rakurai); bitiriş hedefin çevresine şimşek yağmuru (Ikazuchi no Utage). İsabetler kısa sersemletir."},
	"iburi": {"name": "Kemuri Kenpō — Iburi", "key": "style_iburi", "src": "clan:iburi", "range": "orta", "stop": 3.5,
		"desc": "Duman beden: kol dumana çözülüp uzanır ve katı yumrukla vurur, beden dağılıp rakibin arkasında belirir, dumandan bıçakla kesik, yüze üflenen oksitleyici duman içeriden yakar; bitiriş duman hortumu. Rüzgâra (Fūton) karşı zayıf."},
	"kamizuru": {"name": "Hachi Tsukai — Kamizuru", "key": "style_kamizuru", "src": "clan:kamizuru", "range": "orta-uzak", "stop": 6.5,
		"desc": "Arı ustası: yenden salınan eşek arıları zehirli iğne fırlatır (Hachi Senbon), bal arıları hedefte yapışkan bala patlar (Hachi Mitsu), başparmak-avuç mührüyle yerden arı sütunu, patlayıcı kâğıt taşıyan arılar (Hachi Bakudan); bitiriş sürü yelpazesi, zehir uyutur. Yakında zayıf."},
}


## Düşmanın bu tarzla yanaştığı mesafe (uzakçı yaklaşmaz)
static func stop_dist(key: String) -> float:
	for id in STYLES:
		if String(STYLES[id]["key"]) == key:
			return float(STYLES[id].get("stop", 1.6))
	return 1.6


static func is_ranged(key: String) -> bool:
	return stop_dist(key) >= 4.0


static func _has_src(p: Dictionary, src: String) -> bool:
	if src.begins_with("clan:"):
		# göz tarzı: nakledilmiş Byakugan Jūken'i, Sharingan Uchiha tarzını açar (klandan olmasan da — Kakashi gibi)
		if src == "clan:hyuga" and Progress.has_eye("byakugan"):
			return true
		if src == "clan:uchiha" and Progress.has_eye("sharingan"):
			return true
		return String(p.get("clan", "none")) == src.substr(5)
	if src.begins_with("path:"):
		return src.substr(5) in (p.get("paths", {}) as Dictionary) if p.get("paths") is Dictionary else false
	if src.begins_with("jin:"):
		return TailedBeasts.player_jinchuriki() == src.substr(4)
	return false


## Oyuncunun seçebileceği tarzlar ("" = temel taijutsu her zaman ilk)
static func available(p: Dictionary) -> Array:
	var out = [""]
	for id in STYLES:
		if _has_src(p, String(STYLES[id]["src"])):
			out.append(id)
	return out


static func name_of(id: String) -> String:
	return "Temel Taijutsu" if id == "" else String(STYLES.get(id, {}).get("name", id))


## Oyuncunun düz vuruş kombo anahtarı (silahsızken); seçili tarz artık uygun değilse temel
static func player_key(p: Dictionary) -> String:
	var sel = String(p.get("fight_style", ""))
	if sel == "" or not STYLES.has(sel) or not sel in available(p):
		return ""
	return String(STYLES[sel]["key"])


## NPC/düşman: klanının tarzı (oyuncuyla aynı kombo)
static func npc_key(clan: String) -> String:
	for id in STYLES:
		if String(STYLES[id]["src"]) == "clan:" + clan:
			return String(STYLES[id]["key"])
	return ""
