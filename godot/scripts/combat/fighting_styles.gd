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
	"yilan": {"name": "Sen'eijashu — Yılan", "key": "style_yilan", "src": "path:yilan", "range": "orta", "stop": 4.0,
		"desc": "Orochimaru'nun yolu: kolun yeninden fırlayıp ısıran ve sarıp bağlayan yılanlar (zehir), ağızdan uzayıp saplanan Kusanagi, esneyen bedenle yılan atılışı; bitiriş yerden fışkıran yılan sürüsü hedefi yutar (Mandara)."},
	"gama": {"name": "Gama Sennin — Kurbağa", "key": "style_gama", "src": "path:gama", "range": "yakın-orta", "stop": 3.0,
		"desc": "Jiraiya'nın yolu: saç iğneleri yağmuru, hedefe zıplayıp ezen savaş kurbağası, ağızdan kurbağa yağı (kaygan, yavaşlatır) ve ardından onu tutuşturan alev seli (yağ varsa büyük), saç kalkanıyla çevreye iğne halkası; bitiriş Ōdama Rasengan."},
	"chidori": {"name": "Chidori — Şimşek Kılıcı", "key": "style_chidori", "src": "path:chidori", "range": "yakın-orta", "stop": 2.2,
		"desc": "Bin kuşun ötüşü: avuçta toplanan Chidori darbesi, sol elden şimşek iğne yelpazesi (Senbon), uzayıp delen şimşek mızrağı (Eisō), bedenden her yöne akan Nagashi (felç), parmaktan ince delici iğne; bitiriş elini yere sürterek toprağı yaran Chidori koşusu ve yukarı saplanış."},
	"hiraishin": {"name": "Hiraishin — Uçan Yıldırım", "key": "style_hiraishin", "src": "path:hiraishin", "range": "orta (ışınlanma)", "stop": 4.5,
		"desc": "Sarı Şimşek'in yolu: hedefin çevresine saplanan üç uçlu kunailer işaret olur; bir an sonra en yakınının yanında el kılıcı, işaretli rakibin arkasında belirip tekme, havaya atılan kunaiyi yakalayıp yukarıdan iniş, kunailer arası zincir kesik; bitiriş sarı flaşla arkasında Rasengan."},
	"tip": {"name": "Iryō Ninjutsu — Şifacı", "key": "style_tip", "src": "path:tip", "range": "yakın", "stop": 1.6,
		"desc": "Tıbbi ninjanın dövüşü: parmak uçlarından Chakra Neşteri ile görünmez kesikler (kas kesilir, yavaşlar), sinirleri karıştıran Ranshinshō (sersem), ağızdan zehir akışı, rakibin chakrasını çekip seni onaran Shōsen avucu; bitiriş yumrukta toplanan chakra ile yeri yaran Ōkashō."},
	"kakuzu": {"name": "Jiongu — Toprak Kini", "key": "style_kakuzu", "src": "path:kakuzu", "range": "orta", "stop": 3.5,
		"desc": "Kakuzu'nun yolu: koldan fışkıran kara iplik kırbacı, ipliklerle fırlayıp rakibi yakalayıp çeken kol, Domu ile taşlaşan ezici yumruk, sırttan kopan maske canavarlarının Katon (Zukokku) ve Fūton (Atsugai) saldırıları; bitiriş iki maske birden — rüzgâr alevi büyütür."},
	"jashin": {"name": "Jashin Ayini", "key": "style_jashin", "src": "path:jashin", "need_item": "uc_tirpan", "range": "yakın-orta", "stop": 3.0,
		"desc": "Hidan'ın yolu: kabloyla fırlayıp geri dönen üç bıçaklı tırpan ve kara mızrak rakibin kanını alır, tırpan savuruşu çevreyi biçer; kan aldıysan ayağınla Jashin çemberini çizersin — çemberdeyken kendi bacağına ve kalbine sapladığın mızrağın yarasını lanetli rakip alır (kendi canından bedel)."},
	"hachibi": {"name": "Hachibi — Ritim ve Mürekkep", "key": "style_hachibi", "src": "path:hachibi", "range": "yakın-orta", "stop": 2.6,
		"desc": "Killer B'nin yolu: Gyūki'nin ahtapot dokunacıyla kırbaç, kollar ve ağızdaki yedi kılıçla dönüş, kör eden mürekkep tükürüğü, şimşekli Lariat atılışı, iki dokunaçla kavrayıp yere çarpma; bitiriş küçük Sekiz Kuyruk topu."},
	"silah": {"name": "Buki Kuchiyose — Silah Ustası", "key": "style_silah", "src": "path:silah", "range": "orta-uzak", "stop": 6.0,
		"desc": "Tenten'in yolu: iki el arasında açılan parşömenden kunai ve shuriken salvoları, zincirli orakla hedefi çekme, gökten karışık silah yağmuru, parşömenden çekilen dev balta; bitiriş gökten inen dev demir topuz."},
	"jin_shukaku": {"name": "Shukaku — Kum Canavarı", "key": "style_jin_shukaku", "src": "jin:shukaku", "range": "yakın-orta", "stop": 2.8,
		"desc": "Bir Kuyruk'un jinchūriki'si: kısmi dönüşümle kumla kaplanıp büyüyen pençe kol, kavrayıp kuma gömme, karından Fūton: Renkūdan hava mermisi, önden Sabaku Taisō kum dalgası, kısa kum kalkanı; bitiriş dev kum pençe yere çarpar ve büyük Renkūdan."},
	"jin_matatabi": {"name": "Matatabi — Mavi Alev Kedisi", "key": "style_jin_matatabi", "src": "jin:matatabi", "range": "yakın", "stop": 1.8,
		"desc": "İki Kuyruk'un jinchūriki'si: parmak uçlarından uzayan mavi alev tırnaklarla pençe izleri, yay çizen kedi sıçrayışı, mavi ateş topları, yerde yanan mavi alev şeridi; bitiriş çapraz çift pençe."},
	"jin_isobu": {"name": "Isobu — Mercan ve Sis", "key": "style_jin_isobu", "src": "jin:isobu", "range": "orta", "stop": 4.0,
		"desc": "Üç Kuyruk'un jinchūriki'si: hedefin altından fışkıran mercan diken, su avucu itişi, bağlayan mercan tarlası, dikenli kabuğa çekilip yuvarlanış, yanılsama sisi; bitiriş hedefi çevreleyen mercan halkası kapanır."},
	"kagit": {"name": "Shikigami no Mai — Kâğıt", "key": "style_kagit", "src": "path:kagit", "range": "orta", "stop": 6.0,
		"desc": "Konan'ın kâğıt sanatı: kesen kâğıt shurikenler, hedefi saran kelebek sürüsü (kör eder), yerden fırlayan kâğıt mızraklar, kâğıt kanat çırpışıyla kesici fırtına; bitiriş hedefin çevresinde patlayıcı kâğıt halkası."},
	"sumi": {"name": "Chōjū Giga — Sumi", "key": "style_sumi", "src": "path:sumi", "range": "orta-uzak", "stop": 6.5,
		"desc": "Sai'nin fırçası: sayfadan fırlayan mürekkep aslanlar, dolanıp bağlayan mürekkep ejder, aslan sürüsü, görüşü kapayan mürekkep sisi; bitiriş dev mürekkep kaplan ve ejder birden. Rakibe yanaşmaz."},
	"akasuna": {"name": "Kugutsu no Jutsu — Akasuna", "key": "style_akasuna", "src": "path:akasuna", "range": "orta", "stop": 5.0,
		"desc": "Sasori'nin kukla sanatı: parmaklardan uzanan chakra iplikleriyle yönetilen savaş kuklası atılıp keser, ağzından zehirli iğneler fırlatır, bıçaklı kollarıyla döner; iplikler rakibi çeker, kukla zehir gazı salar; bitiriş hedefin çevresinde dört kukla birden (Akahigi). Kuklacı rakibe yanaşmaz."},
	"kil": {"name": "Bakuton Geijutsu — Patlayıcı Kil", "key": "style_kil", "src": "path:kil", "range": "orta-uzak", "stop": 7.0,
		"desc": "Deidara'nın sanatı: avuç ağızlarından yapışıp patlayan kil örümcekler, süzülüp dalan kil kuşlar, hedefin altına gömülen kil mayın; bitiriş \"Katsu!\" — gökten düşen dev kil bebeğin patlaması. Yakında zayıf, rakibe yanaşmaz."},
	"kapi": {"name": "Gōken — Sekiz Kapı", "key": "style_kapi", "src": "path:kapi", "range": "yakın", "stop": 1.6,
		"desc": "Gai ve Lee'nin sert yumruğu: döner Konoha Senpū, alçak Reppū, rakibi havaya kaldıran Shōfū, peşinden sıçrayıp topuk inişi (Kage Buyō); kapılar açılınca alevli yumruk yağmuru (Asakujaku) ve bitiriş kaplan başı hava basıncı (Hirudora)."},
	"nara": {"name": "Kagemane-ryū — Nara", "key": "style_nara", "src": "clan:nara", "range": "orta (kontrol)", "stop": 5.0,
		"desc": "Gölge tarzı: uzanan gölge kırbaçları, kısa Kagemane bağı, yerden fırlayan gölge iğneleri (Kage Nui), bedene tırmanıp boğan gölge eller (Kage Kubi Shibari); bitiriş bağla + iğne yağmuru. Hasarı orta, kontrolü güçlü; yakında zayıf, rakibe yanaşmaz."},
	"hatake": {"name": "Hatake-ryū — Hatake", "key": "style_hatake", "src": "clan:hatake", "range": "yakın + raiton", "stop": 1.8,
		"desc": "Kakashi'nin silahsız tarzı: alçak süpürme ve yüksek döner tekme, Shunshin ile arkaya geçip dirsek, elden fırlayan şimşek tazısı (Raijū Tsuiga), yerden fırlayıp hedefi tutan ninkenler (Doton Tsuiga); bitiriş avuçta toplanan şimşekle hedefe dalış (Raikiri)."},
	"sarutobi": {"name": "Sarutobi-ryū — Sarutobi", "key": "style_sarutobi", "src": "clan:sarutobi", "range": "yakın + orta (kül/ateş)", "stop": 2.4,
		"desc": "Hiruzen, Asuma, Konohamaru: rüzgâr chakralı Hien yumrukları, öne üflenen kül bulutu (göz alır, yavaşlatır), dişler çakılınca bulut patlar (Haisekishō'nun ikinci yarısı), havada çoğalan shuriken (Shuriken Kage Bunshin); bitiriş mühürle ağızdan kıvrılan ateş seli (Karyū Endan)."},
	"senju": {"name": "Senju-ryū — Senju", "key": "style_senju", "src": "clan:senju", "range": "yakın-orta", "stop": 2.2,
		"desc": "Senju kanının canavar gücü ve Mokuton: ağır yumruklar, koldan fışkırıp saplanan dallar, hedefin altından tahta sütunlar, yere yumruk Ōkashō (zemin sivri kayalarla kalkar); bitiriş sıçrayıp topuk inişi Tsūtenkyaku (krater)."},
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
	if src.begins_with("path:"):   # yolda olmak (LegendPaths durum 4 = JOINED)
		var pd = (p.get("paths", {}) as Dictionary).get(src.substr(5), {}) if p.get("paths") is Dictionary else {}
		return pd is Dictionary and int(pd.get("s", 0)) >= 4
	if src.begins_with("jin:"):
		return TailedBeasts.player_jinchuriki() == src.substr(4)
	return false


## Oyuncunun seçebileceği tarzlar ("" = temel taijutsu her zaman ilk)
static func available(p: Dictionary) -> Array:
	var out = [""]
	for id in STYLES:
		if _has_src(p, String(STYLES[id]["src"])):
			if STYLES[id].has("need_item") and not String(STYLES[id]["need_item"]) in Gear.owned_ids(p):
				continue   # kanon silahı olmadan bu tarz olmaz (Jashin = üç bıçaklı tırpan)
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
