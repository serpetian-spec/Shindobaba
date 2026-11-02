class_name WeaponHolders
extends RefCounted
## Efsane silahların sahipleri (Sis'in Yedi Kılıcı dışındakiler; onlar Swordsmen'de): her silahın dünyada bir sahibi var.
## Sahip HER OYUNDA farklı: adı, köyü, cinsiyeti, görünüşü ve gücü yeni oyunda rastgele üretilir. Sahip kaçak olarak Bingo
## Kitabı'na girer, silahı elinde ve silahın kombosuyla dövüşür (KeyedCombos: AI aynı kombo); yenilince silah oyuncuya düşer.
## Kanon kişi yok: sahipler kendi ninjalarımız, silahlar ve tarzları kanondaki gibi.

const INFO := {
	"uc_tirpan": {"alias": ["Kan Rahibi", "Ölümsüz Tırpan", "Ritüel Avcısı"], "el": "", "rank": "S",
		"tech": "Üç bıçaklı kızıl tırpanı arkadan savurur; kancalayıp çeker, yere saplar.",
		"villages": ["yu"], "look": {"outer_style": "pelerin", "outer": "1c1a22", "hair": "b9bcc4"}},
	"gunbai": {"alias": ["Yelpaze Lordu", "Kalkan Savaşçısı", "Alev Geri Çeviren"], "el": "katon", "rank": "S",
		"tech": "Dev gunbai ile darbeleri emer, Uchiha Gaeshi ile geri çevirir.",
		"villages": ["konoha"], "clan": "uchiha", "family": "Uchiha", "look": {"top_style": "yakali", "top": "1f2433", "top2": "1f2433", "hair": "121214"}},
	"raijin": {"alias": ["Şimşek Kılıcı", "Sarı Işın", "Gök Gürleyen Kılıç"], "el": "raiton", "rank": "S",
		"tech": "Yıldırımdan ağızlı kılıçla şimşek hızında keser.",
		"villages": ["kumo"], "look": {"skin": "b88a62"}},
	"ruzgar_bicak": {"alias": ["Rüzgar Kesen", "Görünmez Bıçak", "Fırtına Eli"], "el": "fuuton", "rank": "A",
		"tech": "Rüzgar chakrasından bıçağıyla her savuruşta uçan kesik atar.",
		"villages": ["konoha", "suna"], "look": {}},
	"hiraishin_kunai": {"alias": ["Sarı Flaş", "İşaretleyen", "Işınlanan Gölge"], "el": "raiton", "rank": "S",
		"tech": "Üç dişli kunaiyle hedefi işaretler, sarı flaşla arkasında belirir.",
		"villages": ["konoha", "uzushio"], "look": {"hair": "e8c341", "outer_style": "haori", "outer": "efefea"}},
	"homatsu_kiseru": {"alias": ["Köpük Ustası", "Sessiz Gezgin", "Baloncuk Cellatı"], "el": "suiton", "rank": "A",
		"tech": "Kabarcık borusundan patlayan, hapseden ve aşındıran köpükler üfler.",
		"villages": ["kiri"], "look": {"top_style": "kimono", "top": "8f97b8", "top2": "8f97b8", "pants": "8f97b8", "hair": "1a1a20"}},
	"kusanagi": {"alias": ["Yılan Kılıcı", "Uzayan Diş", "Beyaz Yılan"], "el": "doton", "rank": "S",
		"tech": "Yılan muhafızlı kılıcının ağzı bir anda uzar; kılıcı uzaktan uçurur.",
		"villages": ["oto"], "look": {"skin": "f2ece6", "hair": "15151a", "top": "e8e6e2", "rope_belt": true}},
}
const VILLAGES := ["konoha", "suna", "kiri", "kumo", "iwa", "ame", "kusa", "taki", "oto", "yu", "shimo", "tani"]
const GIVEN_M := ["Raizen", "Kurogane", "Haruto", "Tessai", "Gekko", "Shiden", "Akito", "Zenkai", "Kaito", "Ryūga", "Tobimaru", "Seijirō", "Kazan", "Jinpachi", "Ukyo", "Daigo"]
const GIVEN_F := ["Akane", "Yukari", "Hotaru", "Kaede", "Ranmaru", "Suzume", "Tsubaki", "Sayo", "Natsume", "Hisame"]
const FAMILY := ["Kagerō", "Shirogane", "Ōtori", "Kurosaki", "Amagiri", "Tachibana", "Mibu", "Fūma", "Shimotsuki", "Arashi", "Yamagiri", "Hōjō", "Kamiya", "Nanase", "Akasaka"]


static func _p() -> Dictionary:
	return Game.profile


static func weapon_name(id: String) -> String:
	return String(Gear.item(id).get("name", id)).split(" (")[0]


static func player_has(id: String) -> bool:
	for g in _p().get("gear", []):
		if String(g.get("id", "")) == id:
			return true
	return false


## Yeni sahip: her çağrıda farklı ad / köy / cinsiyet / güç / renkler (oyun başına bir kez üretilir, kayıtta saklanır)
static func _new_holder(id: String) -> Dictionary:
	var f = randf() < 0.4
	var given: String = (GIVEN_F if f else GIVEN_M).pick_random()
	var rank = String(INFO[id]["rank"])
	return {"state": "holder", "name": "%s %s" % [String(INFO[id].get("family", FAMILY.pick_random())), given], "gender": "f" if f else "m",
		"village": (INFO[id].get("villages", VILLAGES) as Array).pick_random(), "level": randi_range(44, 62) if rank == "S" else randi_range(34, 50),
		"alias": (INFO[id]["alias"] as Array).pick_random(), "seed": randi()}


## Dünya durumu: oyuncuda olanlar "player", kalanlar için rastgele sahip -> Bingo Kitabı
static func state() -> Dictionary:
	var pr = _p()
	if pr.is_empty():
		return {}
	if not pr.has("legend_holders"):
		var s = {}
		for id in INFO:
			s[id] = {"state": "player"} if player_has(id) else _new_holder(id)
		pr["legend_holders"] = s
		for id in s:
			if s[id]["state"] == "holder":
				Missions.add_weapon_holder(id, s[id])
	return pr["legend_holders"]


## Bingo'daki sahip yenildi: silah oyuncuya düşer
static func claim(id: String) -> void:
	var s = state()
	if s.is_empty() or not s.has(id):
		return
	s[id] = {"state": "player"}
	if not player_has(id):
		Gear.grant(_p(), id)
	Hud.banner("SİLAH DÜŞTÜ", "%s artık senin! [Tab > Ekipman]" % weapon_name(id), Color(1.0, 0.8, 0.35))
	Sfx.play("levelup", null, 0.8)
