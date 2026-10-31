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
	"kagit": {
		"name": "Kâğıt Yolu", "icon": "scroll", "color": Color(0.85, 0.82, 0.95),
		"style": "Bedeni kâğıda çeviren sanat: kâğıt klonlar, kelebek sürüleri, kanatlar, mızrak ormanı ve patlayıcı kâğıt denizi",
		"site": {"country": "rain", "off": Vector2(-700, 600), "kind": "paper", "clear": 50.0, "place": "Kâğıt Çiçek Kulesi (Yağmur Ülkesi)"},
		"mentor": {"name": "Shirobana Ayame", "title": "Kâğıt Ustası",
			"look": {"gender": "f", "skin": Color(0.96, 0.88, 0.84), "hair": Color(0.45, 0.35, 0.65), "hair_style": "topuz", "eye": Color(0.85, 0.75, 0.4),
				"top": Color(0.15, 0.15, 0.2), "top2": Color(0.15, 0.15, 0.2), "pants": Color(0.15, 0.15, 0.2), "band": Color(0.3, 0.3, 0.35), "age": "adult"}},
		"rumor_level": 9, "join_level": 11,
		"rumor": "Yağmur Ülkesi'nde, tepesinde kâğıt çiçek açan bir kulede yaşayan sessiz bir kadın varmış. Rüzgârla dağılıp yeniden toplanırmış.",
		"intro": "Kadının bedeni bir an kâğıt yapraklara dağılıp yeniden birleşiyor: \"Kâğıt zayıf görünür. Ama bin kat katlanınca çelik keser. Sabrın varsa öğretirim.\"",
		"passive": {"jutsu": 0.1, "speed": 0.03},
		"passive_desc": "Jutsu gücü +%10, hız +%3",
		"order": ["kami_bunshin", "kami_chocho", "kami_tsubasa", "shikigami_no_mai", "kami_yari", "kami_no_shisha_no_jutsu"],
		"quest": {"kami_no_shisha_no_jutsu": "sea"},
		"dark": {},
	},
	"gama": {
		"name": "Kurbağa Bilgesi Yolu", "icon": "seal", "color": Color(1.0, 0.6, 0.25),
		"style": "Kurbağa yağı ve ateş, savaş saçı (iğneler, aslan yelesi, diken kalkanı), kurbağa midesi mühürü ve bilge çağrısı",
		"site": {"country": "waterfall", "off": Vector2(500, -800), "kind": "toad", "clear": 50.0, "place": "Yosunlu Kurbağa Tapınağı (Şelale Ülkesi)"},
		"mentor": {"name": "Hōrō Gamasuke", "title": "Gezgin Kurbağa Bilgesi",
			"look": {"gender": "m", "skin": Color(0.94, 0.8, 0.68), "hair": Color(0.92, 0.92, 0.9), "hair_style": "uzun", "eye": Color(0.3, 0.25, 0.2),
				"top": Color(0.3, 0.45, 0.3), "top2": Color(0.75, 0.2, 0.15), "pants": Color(0.3, 0.45, 0.3), "band": Color(0.85, 0.85, 0.82), "age": "adult", "face_mark": "yanak çizgisi"}},
		"rumor_level": 8, "join_level": 10,
		"rumor": "Şelale Ülkesi'nde, yosunlu bir kurbağa tapınağında roman yazan beyaz saçlı bir bilge görülmüş. Kurbağalarla konuşurmuş.",
		"intro": "Beyaz saçlı adam kaleminden başını kaldırıyor: \"Bir öğrenci mi? Hah! Önce bana kurbağaların gözünden dünyayı göstermelisin. Sonra saçımın bile silah olduğunu görürsün.\"",
		"passive": {"chakra": 0.12, "hp": 0.06},
		"passive_desc": "Chakra +%12, can +%6",
		"order": ["gamayudan", "kebari_senbon", "ranjishigami_no_jutsu", "hari_jizo", "kuchiyose_gamaguchi_shibari", "katon_gamayu_endan", "senpo_kawazu_naki"],
		"quest": {"senpo_kawazu_naki": "sage"},
		"dark": {},
	},
	"kil": {
		"name": "Patlayıcı Kil Yolu", "icon": "seal", "color": Color(0.95, 0.85, 0.6),
		"style": "Avuçtaki ağızlarla chakra yoğrulmuş kil: uçan kuşlar, örümcekler, ejderler, kasaba yıkan heykeller ve sanatın son patlaması",
		"site": {"country": "earth", "off": Vector2(-1200, -900), "kind": "clay", "clear": 50.0, "place": "Kil Atölyesi (Toprak Ülkesi kanyonları)"},
		"mentor": {"name": "Bakufū Gen", "title": "Kil Sanatçısı",
			"look": {"gender": "m", "skin": Color(0.95, 0.84, 0.72), "hair": Color(0.95, 0.85, 0.45), "hair_style": "uzun", "eye": Color(0.3, 0.45, 0.75),
				"top": Color(0.18, 0.18, 0.22), "top2": Color(0.75, 0.15, 0.15), "pants": Color(0.18, 0.18, 0.22), "band": Color(0.4, 0.35, 0.3), "age": "adult"}},
		"rumor_level": 10, "join_level": 12,
		"rumor": "Toprak Ülkesi'nin kanyonlarında patlamalar duyuluyormuş. Kilden kuşlar uçuran, sanatın bir an olduğuna inanan bir zanaatkâr yaşarmış.",
		"intro": "Sarışın adam elindeki kili yoğuruyor, avucundaki ağız sırıtıyor: \"Sanat bir patlamadır! Kalıcı olan sıkıcıdır, hm. Gözlerinle görmek istiyorsan önce benim işimi kanıtla.\"",
		"passive": {"jutsu": 0.12, "chakra": 0.05},
		"passive_desc": "Jutsu gücü +%12, chakra +%5",
		"order": ["nendo_bunshin", "kibaku_nendo", "shi_wan", "bakuha_kibaku_te", "kil_ucan_kus", "ningyo_kibaku_nendo", "shi_tsu", "bakuha_jirai", "bakuha_rensa", "shi_suri", "shi_fo", "shi_o", "nendo_kawarimi", "kibaku_jirai", "shi_tsu_bakuretsu_hiryu"],
		"quest": {"shi_fo": "art", "shi_o": "art"},
		"dark": {"shi_o": 10},
	},
	"kakuzu": {
		"name": "Toprak Kini Yolu", "icon": "seal", "color": Color(0.35, 0.3, 0.28),
		"style": "Bedeni dikip onaran kara iplikler, taş gibi sertleşen deri ve maskeli kalplerin ateş, rüzgâr, şimşek saldırıları",
		"site": {"country": "waterfall", "off": Vector2(-900, 700), "kind": "thread", "clear": 50.0, "place": "Kara İplik Mezarlığı (Şelale Ülkesi)"},
		"mentor": {"name": "Kurogane Zeni", "title": "İplik Ustası",
			"look": {"gender": "m", "skin": Color(0.75, 0.6, 0.48), "hair": Color(0.1, 0.1, 0.12), "hair_style": "uzun", "eye": Color(0.3, 0.7, 0.3),
				"top": Color(0.2, 0.22, 0.2), "top2": Color(0.15, 0.15, 0.15), "pants": Color(0.2, 0.2, 0.2), "band": Color(0.4, 0.4, 0.42), "age": "adult"}},
		"rumor_level": 12, "join_level": 14,
		"rumor": "Şelale Ülkesi'nin mezarlığında, para için ödül avlayan, yüzü dikişlerle dolu yaşlı bir paralı askerden söz ediliyor. Kalbi bir değil beşmiş...",
		"intro": "Dikişli adam paranı sayar gibi sana bakıyor: \"Para asla ihanet etmez. Sen de etmeyeceksen... bedenini dikmeyi öğretirim. Önce ödülünü getir.\"",
		"passive": {"hp": 0.15, "def": 0.05},
		"passive_desc": "Can +%15, savunma +%5",
		"order": ["jiongu_ito_kirbac", "doton_domu", "jiongu", "kakuzu_kalp_calma", "kakuzu_maske_katon", "kakuzu_maske_futon", "kakuzu_maske_raiton", "kakuzu_maske_suiton"],
		"quest": {"kakuzu_kalp_calma": "heart"},
		"dark": {"kakuzu_kalp_calma": 25},
	},
	"hiraishin": {
		"name": "Uçan Yıldırım Yolu", "icon": "seal", "color": Color(1.0, 0.85, 0.3),
		"style": "İşaretli kunailer, göz açıp kapayana kadar ışınlanma, zincirleme kesikler ve ışınlanırken Rasengan",
		"site": {"country": "whirlpool", "off": Vector2(400, 300), "kind": "thunder", "clear": 50.0, "place": "Yıldırım Mührü Tapınağı (Girdap harabeleri)"},
		"mentor": {"name": "Kōsoku Hayate", "title": "Sarı Şimşek",
			"look": {"gender": "m", "skin": Color(0.95, 0.82, 0.7), "hair": Color(0.98, 0.85, 0.3), "hair_style": "diken", "eye": Color(0.25, 0.5, 0.85),
				"top": Color(0.25, 0.35, 0.25), "top2": Color(0.95, 0.95, 0.92), "pants": Color(0.15, 0.2, 0.35), "band": Color(0.15, 0.22, 0.55), "age": "adult"}},
		"rumor_level": 14, "join_level": 16,
		"rumor": "Girdap Ülkesi'nin harabelerinde, sarı bir şimşek gibi göz açıp kapayana kadar yer değiştiren bir ninja görülmüş. Ardında yalnız üç kollu kunailer kalırmış.",
		"intro": "Sarı saçlı adam gülümsüyor, bir an yerinde, bir an arkanda: \"Hız, işaret koymaktır. Nereye işaret koyarsan oradasın. Önce işaretlerimi bul.\"",
		"passive": {"speed": 0.1, "seal_speed": 0.15},
		"passive_desc": "Hız +%10, mühür hızı +%15",
		"order": ["hiraishin_kunai", "hiraishingiri", "hiraishin_ranbu", "hiraishin_ni_no_dan", "hiraishin_no_jutsu", "hiraishin_rasengan", "hiraishin_dorai"],
		"quest": {"hiraishin_no_jutsu": "marks"},
		"dark": {},
	},
	"chidori": {
		"name": "Şimşek Kılıcı Yolu", "icon": "sword", "color": Color(0.55, 0.75, 1.0),
		"style": "Chidori'nin bin kuş sesi: elde, kılıçta, iğne ve mızrakta şimşek, bedenden akan akım ve gökten inen Kirin",
		"site": {"country": "iron", "off": Vector2(-500, 800), "kind": "chidori", "clear": 50.0, "place": "Bin Kuş Uçurumu (Demir Ülkesi)"},
		"mentor": {"name": "Raikō Shinobu", "title": "Şimşek Kılıcı",
			"look": {"gender": "m", "skin": Color(0.95, 0.84, 0.74), "hair": Color(0.08, 0.08, 0.12), "hair_style": "diken", "eye": Color(0.15, 0.15, 0.2),
				"top": Color(0.9, 0.9, 0.92), "top2": Color(0.3, 0.25, 0.45), "pants": Color(0.15, 0.15, 0.2), "band": null, "age": "adult"}},
		"rumor_level": 12, "join_level": 14,
		"rumor": "Demir Ülkesi'nin karlı uçurumlarında bin kuşun ötüşü gibi bir ses yankılanıyormuş. Elinde şimşek taşıyan sessiz bir kılıç ustası...",
		"intro": "Kara saçlı adam kılıcını kınından yarım çekiyor, namlu boyunca şimşek akıyor: \"Şimşek keskinliktir. Zayıf olan kırılır. Bana keskin olduğunu göster.\"",
		"passive": {"melee": 0.08, "el_raiton": 0.15},
		"passive_desc": "Yakın dövüş +%8, Raiton gücü +%15",
		"order": ["raiton_chidori", "chidori_nagashi", "chidori_senbon", "chidori_eiso", "chidori_ranbu", "kusanagi_no_tsurugi_chidorigatana", "chidori_jinrai", "kirin"],
		"quest": {"kirin": "storm"},
		"dark": {},
	},
	"jashin": {
		"name": "Jashin Yolu", "icon": "seal", "color": Color(0.75, 0.1, 0.12),
		"style": "Kan ritüelleri: düşmanın kanıyla lanet çemberi, üç bıçaklı tırpan, geri çekilen mızrak ve ölmeyen beden",
		"site": {"country": "hotwater", "off": Vector2(-800, 900), "kind": "jashin", "clear": 50.0, "place": "Kanlı Ayin Tapınağı (Sıcak Su Ülkesi)"},
		"mentor": {"name": "Chimatsuri Ren", "title": "Ayin Rahibi",
			"look": {"gender": "m", "skin": Color(0.95, 0.88, 0.82), "hair": Color(0.85, 0.85, 0.9), "hair_style": "geriye", "eye": Color(0.7, 0.2, 0.55),
				"top": Color(0.12, 0.12, 0.14), "top2": Color(0.7, 0.1, 0.12), "pants": Color(0.12, 0.12, 0.14), "band": Color(0.35, 0.35, 0.38), "age": "adult"}},
		"rumor_level": 14, "join_level": 16,
		"rumor": "Sıcak Su Ülkesi'nin terk edilmiş bir tapınağında kanla çizilmiş çemberlerin içinde dua eden, ölmeyen bir rahipten bahsediliyor.",
		"intro": "Rahip boynundaki kolyeyi öpüyor: \"Jashin-sama acıyı sever. Acı çekmekten korkmuyor musun? O zaman ayine katıl... ama önce kurbanları getir.\"",
		"passive": {"hp": 0.1, "regen_hp": 0.5},
		"passive_desc": "Can +%10, can yenilenmesi artar",
		"order": ["jashin_sanjin_kama", "jashin_kazik", "jashin_ketsueki", "jujutsu_shiji_hyoketsu", "jashin_fumetsu", "jashin_kurban"],
		"quest": {"jujutsu_shiji_hyoketsu": "ritual"},
		"dark": {"jujutsu_shiji_hyoketsu": 20, "jashin_kurban": 20},
	},
	"hachibi": {
		"name": "Sekiz Kuyruk Yolu", "icon": "seal", "color": Color(0.85, 0.5, 0.75),
		"style": "Ahtapot kolları, mürekkep perdesi, yedi kılıç dansı, kuyruklu lariat ve ritimle akan savaş",
		"site": {"country": "lightning", "off": Vector2(900, -900), "kind": "octo", "clear": 50.0, "place": "Hileler ve Gerçekler Şelalesi (Yıldırım Ülkesi)"},
		"mentor": {"name": "Hachiryū Biito", "title": "Ritim Ustası",
			"look": {"gender": "m", "skin": Color(0.42, 0.3, 0.22), "hair": Color(0.92, 0.92, 0.9), "hair_style": "kisa", "eye": Color(0.15, 0.15, 0.15),
				"top": Color(0.9, 0.9, 0.88), "top2": Color(0.25, 0.25, 0.28), "pants": Color(0.2, 0.2, 0.22), "band": Color(0.15, 0.22, 0.55), "age": "adult"}},
		"rumor_level": 16, "join_level": 18,
		"rumor": "Yıldırım Ülkesi'nin şelalesinde ritimle konuşan, sırtında yedi kılıç taşıyan güçlü bir savaşçı yaşarmış. Bazen ahtapot kolları çıkarırmış!",
		"intro": "İri adam ritim tutarak sana bakıyor: \"Yo! Ritmini bulamazsan kılıcın da şaşar, bebeğim! Şelalenin altında kendinle yüzleş, sonra rap yapalım!\"",
		"passive": {"melee": 0.1, "hp": 0.08},
		"passive_desc": "Yakın dövüş +%10, can +%8",
		"order": ["hachibi_murekkep", "takoashi_bunshin_no_jutsu", "hachibi_lariat", "hachibi_ahtapot_kollari", "hachibi_yedi_kilic", "hachibi_kuyruk_zirhi", "hachibi_ahtapot_topu"],
		"quest": {"hachibi_ahtapot_topu": "falls"},
		"dark": {},
	},
	"sumi": {
		"name": "Kök: Mürekkep Yolu", "icon": "scroll", "color": Color(0.55, 0.55, 0.62),
		"style": "Fırçayla çizilen mürekkep canavarları (Chōjū Giga), mürekkep klonları ve sisi, mürekkep mühürleri; duygusuz Kök eğitimi",
		"site": {"country": "fire", "off": Vector2(1800, 2600), "kind": "ink", "clear": 48.0, "place": "Yıkık Kök Karakolu (Ateş Ülkesi ormanı)"},
		"mentor": {"name": "Sumizome Kōji", "title": "Mürekkep Ustası",
			"look": {"gender": "m", "skin": Color(0.95, 0.9, 0.86), "hair": Color(0.06, 0.06, 0.08), "hair_style": "kisa", "eye": Color(0.08, 0.08, 0.1),
				"top": Color(0.12, 0.12, 0.14), "top2": Color(0.4, 0.4, 0.45), "pants": Color(0.12, 0.12, 0.14), "band": Color(0.2, 0.2, 0.22), "age": "adult"}},
		"rumor_level": 8, "join_level": 10,
		"rumor": "Ateş Ülkesi ormanında, dağıtılmış eski bir Kök karakolunda sessizce resim yapan solgun bir adam varmış. Çizdiği kuşlar sayfadan kalkıp uçarmış.",
		"intro": "Solgun adam fırçasını kaldırmadan konuşuyor: \"Kök duyguları siler, yalnız görev kalır. Ben resmimle bir şeyler geri kazandım. Önce elinin titremediğini göster.\"",
		"passive": {"chakra": 0.1, "jutsu": 0.05},
		"passive_desc": "Chakra +%10, jutsu gücü +%5",
		"order": ["sumi_bunshin_no_jutsu", "sumigasumi_no_jutsu", "choju_giga", "hoki_sumi_ryu", "fuinjutsu_okutopasu_horudo", "choshin_giga", "hoki_sumi_tora", "hoki_sumi_tori"],
		"quest": {"choshin_giga": "god"},
		"dark": {},
	},
}
## Sıradaki yollar (ROADMAP): kurbağa sennin, kil sanatı, kukla ustası, Hiraishin, köpekbalığı...

## Yollara ait, veri dosyasında olmayan teknikler: Data.jutsu'ya yüklenir
const EXTRA_JUTSU := {
	"kami_chocho": {"name": "Kami Chōchō (Kâğıt Kelebekler)", "cost": 30, "cd": 10, "element": "", "level": 12, "rank": 2, "tier": 3, "shape": "debuff", "learn": "path:kagit", "category": "ninjutsu",
		"seals": ["Tora", "Hitsuji"], "desc": "Bedenden kopan yüzlerce kâğıt kelebek düşmanları sarar: görüşü kapanır (3 sn sersem), küçük kesikler."},
	"kami_tsubasa": {"name": "Kami Tsubasa (Kâğıt Kanatlar)", "cost": 35, "cd": 25, "element": "", "level": 14, "rank": 2, "tier": 3, "shape": "transform", "learn": "path:kagit", "category": "ninjutsu",
		"seals": ["Tori"], "desc": "Sırtından kâğıt kanatlar açılır: 20 sn uçarsın (Space yüksel, Ctrl alçal), kanat çırpışı kâğıt bıçakları savurur."},
	"kami_yari": {"name": "Kami Yari no Mori (Kâğıt Mızrak Ormanı)", "cost": 45, "cd": 14, "element": "", "level": 22, "rank": 3, "tier": 4, "shape": "spikes", "learn": "path:kagit", "category": "ninjutsu",
		"seals": ["I", "Tatsu"], "desc": "Yerden sivri kâğıt mızraklar fışkırır; hedef ve çevresi delinir, havaya atılır."},
	"hari_jizo": {"name": "Ninpō: Hari Jizō (Diken Bekçisi)", "cost": 30, "cd": 16, "element": "", "level": 16, "rank": 2, "tier": 3, "shape": "buff", "learn": "path:gama", "category": "ninjutsu",
		"seals": ["Mi"], "desc": "Saçın bedenini saran dikenli bir kozaya döner: 4 sn neredeyse hasar almazsın, yakın dövüşle vuranlar dikenlere batar."},
	"katon_gamayu_endan": {"name": "Katon: Gamayu Endan (Kurbağa Yağı Alev Bombası)", "cost": 50, "cd": 16, "element": "katon", "level": 26, "rank": 3, "tier": 4, "shape": "breath", "learn": "path:gama", "category": "ninjutsu",
		"seals": ["Mi", "Hitsuji", "Tora"], "desc": "Bir kurbağa yağ fışkırtır, sen ateşi üflersin: yağla büyüyen dev alev seli, yerde yanan yağ gölü bırakır."},
	"kil_ucan_kus": {"name": "Kibaku Nendo: Tori (Kil Kuşu Uçuşu)", "cost": 40, "cd": 30, "element": "", "level": 16, "rank": 2, "tier": 3, "shape": "transform", "learn": "path:kil", "category": "ninjutsu",
		"seals": ["Tora"], "desc": "Dev kil kuş yoğrulur, sırtına binersin: 20 sn uçarsın, uçarken altına küçük kil bombalar düşer."},
	"jiongu_ito_kirbac": {"name": "Jiongu: Ito Muchi (Kara İplik Kırbacı)", "cost": 26, "cd": 8, "element": "", "level": 14, "rank": 2, "tier": 3, "shape": "melee", "learn": "path:kakuzu", "category": "kinjutsu",
		"seals": [], "desc": "İplikli el göğse dalar ve kalbi söker: güçlü hedefin kalbi (canı %30 altına inen ya da ölen) senin olur. En fazla 4 çalınmış kalp: her biri sahibinin doğasının maskeli tekniğini açar ve seni bir kez ölümden döndürür."},
	"doton_domu": {"name": "Doton: Domu", "cost": 30, "cd": 20, "element": "doton", "level": 15, "rank": 2, "tier": 3, "shape": "buff", "learn": "path:kakuzu", "category": "ninjutsu",
		"seals": ["Ushi", "Tori"], "desc": "Ten kararıp taş kadar sertleşir: 8 sn fiziksel hasarı neredeyse almazsın, yumrukların ağırlaşır."},
	"kakuzu_maske_katon": {"name": "Jiongu: Katon Zukokku (Ateş Maskeli Kalp)", "cost": 45, "cd": 16, "element": "katon", "level": 18, "rank": 3, "tier": 4, "shape": "breath", "learn": "path:kakuzu", "category": "ninjutsu",
		"seals": [], "desc": "Sırtından ateş maskeli canavar çıkar, ağzından dev patlayan alev topu kusar. Çalınmış bir Katon kalbi ister."},
	"kakuzu_maske_futon": {"name": "Jiongu: Fūton Atsugai (Rüzgâr Maskeli Kalp)", "cost": 45, "cd": 16, "element": "fuuton", "level": 20, "rank": 3, "tier": 4, "shape": "beam", "learn": "path:kakuzu", "category": "ninjutsu",
		"seals": [], "desc": "Rüzgâr maskeli canavar sıkıştırılmış kasırga üfler; geniş alanı yıkar. Çalınmış bir Fūton kalbi ister."},
	"kakuzu_maske_raiton": {"name": "Jiongu: Raiton Gian (Şimşek Maskeli Kalp)", "cost": 45, "cd": 16, "element": "raiton", "level": 22, "rank": 3, "tier": 4, "shape": "beam", "learn": "path:kakuzu", "category": "ninjutsu",
		"seals": [], "desc": "Şimşek maskeli canavar kara-mavi şimşek ışını fırlatır; hattı delip geçer. Çalınmış bir Raiton kalbi ister."},
	"kakuzu_maske_suiton": {"name": "Jiongu: Suiton Mizu Kiba (Su Maskeli Kalp)", "cost": 45, "cd": 16, "element": "suiton", "level": 24, "rank": 3, "tier": 4, "shape": "beam", "learn": "path:kakuzu", "category": "ninjutsu",
		"seals": [], "desc": "Su maskeli canavar basınçlı su dişleri fırlatır. Çalınmış bir Suiton kalbi ister."},
	"kakuzu_kalp_calma": {"name": "Jiongu: Shinzō Ubai (Kalp Çalma)", "cost": 50, "cd": 40, "element": "", "level": 15, "rank": 2, "tier": 5, "shape": "melee", "learn": "path:kakuzu", "category": "kinjutsu",
		"seals": [], "desc": "İplikli el göğse dalar ve kalbi söker: güçlü hedefin kalbi (canı %30 altına inen ya da ölen) senin olur. En fazla 4 çalınmış kalp: her biri sahibinin doğasının maskeli tekniğini açar ve seni bir kez ölümden döndürür."},
	"hiraishin_kunai": {"name": "Hiraishin Kunai (Uçan Yıldırım Kunaisi)", "cost": 20, "cd": 6, "element": "", "level": 16, "rank": 2, "tier": 3, "shape": "projectile", "learn": "path:hiraishin", "category": "ninjutsu",
		"seals": [], "desc": "Mühürlü üç kollu kunai fırlatılır; saplandığı yere 0.3 sn sonra ışınlanıp kesersin."},
	"hiraishin_ranbu": {"name": "Hiraishin Ranbu (Uçan Yıldırım Dansı)", "cost": 40, "cd": 14, "element": "", "level": 20, "rank": 3, "tier": 4, "shape": "melee", "learn": "path:hiraishin", "category": "ninjutsu",
		"seals": [], "desc": "Çevredeki düşmanlar arasında sarı şimşek gibi zıplayıp her birini art arda kesersin."},
	"hiraishin_rasengan": {"name": "Hiraishin Rasengan (Uçan Yıldırım Rasengan)", "cost": 50, "cd": 16, "element": "", "level": 26, "rank": 4, "tier": 5, "shape": "melee", "learn": "path:hiraishin", "category": "ninjutsu",
		"seals": [], "desc": "Elinde Rasengan yoğrulur, hedefin arkasına ışınlanıp çarparsın."},
	"chidori_ranbu": {"name": "Chidori Ranbu (Chidori Kılıç Dansı)", "cost": 35, "cd": 12, "element": "raiton", "level": 20, "rank": 3, "tier": 4, "shape": "melee", "learn": "path:chidori", "category": "ninjutsu",
		"seals": [], "desc": "Kılıca akan Chidori ile beş hızlı kesik; her kesik şimşek yarığı bırakır."},
	"chidori_jinrai": {"name": "Chidori: Jinrai", "cost": 45, "cd": 16, "element": "raiton", "level": 24, "rank": 3, "tier": 4, "shape": "melee", "learn": "path:chidori", "category": "ninjutsu",
		"seals": [], "desc": "Chidori'yle hat boyunca şimşek gibi ileri atılır, yolundaki her düşmanı delersin."},
	"jashin_sanjin_kama": {"name": "Sanjin no Ōgama (Üç Bıçaklı Tırpan)", "cost": 25, "cd": 7, "element": "", "level": 16, "rank": 2, "tier": 3, "shape": "projectile", "learn": "path:jashin", "category": "taijutsu",
		"seals": [], "desc": "Kabloya bağlı kızıl üç bıçaklı tırpan fırlatılır; kanatıp geri çekilir."},
	"jashin_kazik": {"name": "Jashin: Kaeri Yari (Geri Çekilen Kazık)", "cost": 22, "cd": 6, "element": "", "level": 17, "rank": 2, "tier": 3, "shape": "projectile", "learn": "path:jashin", "category": "taijutsu",
		"seals": [], "desc": "Kolundan uzayan siyah kazık hedefe saplanır; kanını alırsın (ayin için)."},
	"jashin_ketsueki": {"name": "Jashin: Chi no Chikai (Kan Yemini)", "cost": 20, "cd": 12, "element": "", "level": 18, "rank": 2, "tier": 3, "shape": "buff", "learn": "path:jashin", "category": "kinjutsu",
		"seals": [], "desc": "Kendi kanını içip bedeni siyah-beyaz ölüm desenine bürünür: 10 sn vuruşların kanatır ve can çalar."},
	"jashin_fumetsu": {"name": "Jashin: Fujimi (Ölümsüz Beden)", "cost": 40, "cd": 60, "element": "", "level": 22, "rank": 3, "tier": 4, "shape": "buff", "learn": "path:jashin", "category": "kinjutsu",
		"seals": [], "desc": "Jashin'in lütfu: 8 sn canın 1'in altına inmez, aldığın her darbe yakındaki düşmanlara da yansır."},
	"jashin_kurban": {"name": "Jashin: Ikenie no Gi (Kurban Ayini)", "cost": 55, "cd": 30, "element": "", "level": 26, "rank": 4, "tier": 5, "shape": "aoe", "learn": "path:jashin", "category": "kinjutsu",
		"seals": [], "desc": "Yere dev kan çemberi çizilir; içindeki düşmanlar her saniye senin aldığın kadar hasar alır."},
	"hachibi_murekkep": {"name": "Hachibi: Tako Sumi (Mürekkep Perdesi)", "cost": 20, "cd": 10, "element": "", "level": 18, "rank": 2, "tier": 3, "shape": "aoe", "learn": "path:hachibi", "category": "ninjutsu",
		"seals": [], "desc": "Ağızdan fışkıran kara mürekkep: önündekiler kör olur, yapışkan mürekkep yavaşlatır."},
	"hachibi_lariat": {"name": "Bijū Rariatto (Kuyruklu Lariat)", "cost": 35, "cd": 12, "element": "raiton", "level": 20, "rank": 3, "tier": 4, "shape": "melee", "learn": "path:hachibi", "category": "taijutsu",
		"seals": [], "desc": "Şimşekli kol ve ahtapot koluyla çift lariat; yolundakiler savrulur."},
	"hachibi_ahtapot_kollari": {"name": "Takoashi Ude (Ahtapot Kolları)", "cost": 40, "cd": 14, "element": "", "level": 22, "rank": 3, "tier": 4, "shape": "aoe", "learn": "path:hachibi", "category": "ninjutsu",
		"seals": [], "desc": "Sırttan çıkan dev ahtapot kolları yeri döver, yakalayıp sıkar."},
	"hachibi_yedi_kilic": {"name": "Nanatō Ranbu (Yedi Kılıç Dansı)", "cost": 45, "cd": 16, "element": "", "level": 24, "rank": 3, "tier": 4, "shape": "melee", "learn": "path:hachibi", "category": "kenjutsu",
		"seals": [], "desc": "Kollar, koltuk altı, ağız: yedi kılıçla dönen kasırga kesik dansı."},
	"hachibi_kuyruk_zirhi": {"name": "Bijū Koromo (Kuyruk Örtüsü)", "cost": 40, "cd": 40, "element": "", "level": 26, "rank": 4, "tier": 5, "shape": "mode", "learn": "path:hachibi", "category": "ninjutsu",
		"seals": [], "desc": "Mor çakra örtüsü ve sekiz kuyruk: 20 sn güç, dayanıklılık, kollar otomatik saldırır."},
	"hachibi_ahtapot_topu": {"name": "Hachibi: Bijūdama (Sekiz Kuyruk Topu)", "cost": 60, "cd": 30, "element": "", "level": 28, "rank": 4, "tier": 5, "shape": "projectile", "learn": "path:hachibi", "category": "ninjutsu",
		"seals": [], "desc": "Ağızda siyah-mor canavar topu sıkıştırılır ve fırlatılır: dev patlama."},
}

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


## Kan yatkınlığı: Namikaze soyu Uçan Yıldırım Yolu'na erken çağrılır, sınavsız kabul edilir, yarı fiyata öğrenir, pasif 1.5 kat
const BLOOD := {"hiraishin": "namikaze"}


static func blood(pid: String) -> bool:
	return BLOOD.has(pid) and String(pr().get("clan", "")) == BLOOD[pid]


static func lv_need(pid: String, key: String) -> int:
	return int(PATHS[pid][key]) - (6 if blood(pid) else 0)


## Stats.skill eklentisi: katıldığın yolların pasif bonusları
static func passive(p: Dictionary, key: String) -> float:
	var v = 0.0
	var ps = p.get("paths", {})
	if not ps is Dictionary:
		return 0.0
	for pid in ps:
		if int(ps[pid].get("s", 0)) >= JOINED and PATHS.has(pid):
			v += float(PATHS[pid]["passive"].get(key, 0.0)) * (1.5 if BLOOD.has(pid) and String(p.get("clan", "")) == BLOOD[pid] else 1.0)
	return v


static func price(jid: String) -> int:
	var base = 100 + int(Data.jutsu.get(jid, {}).get("level", 1)) * 55
	var lp = String(Data.jutsu.get(jid, {}).get("learn", ""))
	if lp.begins_with("path:") and blood(lp.substr(5)):
		return base / 2
	return base


## Sıradaki adımın kısa metni (sekme ve diyalog)
static func next_step(pid: String) -> String:
	var P: Dictionary = PATHS[pid]
	match state(pid):
		UNKNOWN:
			return "Henüz bir söylenti duymadın (Sv.%d civarı)." % lv_need(pid, "rumor_level")
		RUMOR:
			return "Söylentinin peşine düş: %s. (İzi takip et)" % P["site"]["place"]
		FOUND:
			if int(pr().get("level", 1)) < lv_need(pid, "join_level"):
				return "Ustan seni Seviye %d olunca kabul edecek." % lv_need(pid, "join_level")
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
		if s == UNKNOWN and lv >= lv_need(pid, "rumor_level"):
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
		if lv < lv_need(pid, "join_level"):
			Hud.dialog(title, P["intro"] + "\n\n\"Ama henüz çok zayıfsın. Seviye %d olunca gel.\"" % lv_need(pid, "join_level"), [])
			return
		if blood(pid):
			Hud.dialog(title, P["intro"] + "\n\nUsta bir an duraksıyor: \"Bu saçlar, bu hız... Sen Namikaze kanındansın. Sınava gerek yok; kanın seni zaten buraya getirdi.\"", [{"label": "Yola katıl", "cb": func():
				st_of(pid)["s"] = JOINED
				Hud.banner("YOLA KATILDIN: " + P["name"].to_upper(), "Kan yatkınlığı: yarı fiyat, pasif ×1.5", P["color"])
				Game.save_game()}])
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
		"kil:trial":
			q = {"title": "Sanatın Kanıtı", "rank": "C",
				"brief": "Sanatçı, kanyondaki kil damarlarından yoğrulabilir kil toplamanı ve atölyeyi soymaya gelen haydutları 'sanatla' kovmanı istiyor.",
				"steps": [
					{"kind": "collect", "at": _near(at, 280.0), "item": "chakra kili", "n": 6, "spread": 32, "text": "Kanyondan chakra kili topla (6)."},
					{"kind": "defend", "at": at, "enemy": "bandit", "waves": [3, 3], "text": "Atölyeye saldıran haydutları püskürt."}]}
		"kil:art":
			q = {"title": "Son Sanat Eseri", "rank": "A",
				"brief": "Ustanın en büyük eseri için eski bir taş kale yıkılmalı. Kaleyi tutan kaçak kayaninjalarını dağıt ve sanatın gürültüsünü göster.",
				"steps": [
					{"kind": "track", "from": at, "to": _near(at, 900.0), "text": "Taş kaleye git."},
					{"kind": "kill", "at": _near(at, 900.0), "enemy": "rogue", "n": 4, "camp": true, "boss": {"name": "Taş Muhafız Ganseki", "hp": 3200.0, "level": 30, "power": 2.6}, "text": "Kalenin muhafızlarını yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Kil Atölyesi", "text": "Atölyeye dön."}]}
		"kakuzu:trial":
			q = {"title": "Ödülün Bedeli", "rank": "C",
				"brief": "İplik ustası, başına ödül konmuş üç kaçağı getirmeni istiyor. Para asla ihanet etmez.",
				"steps": [
					{"kind": "kill", "at": _near(at, 450.0), "enemy": "rogue", "n": 3, "camp": true, "text": "Ödüllü kaçakları avla."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Kara İplik Mezarlığı", "text": "Ödülü ustaya getir."}]}
		"kakuzu:heart":
			q = {"title": "Beşinci Kalp", "rank": "A",
				"brief": "Kalp çalmak için güçlü bir rakibin kalbini sökmen gerek. Mezarlığa dadanan şimşek ninjasını yen.",
				"steps": [
					{"kind": "track", "from": at, "to": _near(at, 800.0), "text": "Şimşek ninjasının izini sür."},
					{"kind": "kill", "at": _near(at, 800.0), "enemy": "rogue", "n": 3, "camp": true, "boss": {"name": "Raijin Kogane", "hp": 3400.0, "level": 31, "power": 2.7}, "text": "Rakibi yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Kara İplik Mezarlığı", "text": "Mezarlığa dön."}]}
		"hiraishin:trial":
			q = {"title": "Sarı Şimşeğin İşaretleri", "rank": "C",
				"brief": "Usta harabelerin dört bir yanına mühürlü kunailer saplamış. Hepsini bul — hızlı ol!",
				"steps": [
					{"kind": "collect", "at": _near(at, 320.0), "item": "mühürlü kunai", "n": 6, "spread": 40, "text": "Mühürlü kunaileri topla (6)."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Yıldırım Mührü Tapınağı", "text": "Tapınağa dön."}]}
		"hiraishin:marks":
			q = {"title": "Zaman-Uzay Formülü", "rank": "A",
				"brief": "Gerçek ışınlanma için beş mühür taşına formül yaz ve formülü çalmaya gelenleri püskürt.",
				"steps": [
					{"kind": "points", "at": _near(at, 40.0), "n": 5, "spread": 18, "label": "[F] Mühür formülünü yaz", "fx": "seal", "text": "Beş mühür taşına formül yaz (5)."},
					{"kind": "defend", "at": at, "enemy": "rogue", "waves": [3, 4], "text": "Formülü çalmaya gelenleri püskürt."}]}
		"chidori:trial":
			q = {"title": "Keskinliğin Sınavı", "rank": "C",
				"brief": "Usta, uçurumun dibindeki samuray kaçaklarını yalnızca kılıçla yenmeni istiyor.",
				"steps": [
					{"kind": "kill", "at": _near(at, 420.0), "enemy": "samurai", "n": 4, "camp": true, "text": "Kaçak samurayları yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Bin Kuş Uçurumu", "text": "Uçuruma dön."}]}
		"chidori:storm":
			q = {"title": "Gökteki Ejder", "rank": "A",
				"brief": "Kirin için doğal bir fırtına gerekir. Beş zirvede ateş topu yakarak bulutları ısıt, sonra fırtınayı bölmeye gelenleri kov.",
				"steps": [
					{"kind": "points", "at": _near(at, 60.0), "n": 5, "spread": 24, "label": "[F] Zirvede bulutları ısıt", "fx": "seal", "text": "Beş zirvede bulutları ısıt (5)."},
					{"kind": "defend", "at": at, "enemy": "rogue", "waves": [3, 4], "text": "Fırtınayı bölenleri püskürt."}]}
		"jashin:trial":
			q = {"title": "İlk Kurban", "rank": "C",
				"brief": "Rahip, tapınağa saldıran kâfir paralı askerleri Jashin'e kurban etmeni istiyor.",
				"steps": [
					{"kind": "defend", "at": at, "enemy": "bandit", "waves": [3, 4], "text": "Tapınağa saldıranları püskürt."},
					{"kind": "collect", "at": _near(at, 200.0), "item": "kan şişesi", "n": 4, "spread": 24, "text": "Ayin için kan şişelerini topla (4)."}]}
		"jashin:ritual":
			q = {"title": "Lanet Çemberi", "rank": "A",
				"brief": "Ölüm mahkûmiyeti ayini için güçlü bir rakibin kanı gerekir. Onu bul, yen ve çembere dön.",
				"steps": [
					{"kind": "track", "from": at, "to": _near(at, 850.0), "text": "Kurbanın izini sür."},
					{"kind": "kill", "at": _near(at, 850.0), "enemy": "rogue", "n": 3, "camp": true, "boss": {"name": "Gümüş Muhafız Asuka", "hp": 3300.0, "level": 31, "power": 2.6}, "text": "Kurbanı yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Kanlı Ayin Tapınağı", "text": "Çembere dön."}]}
		"hachibi:trial":
			q = {"title": "Ritmini Bul", "rank": "C",
				"brief": "Usta, şelalenin çevresindeki beş ritim taşını çalmanı ve ritmi bozan haydutları kovmanı istiyor. Yo!",
				"steps": [
					{"kind": "points", "at": _near(at, 50.0), "n": 5, "spread": 20, "label": "[F] Ritim taşını çal", "fx": "seal", "text": "Beş ritim taşını çal (5)."},
					{"kind": "kill", "at": _near(at, 380.0), "enemy": "bandit", "n": 4, "camp": true, "text": "Ritmi bozan haydutları kov."}]}
		"hachibi:falls":
			q = {"title": "Gerçekler Şelalesi", "rank": "A",
				"brief": "Canavar topu için içindeki karanlıkla yüzleşmelisin. Şelalenin altına git ve kendi gölgeni yen.",
				"steps": [
					{"kind": "goto", "at": _near(at, 120.0), "r": 10.0, "name": "Şelalenin Altı", "text": "Şelalenin altına git."},
					{"kind": "kill", "at": _near(at, 120.0), "enemy": "rogue", "n": 2, "camp": true, "boss": {"name": "Karanlık Benlik", "hp": 3600.0, "level": 32, "power": 2.8}, "text": "Karanlık benliğini yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Şelale", "text": "Ustaya dön."}]}
		"sumi:trial":
			q = {"title": "Titremeyen El", "rank": "C",
				"brief": "Usta, karakolun çevresine dağılmış eski Kök mühür parşömenlerini toplamanı ve onları arayan kaçak Kök ajanlarını durdurmanı istiyor.",
				"steps": [
					{"kind": "collect", "at": _near(at, 240.0), "item": "Kök parşömeni", "n": 6, "spread": 30, "text": "Dağılmış Kök parşömenlerini topla (6)."},
					{"kind": "defend", "at": at, "enemy": "rogue", "waves": [2, 3], "text": "Parşömenlerin peşindeki kaçak ajanları püskürt."}]}
		"sumi:god":
			q = {"title": "Tanrı Çizimi", "rank": "A",
				"brief": "Dev mürekkep figürü için ustanın eski Kök arkadaşının mühürlü fırçası gerek. Fırçayı çalan kaçak Kök komutanını bul ve yen.",
				"steps": [
					{"kind": "track", "from": at, "to": _near(at, 850.0), "text": "Kaçak komutanın izini sür."},
					{"kind": "kill", "at": _near(at, 850.0), "enemy": "rogue", "n": 3, "camp": true, "boss": {"name": "Kök Komutanı Kurosen", "hp": 2800.0, "level": 26, "power": 2.5}, "text": "Kaçak Kök komutanını yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Yıkık Kök Karakolu", "text": "Fırçayla ustaya dön."}]}
		"kagit:trial":
			q = {"title": "Kâğıdın Sabrı", "rank": "C",
				"brief": "Usta, rüzgârın dağıttığı yüz kâğıt turnayı toplamanı ve onları çalmaya gelen haydutları kovmanı istiyor.",
				"steps": [
					{"kind": "collect", "at": _near(at, 260.0), "item": "kâğıt turna", "n": 6, "spread": 34, "text": "Dağılan kâğıt turnaları topla (6)."},
					{"kind": "defend", "at": at, "enemy": "bandit", "waves": [2, 3], "text": "Kuleye saldıran haydutları püskürt."}]}
		"kagit:sea":
			q = {"title": "Kâğıt Denizi", "rank": "A",
				"brief": "Bin patlayıcı etiketlik bir deniz için yasak bir mühür kâğıdı gerek. Onu saklayan kaçak kâğıt ustasını bul ve yen.",
				"steps": [
					{"kind": "track", "from": at, "to": _near(at, 900.0), "text": "Kaçak kâğıt ustasının izini sür."},
					{"kind": "kill", "at": _near(at, 900.0), "enemy": "rogue", "n": 3, "camp": true, "boss": {"name": "Kara Origami Shiga", "hp": 3000.0, "level": 30, "power": 2.6}, "text": "Kaçak kâğıt ustasını yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Kâğıt Çiçek Kulesi", "text": "Mühür kâğıdıyla ustaya dön."}]}
		"gama:trial":
			q = {"title": "Kurbağanın Gözü", "rank": "C",
				"brief": "Bilge, kayıp genç kurbağaları bulup tapınağa getirmeni ve onları avlayan yılan avcılarını dağıtmanı istiyor.",
				"steps": [
					{"kind": "collect", "at": _near(at, 300.0), "item": "kayıp kurbağa", "n": 5, "spread": 30, "text": "Kayıp kurbağaları bul (5)."},
					{"kind": "kill", "at": _near(at, 420.0), "enemy": "oto", "n": 3, "camp": true, "text": "Kurbağa avcılarını dağıt."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Kurbağa Tapınağı", "text": "Tapınağa dön."}]}
		"gama:sage":
			q = {"title": "Doğanın Sesi", "rank": "A",
				"brief": "Kurbağa yaşlılarının şarkısını taşıyabilmek için doğa enerjisini hissetmelisin. Beş yosun taşında meditasyon yap ve rahatsız edenleri kov.",
				"steps": [
					{"kind": "points", "at": _near(at, 40.0), "n": 5, "spread": 16, "label": "[F] Yosun taşında meditasyon", "fx": "seal", "text": "Beş yosun taşında meditasyon yap (5)."},
					{"kind": "defend", "at": at, "enemy": "rogue", "waves": [3, 4], "text": "Meditasyonu bölenleri püskürt."}]}
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
