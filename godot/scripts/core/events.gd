extends Node
## Chūnin Seçme Sınavı (autoload "ChuninExam"). Köyler sırayla ev sahipliği yapar; aşamalar:
##  1 Yazılı sınav (kopya çekmek serbest ama yakalanmamak şartıyla; 10. soru ikilemi asıl sınavdır)
##  2 Ölüm Ormanı (5 gün; takımınla Gök + Yer parşömenlerini topla, ormanın ortasındaki kuleye ulaş; gece pusuları)
##  3 Ön elemeler (kulede 1'e 1 eşleşmeler, kaybeden elenir)
##  4 Final turnuvası (ev sahibi köyün stadyumu, seyirci, Kage locası). Jüri taktiği değerlendirir: kaybetsen bile terfi olabilir.
## Final sırasında bir istila yaşanabilir (Orgs.exam_invasion).

const HOSTS := ["konoha", "suna", "kiri", "kumo", "iwa"]
const DAY_LEN := 60.0
const QUIZ := [
	["Bir kunai 12 m yükseklikteki bir daldan, 30° açıyla, 18 m uzaklıktaki saklanmış düşmana atılacak. Hangi açı düzeltmesi isabet şansını artırır?", ["Yerçekimi için hedefin biraz üstüne nişan almak", "Doğrudan hedefe nişan almak", "Hedefin altına nişan almak"], 0],
	["Bir şifre mesajında her harf, mühür sırasının üç sonrakiyle değiştirilmiş. 'Kaplan' mührünün üç sonrası hangisidir?", ["Ejderha", "At", "Yılan"], 0],
	["Genjutsu'yu bozmanın en güvenilir yolu hangisidir?", ["Chakra akışını kesip yeniden başlatmak (Kai)", "Gözleri kapatıp beklemek", "Daha hızlı koşmak"], 0],
	["Su ile yangını söndürmek için Suiton yeterli değilse ne yapılır?", ["Toprakla boğmak (Doton)", "Rüzgarla beslemek", "Yıldırımla vurmak"], 0],
	["Takımdan biri genjutsuya düştü. Lider olarak ilk adımın ne olur?", ["Diğerlerinin chakrasıyla onu uyandırmak ve pozisyonu korumak", "Onu bırakıp devam etmek", "Hemen geri çekilmek"], 0],
	["Bir ağaca chakra ile tırmanırken kabuk kırılıyorsa sorun nedir?", ["Ayaklara fazla chakra veriliyor", "Az chakra veriliyor", "Ağaç çürük"], 0],
	["Bir Gök Parşömeni sınav bitmeden açılırsa ne olur?", ["İçindeki mühür seni bayıltır; elenirsin", "Bir jutsu öğrenirsin", "Kule kapısı açılır"], 0],
	["Rüzgar elementi hangi elemente karşı güçlüdür?", ["Yıldırım", "Su", "Ateş"], 0],
	["Bir ninjanın gücünü düşmandan saklamasının en iyi yolu hangisidir?", ["Sınavda sadece gerekeni göstermek", "En güçlü jutsuyu hemen kullanmak", "Herkese tekniklerini anlatmak"], 0],
	["Kuşatılmış bir takım için en iyi kaçış planı hangisidir?", ["Bir yem/klon ile dikkat dağıtıp farklı yönlere çekilmek", "Hepsinin aynı yöne koşması", "Teslim olmak"], 0],
	["Hangi durumda bir genin chūnin olur?", ["Yalnızca turnuvayı kazanırsa", "Jüri komutanlık yeteneği görürse, kaybetse bile", "Seviyesi yeterliyse"], 1],
	["Kum fırtınasında takipten kurtulmak için?", ["Rüzgârın tersine dönüp izleri silmek", "Hızlanmak", "Durup beklemek"], 0],
]
const RIVALS := [
	{"name": "Raiga Kurosawa", "style": "Taijutsu ustası, inanılmaz hızlı", "el": "", "j": [], "power": 1.55, "hp": 1.1, "sub": 0.35, "hair": "diken", "top": Color(0.2, 0.5, 0.25), "v": "kumo"},
	{"name": "Kotone Ibuki", "style": "Kukla ve Fūton, mesafeden saldırır", "el": "fuuton", "j": ["fuuton_daitoppa", "fuuton_shinkuu"], "power": 1.35, "hp": 0.95, "sub": 0.2, "hair": "atkuyruğu", "top": Color(0.55, 0.42, 0.28), "v": "suna", "f": true},
	{"name": "Haruki Aoba", "style": "Böcek klanı, sabırlı ve sinsi", "el": "doton", "j": ["doton_doryuusou"], "power": 1.3, "hp": 1.0, "sub": 0.4, "hair": "kase", "top": Color(0.3, 0.32, 0.3), "v": "konoha"},
	{"name": "Juro Kaneda", "style": "Doton duvarlarıyla ağır savunma", "el": "doton", "j": ["doton_doryuheki", "doton_doryuusou"], "power": 1.5, "hp": 1.45, "sub": 0.1, "hair": "kısa", "top": Color(0.5, 0.25, 0.2), "v": "iwa"},
	{"name": "Shizuku Mizuno", "style": "Suiton ejderhaları, sisli saldırı", "el": "suiton", "j": ["suiton_suiryuudan", "suiton_suikoudan"], "power": 1.4, "hp": 1.0, "sub": 0.3, "hair": "uzun", "top": Color(0.25, 0.35, 0.45), "v": "kiri", "f": true},
	{"name": "Akane Hinode", "style": "Katon fırtınası, saldırgan", "el": "katon", "j": ["katon_goukakyuu", "katon_housenka"], "power": 1.45, "hp": 1.0, "sub": 0.2, "hair": "atkuyruğu", "top": Color(0.65, 0.2, 0.15), "v": "konoha", "f": true},
	{"name": "Tobio Raido", "style": "Raiton ve kılıç, ani dalışlar", "el": "raiton", "j": ["raiton_nagashi", "raiton_chidori"], "power": 1.5, "hp": 1.05, "sub": 0.3, "hair": "dağınık", "top": Color(0.85, 0.85, 0.82), "v": "kumo"},
	{"name": "Sora Kirishima", "style": "Rüzgar bıçakları ve kawarimi ustası", "el": "fuuton", "j": ["fuuton_shinkuu"], "power": 1.4, "hp": 0.95, "sub": 0.55, "hair": "uzun", "top": Color(0.35, 0.3, 0.5), "v": "ame"},
]

## 2. aşama alanının adı ev sahibi köye göre: [ad, (yedek), "...ın" tamlaması, "...a gir" düğmesi]
const AREA := {"konoha": ["Ölüm Ormanı", "", "ormanın", "Ormana"], "suna": ["Ölüm Çölü", "", "çölün", "Çöle"],
	"kiri": ["Ölüm Bataklığı", "", "bataklığın", "Bataklığa"], "kumo": ["Ölüm Uçurumları", "", "uçurumların", "Uçurumlara"],
	"iwa": ["Ölüm Kanyonu", "", "kanyonun", "Kanyona"]}


func area_name() -> String:
	return String(AREA.get(host, AREA["konoha"])[0])


var stage = 0      # 0 yok, 1 yazılı, 2 orman, 3 ön eleme, 4 final yolu, 5 final, 9 seyahat
var host = "konoha"
var rivals: Array = []
var team: Array = []
var st := {}


func p() -> Dictionary:
	return Game.profile


func _flags() -> Dictionary:
	return Exams.flags()


## Bu dönemin ev sahibi: ilk sınav Konoha'da, sonrakiler sırayla
func current_host() -> String:
	var n = int(_flags().get("chunin_attempts", 0))
	var h = HOSTS[n % HOSTS.size()]
	return h if not Game.village(h).is_empty() else "konoha"


## Ev sahibinin stadyumu (Konoha'da gerçek stadyum; diğerlerinde köy içi arena noktası)
func stadium_pos(vid := "") -> Vector3:
	if vid == "":
		vid = host
	if vid == "konoha":
		for it in Interact.items:
			if it.get("kind", "") == "chunin_exam":
				return it["pos"] + Vector3(0, 0, -84)
	var v = Game.village(vid)
	if BuildVillageStory.STYLE.has(vid):
		var s: Vector2 = BuildVillageStory._sites(v)["stadium"]   # köyün kalıcı stadyumu
		return Game.from_map(s)
	return Game.from_map(Vector2(float(v["x"]) + float(v["r"]) * 0.35, float(v["y"]) - float(v["r"]) * 0.2))


func forest_center() -> Vector3:
	if host == "konoha" and not Game.village("forest_death").is_empty():
		var fd = Game.village("forest_death")
		return Game.from_map(Vector2(fd["x"], fd["y"]))
	if BuildVillageStory.STYLE.has(host):
		return Game.from_map(BuildVillageStory.exam_ground(Game.village(host)))   # köyün kalıcı sınav kulesi
	var s = Missions._spot(host, 600, 900)
	return Game.from_map(Vector2(s[0], s[1]))


func apply() -> void:
	var pr = p()
	if int(pr["rank"]) >= 2:
		Hud.dialog("Sınav Gözetmeni", "Sen zaten bir Chūnin'sin. Finallere izleyici olarak gelebilirsin!", [])
		return
	if stage != 0:
		Hud.dialog("Sınav Gözetmeni", "Sınav devam ediyor. Hedefine odaklan!", [])
		return
	var md: Dictionary = pr.get("missions_done", {})
	var nd = int(md.get("D", 0))
	var nc = int(md.get("C", 0))
	if int(pr["level"]) < 15 or Progress.story() < Journal.FREE or nd < 8 or nc < 4:
		# rütbe yalnız Güç kasarak gelmez: görev tecrübesi şart (kullanıcı: "hiç görev yapmadan rütbe alıyorum")
		Hud.dialog("Sınav Gözetmeni", "Chūnin Sınavı için: Güç 15 (%d), 8 D-rank görev (%d) ve 4 C-rank görev (%d) gerekli. Hocan seni ancak sahada kendini kanıtlayınca önerir." % [int(pr["level"]), nd, nc], [])
		return
	host = current_host()
	var hn = String(Game.village(host).get("name", host))
	Hud.dialog("Sınav Gözetmeni", "Bu dönemin Chūnin Sınavı %s'de. Takım arkadaşlarınla birlikte yaralanma ve ölüm feragatnamesini imzalamalısın. Hile ve zor kullanmak serbest; çekilmek ayıp değil. Kayıt olmak istiyor musun?" % hn, [
		{"label": "İmzala ve kaydol", "cb": _register},
		{"label": "Henüz hazır değilim", "cb": func(): pass}])


func _register() -> void:
	Journal.add("Chūnin Sınavı'na kaydoldun.", "exam")
	_flags()["chunin_attempts"] = int(_flags().get("chunin_attempts", 0)) + 1
	st = {"written": 0, "forest_days": 0.0, "prelim_wins": 0, "final_wins": 0, "jutsu": {}, "kawarimi": 0, "hp_lost": 0.0, "invasion": false, "mates_alive": 2}
	var sp = stadium_pos()
	if Game.player.global_position.distance_to(sp) > 400.0:
		stage = 9
		Missions.target_marker = sp
		Missions.has_marker = true
		Missions.target_name = "Chūnin Sınavı — %s" % Game.village(host).get("name", host)
		Game.profile["active_mission"] = {"exam": "chunin", "title": "Chūnin Sınavı", "desc": "Ev sahibi köye (%s) git; sınav salonu stadyumun yanında." % Game.village(host).get("name", host), "type": "story", "rank": "C", "count": 1, "progress": 0}
		Hud.objective_changed()
		Hud.banner("CHŪNİN SINAVI", "Ev sahibi: %s — yola çık!" % Game.village(host).get("name", host), Color(1, 0.75, 0.3))
		return
	_written()


# ------------------------------------------------------------------ 1. aşama: yazılı sınav
func _cheat_level() -> int:
	var pr = p()
	var L: Dictionary = pr.get("look", {})
	if L.get("eye_r") != null or L.get("eye_l") != null:
		return 2
	if String(pr.get("specialty", "")) == "sensor" or String(pr.get("clan", "")) in ["hyuga", "uchiha", "aburame", "yamanaka", "inuzuka", "kurama"]:
		return 2
	return 1


func _written() -> void:
	stage = 1
	var pool = QUIZ.duplicate()
	pool.shuffle()
	Hud.dialog("Baş Gözetmen", "1. AŞAMA — YAZILI SINAV. Dokuz soru, bir saat... yani 3 dakika. Her kopya girişimi yakalanırsa iki puan silinir; üç kez yakalanan takımıyla birlikte çıkar. Onuncu soruyu sona sakladım. Başlayın!", [{"label": "Kâğıdı çevir", "cb": func():
		ExamUI.written({"title": "Chūnin Seçme Sınavı — Yazılı", "subtitle": "Kopya çekmek serbest... yakalanmamak şartıyla. (Gözetmenler her şeyi görür.)", "questions": pool.slice(0, 9), "time": 180.0,
			"cheat": _cheat_level(), "q10": true}, _written_done)}])


func _written_done(r: Dictionary) -> void:
	st["written"] = maxi(0, int(r["correct"]) - int(r["caught"]) * 2)
	if r.get("q10", "") != "kabul":
		stage = 0
		Journal.add("Chūnin Sınavı'nın yazılı aşamasında çekilmeyi seçtin.", "exam")
		Game.profile["active_mission"] = {}
		Hud.objective_changed()
		Hud.dialog("Baş Gözetmen", "Çekilmeyi seçtin. Bu da bir karardır... ama bir chūnin, takımı için bilinmezliğe adım atabilmeli. Bir sonraki dönem tekrar dene.", [])
		return
	Hud.dialog("Baş Gözetmen", "Onuncu soru... yoktu. Asıl soru, bilinmeyen bir tehlikeye takımını götürme cesaretiydi. Kalan herkes GEÇTİ! (Yazılı puanın: %d)\n\n2. AŞAMA — %s. Takımına bir parşömen veriyoruz; diğerini rakiplerden alıp 5 gün içinde %s ortasındaki kuleye ulaşın. Parşömenleri kulede açın, önce değil!" % [st["written"], area_name().to_upper(), AREA.get(host, AREA["konoha"])[2]], [{"label": "%s gir" % AREA.get(host, AREA["konoha"])[3], "cb": _forest}])


# ------------------------------------------------------------------ 2. aşama: Ölüm Ormanı
func _forest() -> void:
	stage = 2
	var c = forest_center()
	var have = ["heaven", "earth"].pick_random()
	st["need"] = "earth" if have == "heaven" else "heaven"
	st["field"] = _build_field()
	st["forest_t"] = 5.0 * DAY_LEN
	st["day"] = 1
	st["tower"] = c
	var inv: Dictionary = p()["inventory"]
	inv.erase("scroll_heaven")
	inv.erase("scroll_earth")
	inv["scroll_" + have] = 1
	# girişe ışınla: ormanın KENARI (kuleye yürünür; eskiden kulenin dibinde başlıyordu)
	var fr = _forest_r()
	var start_a = randf() * TAU
	var start = c + Vector3(cos(start_a), 0, sin(start_a)) * fr * 0.85
	start = Missions.open_ground(start, 30.0)
	start.y = Game.ground_height(start.x, start.z)
	Game.player.respawn(start + Vector3.UP * 0.5)
	Exams._clear_nodes()
	team = Exams.spawn_teammates(start, 2, maxi(10, int(p()["level"])))
	rivals.clear()
	# rakip takımların kampları ormana dağılır; oyuncu yaklaşınca doğarlar (uzakta arazi çarpışması yokken düşüp kayboluyorlardı)
	st["camps"] = []
	for t in 4:
		var ang = start_a + PI * 0.5 + TAU * t / 4.0 + randf_range(-0.3, 0.3)
		var tc = c + Vector3(cos(ang), 0, sin(ang)) * fr * randf_range(0.35, 0.7)
		st["camps"].append({"pos": [tc.x, tc.y, tc.z], "carrier": t < 3, "i": t, "spawned": false})
	_mark(c, "%s — Kule" % area_name())
	Game.profile["active_mission"] = {"exam": "chunin", "title": area_name(), "desc": "%s Parşömeni'ni rakip takımlardan al (✉) ve 5 gün içinde kuleye ulaş." % ("Yer" if st["need"] == "earth" else "Gök"), "type": "story", "rank": "C", "count": 1, "progress": 0}
	Hud.objective_changed()
	Hud.banner(area_name().to_upper(), "Gün 1 / 5 — elinde %s Parşömeni var" % ("Gök" if have == "heaven" else "Yer"), Color(0.5, 0.85, 0.4))


## Sınav adayları — sabit liste yok, her dönem yeni insanlar (anime: her köyden, her tarzdan aday):
## köy dünyadaki 15 köyden biri; isim hece + aile kökünden üretilir; klan bütün oynanabilir klanlardan (ya da klansız);
## DÖVÜŞ ODAĞI (ninjutsu / taijutsu / kenjutsu / genjutsu / fūinjutsu / tıbbi / klan hiden) ve kit oyunun jutsu verisinden süzülür:
## yalnız klansız teknikler + ADAYIN KENDİ klanının teknikleri; kanon karakter imza teknikleri, göz/kekkei genkai/sennin/kontrat şartlı
## teknikler yok; silahlı odakta yalnız dükkânda satılan sıradan silahlar (efsanevi / karaktere bağlı / klan silahı yok).
## Sahada sokakta tanıdığın köy takımları (AmbientTeams.roster) ve önceki dönemde kalıp yeniden giren adaylar (profile.exam_pool) de olur.
const _AT = preload("res://scripts/world/ambient_teams.gd")
const _MORA := ["a", "ka", "ki", "ku", "ke", "ko", "sa", "shi", "su", "se", "so", "ta", "chi", "tsu", "te", "to", "na", "ni", "no", "ha", "hi", "fu",
	"ho", "ma", "mi", "mu", "me", "mo", "ya", "yu", "yo", "ra", "ri", "ru", "re", "ro", "wa", "ga", "gi", "go", "za", "ji", "zu", "da", "do", "ba", "bi", "bu", "ei", "ō", "ū"]
const _END_M := ["ta", "ki", "to", "ru", "ji", "suke", "rō", "ma", "ya", "shi", "hiko", "zō", "kichi", "go", "nosuke", "ichi", "hei", "shin", "tarō", "ma"]
const _END_F := ["ko", "mi", "na", "ka", "e", "ri", "ne", "yo", "ho", "no", "sa", "ki", "ha", "ru", "yu", "e", "mi", "ka", "ri", "na"]
const _FAM_A := ["Yama", "Kawa", "Mori", "Ishi", "Kuro", "Shira", "Taka", "Naka", "Hoshi", "Tsuki", "Kaze", "Mizu", "Hi", "Kane", "Ao", "Aka", "Sugi",
	"Matsu", "Take", "Fuji", "Hara", "Saka", "Tani", "Miya", "Ono", "Ina", "Kita", "Minami", "Nishi", "Higashi", "Sawa", "Hama", "Shima", "Oka", "Mura",
	"Kage", "Kiri", "Kumo", "Iwa", "Suna", "Asa", "Yoru", "Tora", "Washi", "Kitsune", "Sakura", "Ume", "Kiku", "Hasu", "Kusa", "Ame", "Yuki"]
const _FAM_B := ["moto", "mura", "yama", "kawa", "da", "no", "zaki", "shima", "hara", "saki", "gawa", "be", "oka", "tani", "sawa", "naga", "ki", "ba",
	"zawa", "hashi", "kubo", "mine", "zuka", "nami", "ide", "gaki", "wara", "sato", "mizu", "kage"]
const _HAIRS := ["kısa", "uzun", "kase", "dağınık", "topuz", "diken", "atkuyruğu"]
const _ELS := ["katon", "fuuton", "suiton", "doton", "raiton"]
const _EL_TR := {"katon": "Katon", "fuuton": "Fūton", "suiton": "Suiton", "doton": "Doton", "raiton": "Raiton"}
## odak -> jutsu kategorileri + açıklama
const _FOCUS := {
	"ninjutsu": [["ninjutsu"], "%s ninjutsusu"], "taijutsu": [["taijutsu"], "taijutsu ustası, yakın dövüşte acımasız"],
	"kenjutsu": [["kenjutsu", "taijutsu"], "%s ile kenjutsu"], "genjutsu": [["genjutsu", "ninjutsu"], "genjutsu kullanıcısı, aklını karıştırır"],
	"fuinjutsu": [["fuinjutsu", "ninjutsu"], "mühür ustası, bağlar ve kilitler"], "iryo": [["medical", "taijutsu"], "tıbbi ninja, yaralarını kapatır"],
	"hiden": [["hiden", "kekkei_genkai", "ninjutsu"], "klanının gizli teknikleri"]}
const _FOCUS_W := {"ninjutsu": 5, "taijutsu": 3, "kenjutsu": 3, "genjutsu": 2, "fuinjutsu": 1, "iryo": 1, "hiden": 4}
const _BAD_LEARN := ["eye:", "kg:", "sage:", "path:", "quest:", "beast", "contract", "legend"]
static var _users := {}


## Kanon kullanıcıları (Narutopedia bilgi kutusu, data/jutsu_users.json): "~game" (yalnız oyunda geçen) sayılmaz
static func _canon_users(id: String) -> int:
	if _users.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/jutsu_users.json"))
		_users = d if d is Dictionary else {"_": []}
	if not _users.has(id):
		return -1
	var n = 0
	for u in _users[id]:
		if not "~game" in String(u).to_lower():
			n += 1
	return n


static func gen_name(female: bool, rng: RandomNumberGenerator) -> String:
	var g = ""
	for k in (1 if rng.randf() < 0.55 else 2):
		g += _MORA[rng.randi() % _MORA.size()]
	var ends: Array = _END_F if female else _END_M
	g += ends[rng.randi() % ends.size()]
	return "%s %s" % [String(_FAM_A[rng.randi() % _FAM_A.size()]) + String(_FAM_B[rng.randi() % _FAM_B.size()]), g.capitalize()]


static func _pick_w(rng: RandomNumberGenerator, w: Dictionary) -> String:
	var tot = 0
	for k in w:
		tot += int(w[k])
	var r = rng.randi() % maxi(1, tot)
	for k in w:
		r -= int(w[k])
		if r < 0:
			return String(k)
	return String(w.keys()[0])


## Sıradan silahlar: dükkânda satılan, efsanevi / klan / karaktere bağlı / kaldırılmış olmayan
static func _plain_weapons() -> Array:
	var out = []
	for k in Gear.ITEMS:
		var it: Dictionary = Gear.ITEMS[k]
		if it.has("weapon") and not it.has("removed") and not it.has("legend") and not it.has("clan") and int(it.get("price", 0)) > 0 and int(it.get("price", 0)) <= 1500:
			out.append(String(k))
	return out


## Adayın kiti: odağın kategorilerinden, seviyesine uygun, yalnız klansız + kendi klanının teknikleri
static func _kit(focus: String, clan: String, el: String, el2: String, weapon: String, lv: int, rng: RandomNumberGenerator) -> Array:
	var cats: Array = _FOCUS[focus][0]
	var pool = []
	for id in Data.jutsu:
		var j = Data.jutsu[id]
		if not j is Dictionary:
			continue
		if not String(j.get("category", "")) in cats or int(j.get("level", 99)) > lv + 4:
			continue
		var jc = j.get("clan", "")
		var jclan = String(jc[0]) if jc is Array and not jc.is_empty() else String(jc) if jc is String else ""
		if jclan != "" and jclan != clan:
			continue   # başka klanın tekniği yok
		if focus == "hiden" and jclan == "":
			continue
		var rq = j.get("requires", {})
		if rq is Dictionary and not rq.is_empty() and not rq.has("clan_or_lineage"):
			continue   # göz / kekkei genkai / sennin şartlı
		var ln = String(j.get("learn", ""))
		var bad = false
		for b in _BAD_LEARN:
			if ln.begins_with(b):
				bad = true
		if bad or j.get("signature", false) or j.has("path") or j.has("virtual"):
			continue   # kanon karakter imza teknikleri / efsane yolları
		var nd = String(j.get("need", ""))
		if nd != "" and nd != "weapon:" + weapon:
			continue
		if jclan == "":
			# genin adayı: yalnız E/D/C/B rütbe ve kanonda en az 3 kişinin kullandığı (tek karaktere ait imza tekniği değil);
			# kanon kaydı yoksa yalnız akademi / temel element tekniği
			if String(j.get("canon_rank", "C")) in ["A", "S"]:
				continue
			var cu = _canon_users(String(id))
			if cu >= 0 and cu < 3:
				continue
			if cu < 0 and not ln in ["academy", "element"]:
				continue
		var jel = String(j.get("element", ""))
		if focus == "ninjutsu" and jel != "" and jel != el and jel != el2:
			continue
		pool.append(String(id))
	var out = []
	for k in mini(4, pool.size()):
		var x = pool[rng.randi() % pool.size()]
		pool.erase(x)
		out.append(x)
	return out


## Adayın kalıcı sınav kimliği
func _exam_id(rng: RandomNumberGenerator) -> Dictionary:
	var clans = []
	for cc in Data.clans:
		if cc != "none" and not cc in Progress.UNPLAYABLE_CLANS:
			clans.append(cc)
	var clan = "" if clans.is_empty() or rng.randf() < 0.3 else String(clans[rng.randi() % clans.size()])
	var fw = _FOCUS_W.duplicate()
	if clan == "":
		fw.erase("hiden")
	var focus = _pick_w(rng, fw)
	var el = String(_ELS[rng.randi() % _ELS.size()]) if focus != "taijutsu" else ""
	var el2 = String(_ELS[rng.randi() % _ELS.size()]) if el != "" and rng.randf() < 0.3 else ""
	if el2 == el:
		el2 = ""
	var weapon = ""
	if focus == "kenjutsu" or rng.randf() < 0.15:
		var ws = _plain_weapons()
		if not ws.is_empty():
			weapon = String(ws[rng.randi() % ws.size()])
	var lvl = rng.randi_range(13, 22)
	return {"el": el, "el2": el2, "focus": focus, "weapon": weapon, "lv": lvl, "kit": _kit(focus, clan, el, el2, weapon, lvl, rng),
		"power": rng.randf_range(1.22, 1.68), "hp": rng.randf_range(0.9, 1.2), "sub": rng.randf_range(0.15, 0.45), "tries": 0, "clan": clan}


func _cand_of(src: String, ti: int, pi: int, person: Dictionary) -> Dictionary:
	var look: Dictionary = Friends.look_of(person)
	var rng = RandomNumberGenerator.new()
	rng.seed = hash("%s:%d:%d:%s" % [src, ti, pi, person["name"]])
	if not person.has("exam") or not (person["exam"] as Dictionary).has("focus"):
		person["exam"] = _exam_id(rng)
	var ex: Dictionary = person["exam"]
	var vid = String(person.get("vid", src))
	var vn = String(Game.village(vid).get("name", vid))
	var focus = String(ex["focus"])
	var what = String(_FOCUS[focus][1])
	if "%s" in what:
		var w = String(Gear.item(String(ex["weapon"])).get("name", "silah")) if focus == "kenjutsu" else _EL_TR.get(String(ex["el"]), "Chakra")
		what = what % w
	if String(ex.get("el2", "")) != "":
		what += " + " + String(_EL_TR.get(String(ex["el2"]), ""))
	var cn = ClanWorld.clan_name(String(ex["clan"])) if String(ex["clan"]) != "" else ""
	var style = ("%s — %s" % [cn, what]) if cn != "" else what.capitalize()
	return {"name": "%s (%s)" % [person["name"], vn], "style": style, "el": ex["el"], "el2": ex.get("el2", ""), "j": ex.get("kit", []),
		"power": float(ex["power"]) + int(ex["tries"]) * 0.04, "hp": float(ex["hp"]) + int(ex["tries"]) * 0.03, "sub": ex["sub"],
		"hair": look.get("hair_style", "diken"), "top": look.get("top", Color(0.3, 0.4, 0.35)), "v": vid, "f": String(look.get("gender", "m")) == "f",
		"clan": String(ex.get("clan", "")), "weapon": String(ex.get("weapon", "")), "lv": int(ex.get("lv", 16)), "ref": [src, ti, pi]}


## Yepyeni bir genin takımı (rastgele köy, üretilmiş isimler ve görünüşler) — exam_pool'a yazılır
func _new_team() -> Dictionary:
	var vids = []
	for v in Game.world_info.get("villages", []):
		vids.append(String(v["id"]))
	if vids.is_empty():
		vids = ["konoha", "suna", "kiri", "kumo", "iwa"]
	var vid = String(vids.pick_random())
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var people = []
	for i in 3:
		var female = rng.randf() < 0.45
		var look = {"gender": "f" if female else "m", "hair_style": _HAIRS[rng.randi() % _HAIRS.size()],
			"hair": Color(rng.randf_range(0.03, 0.95), rng.randf_range(0.03, 0.8), rng.randf_range(0.03, 0.75)),
			"top": Color(rng.randf_range(0.1, 0.85), rng.randf_range(0.1, 0.8), rng.randf_range(0.1, 0.8))}
		var person = {"name": gen_name(female, rng), "rank": 0, "look": Friends._ser(look), "fid": "", "vid": vid}
		person["exam"] = _exam_id(rng)
		people.append(person)
	return {"vid": vid, "people": people}


## Bu dönemin sahası: 7 takım × 3 aday — 3-5 yepyeni takım, kalanı sokaktaki köy takımları ve önceki dönemden kalanlar karışık
func _build_field() -> Array:
	var pr = p()
	if not pr.has("exam_pool"):
		pr["exam_pool"] = []
	var pool: Array = pr["exam_pool"]
	var old = []
	for vid in ["konoha", "suna", "kiri", "kumo", "iwa"]:
		var ros: Array = _AT.roster(vid)
		for ti in ros.size():
			old.append([vid, ti, ros[ti]["people"]])
	for ti in pool.size():
		old.append(["pool", ti, pool[ti]["people"]])
	old.shuffle()
	var teams = []
	for k in 3 + randi() % 3:
		pool.append(_new_team())
		var ti = pool.size() - 1
		var t = []
		for pi in 3:
			t.append(_cand_of("pool", ti, pi, pool[ti]["people"][pi]))
		teams.append(t)
	for o in old:
		if teams.size() >= 7:
			break
		var t = []
		var ppl: Array = o[2]
		for pi in ppl.size():
			if int(ppl[pi].get("rank", 0)) == 0:
				t.append(_cand_of(o[0], o[1], pi, ppl[pi]))
		if t.size() >= 3:
			teams.append(t.slice(0, 3))
	while teams.size() < 7:
		pool.append(_new_team())
		var ti = pool.size() - 1
		var t = []
		for pi in 3:
			t.append(_cand_of("pool", ti, pi, pool[ti]["people"][pi]))
		teams.append(t)
	teams.shuffle()
	return teams


func _field() -> Array:
	if not st.has("field") or (st["field"] as Array).is_empty():
		st["field"] = _build_field()
	return st["field"]


func _person_of(ref: Array) -> Dictionary:
	if String(ref[0]) == "pool":
		var pool: Array = p().get("exam_pool", [])
		return pool[int(ref[1])]["people"][int(ref[2])] if int(ref[1]) < pool.size() else {}
	return _AT.roster(String(ref[0]))[int(ref[1])]["people"][int(ref[2])]


## Dönem sonu: finalistlerin bir kısmı chūnin olur (havuzdan çıkar), diğerleri bir dahaki dönem güçlenmiş döner; havuz şişmez
func _field_after() -> void:
	var fin_refs = []
	for r in st.get("finalists", []):
		if r.has("ref"):
			fin_refs.append(r["ref"])
	for team in _field():
		for r in team:
			if not r.has("ref"):
				continue
			var person = _person_of(r["ref"])
			if person.is_empty():
				continue
			if r["ref"] in fin_refs and randf() < 0.4:
				person["rank"] = 1
			elif person.has("exam"):
				person["exam"]["tries"] = int(person["exam"]["tries"]) + 1
	var pool: Array = p().get("exam_pool", [])
	while pool.size() > 40:
		pool.pop_front()


func _rival_enemy(r: Dictionary, scale: float, i := 0) -> Enemy:
	var e = Enemy.new()
	var a = Enemy.archetype("genin_rival", i)
	var lv = int(r.get("lv", randi_range(13, 22)))   # sınav rakipleri genin/chūnin adayı gücünde (adayın kalıcı seviyesi)
	a["name"] = r["name"]
	a["respawn"] = false
	a["level"] = lv
	a["hp"] = (180.0 + lv * 18.0) * float(r["hp"]) * scale
	a["power"] = float(r["power"]) * (0.8 + scale * 0.2)
	a["sub"] = float(r["sub"])
	a["element"] = r["el"]
	# imza jutsuları + seviyesine göre ek element jutsuları (eskiden tüm sınavda 3-4 jutsu atılıyordu)
	var js: Array = (r["j"] as Array).duplicate()
	for x in Enemy.auto_jutsu("rogue", String(r["el"]), lv):
		if not x in js and js.size() < 4:
			js.append(x)
	if String(r.get("el2", "")) != "":
		for x in Enemy.auto_jutsu("rogue", String(r["el2"]), lv):
			if not x in js and js.size() < 5:
				js.append(x)
	a["jutsu"] = js
	a["aggr"] = maxf(float(a.get("aggr", 0.5)), 0.75)
	a["look"]["hair_style"] = r["hair"]
	a["look"]["top"] = r["top"]
	a["look"]["village"] = r["v"]
	a["look"]["gender"] = "f" if r.get("f", false) else "m"
	a["look"]["age"] = "teen"   # Chūnin adayları genin: genç boyu (yetişkin boyunda çıkıyorlardı)
	if String(r.get("weapon", "")) != "":
		a["look"]["weapon_r"] = String(r["weapon"])   # kenjutsu adayı: sıradan dükkân silahı
	if String(r.get("clan", "")) != "":
		a["clan_force"] = String(r["clan"])   # adayın kendi klanı (her dönem aynı kişi aynı klanla)
	elif r.has("ref"):
		a["no_clan"] = true
	a["look"]["vest"] = null
	a["xp"] = 60 + lv * 4
	a["no_level"] = true   # sınav adayı: isim etiketinde seviye yok
	e.setup(a)
	e.set_meta("eyes_taken", true)   # sınavda ölen adayın gözleri alınamaz (gözetmenler var; saçma olur)
	get_tree().current_scene.add_child(e)
	Exams.nodes.append(e)
	return e


func _place(e: Node3D, at: Vector3) -> void:
	var it = Interiors.inst
	if it and it.inside != "":
		at.y = it.origin.y + 0.3   # iç mekân (kule ön eleme salonu gökte kurulu): dış zemin yüksekliği rakibi 1500 m aşağıya koyuyordu
	else:
		at.y = Game.ground_height(at.x, at.z)
	e.global_position = at
	e.home = at
	e.wander_to = at


func _mark(at: Vector3, nm: String) -> void:
	Missions.target_marker = at
	Missions.has_marker = true
	Missions.target_name = nm


func _forest_r() -> float:
	if host == "konoha" and not Game.village("forest_death").is_empty():
		return float(Game.village("forest_death").get("r", 500))
	return 450.0


func _spawn_camps() -> void:
	var pp = Game.player.global_position
	for cp in st.get("camps", []):
		if cp["spawned"]:
			continue
		var tc = Vector3(cp["pos"][0], cp["pos"][1], cp["pos"][2])
		if Vector2(tc.x - pp.x, tc.z - pp.z).length() > 140.0:
			continue
		cp["spawned"] = true
		for i in 3:
			var e = _rival_enemy(_field()[int(cp["i"])][i], 0.75, i)
			if cp["carrier"] and i == 0:
				e.set_meta("carries", st["need"])
				e.display_name += " ✉"
				if e.nameplate:
					e.nameplate.text = e.display_name
			_place(e, Missions.open_ground(tc + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8)), 12.0))
			rivals.append(e)


func _forest_tick(dt: float) -> void:
	Exams.follow_player(team)
	_spawn_camps()
	st["forest_t"] = float(st["forest_t"]) - dt
	var day = 6 - int(ceil(float(st["forest_t"]) / DAY_LEN))
	day = clampi(day, 1, 5)
	if day != int(st["day"]):
		st["day"] = day
		Hud.banner("GÜN %d / 5" % day, "Gece pusuları başlıyor, dikkat!", Color(0.6, 0.7, 1))
		var pp = Game.player.global_position
		for i in 2:
			var e = _rival_enemy((_field()[4 + randi() % 3] as Array).pick_random(), 0.6, i)
			e.display_name = "Pusucu " + e.display_name
			if i == 0:
				# kanon: her takım bir parşömen taşır (yarısı Gök, yarısı Yer) — pusucular parşömensizdi, kesen eli boş kalıyordu
				var need = String(st["need"])
				e.set_meta("carries", need if (randf() < 0.75 or day >= 3) else ("earth" if need == "heaven" else "heaven"))
				e.display_name += " ✉"
			if e.nameplate:
				e.nameplate.text = e.display_name
			_place(e, pp + Vector3(randf_range(-25, 25), 0, randf_range(-25, 25)))
			rivals.append(e)
	var have_both = int(p()["inventory"].get("scroll_heaven", 0)) > 0 and int(p()["inventory"].get("scroll_earth", 0)) > 0
	if not have_both:
		for r in rivals:
			if is_instance_valid(r) and r.dead and r.has_meta("carries") and not r.has_meta("looted"):
				r.set_meta("looted", true)
				var cr = String(r.get_meta("carries"))
				var nm = "Gök" if cr == "heaven" else "Yer"
				if cr == String(st["need"]):
					p()["inventory"]["scroll_" + cr] = 1
					Hud.banner("PARŞÖMEN ALINDI", "%s Parşömeni! İki parşömen de sende — kuleye git." % nm, Color(0.95, 0.85, 0.5))
					Sfx.play("coin")
				else:
					Hud.banner("YANLIŞ PARŞÖMEN", "Bu takım da %s Parşömeni taşıyordu — sende zaten var. Başka takım bul (✉)." % nm, Color(0.85, 0.7, 0.5))
		Hud.objective_progress("Gün %d/5  •  ⏰ %d sn  •  Gerekli: %s ✉" % [day, int(st["forest_t"]), "Yer" if st["need"] == "earth" else "Gök"])
	else:
		Hud.objective_progress("Gün %d/5  •  Kuleye ulaş!" % day)
		# yatay mesafe: Konoha'nın Ölüm Ormanı kulesi 40 m yarıçaplı; merkezine 30 m yaklaşmak imkânsızdı
		var tw: Vector3 = st["tower"]
		if Vector2(Game.player.global_position.x - tw.x, Game.player.global_position.z - tw.z).length() < 34.0 or st.get("at_tower", false):
			st["forest_days"] = float(st["forest_t"]) / DAY_LEN
			var alive = 0
			for m in team:
				if is_instance_valid(m) and not m.is_dead():
					alive += 1
			st["mates_alive"] = alive
			_prelims()
			return
	if float(st["forest_t"]) <= 0.0:
		_fail("Beş gün doldu. Kuleye ulaşamadınız; elendiniz.")


## Ölüm Ormanı kulesinin kapısı ([F] Merkez Kule)
func enter_tower() -> void:
	if stage != 2:
		Hud.dialog("Merkez Kule", "Kule kapısı mühürlü. Yalnızca Chūnin Sınavı'nın ikinci aşamasında, iki parşömeni de taşıyan takımlar girebilir.", [])
		return
	var inv: Dictionary = p()["inventory"]
	if int(inv.get("scroll_heaven", 0)) <= 0 or int(inv.get("scroll_earth", 0)) <= 0:
		Hud.dialog("Merkez Kule", "Gök ve Yer parşömenlerinin ikisi de olmadan kuleye giremezsin. Eksik olanı rakip takımlardan (✉) al.", [])
		return
	st["at_tower"] = true
	_forest_tick(0.0)


# ------------------------------------------------------------------ 3. aşama: ön elemeler
func _prelims() -> void:
	stage = 3
	for r in rivals:
		if is_instance_valid(r):
			r.queue_free()
	rivals.clear()
	var pool = []
	for k in range(4, 7):
		pool.append_array(_field()[k])
	pool.shuffle()
	st["opponents"] = [pool[0], pool[1]]
	st["finalists"] = [pool[2], pool[3], pool[4]]
	st["prelim_i"] = 0
	# kanon: ön elemeler kulenin içindeki salonda (dev el mührü heykeli, balkonlardan izleyen adaylar)
	var arena = st["tower"] + Vector3(0, 0, 60)
	if Interiors.inst:
		Interiors.inst.enter({"pos": st["tower"], "out": st["tower"] + Vector3(0, 0, 40), "room": "chunin_hall", "kind": "enter"})
		await get_tree().create_timer(1.6).timeout
		arena = Interiors.inst.origin + Vector3(0, 0, -Interiors.HALL_D * 0.5)
	else:
		Exams.make_arena(arena, 26.0, false)
	st["arena"] = arena
	Hud.dialog("Ön Eleme Gözetmeni", "Kuleye çok fazla takım ulaştı. Finaller için ön elemeler yapacağız: bire bir, kaybeden elenir. Takım arkadaşların da kendi maçlarında. İlk rakibin: %s — %s." % [pool[0]["name"], pool[0]["style"]],
		[{"label": "Eşleşmeleri gör", "cb": func():
			ExamUI.bracket("Ön Elemeler", [[p()["name"], pool[0]["name"], ""], [team_name(0), pool[5]["name"], team_name(0)], [team_name(1), pool[6]["name"], pool[6]["name"]], [p()["name"] + " / ?", pool[1]["name"], ""]],
				"Kazanan finale çıkar. Bir ay sonra ev sahibi stadyumda final turnuvası!", _next_prelim)}])


func team_name(i: int) -> String:
	if i < team.size() and is_instance_valid(team[i]):
		return String(team[i].display_name).replace(" (takım)", "")
	return ["Hayato", "Sayuri"][i % 2]


func _next_prelim() -> void:
	var i = int(st["prelim_i"])
	if i >= 2:
		_to_finals()
		return
	var r: Dictionary = st["opponents"][i]
	var arena: Vector3 = st["arena"]
	for m in team:
		if is_instance_valid(m):
			m.queue_free()
	team.clear()
	Game.player.respawn(arena + Vector3(0, 0.5, 12))
	Game.player.hp = Game.player.max_hp
	Game.player.chakra = Game.player.max_chakra
	var e = _rival_enemy(r, 1.0)
	_place(e, arena + Vector3(0, 0, -12))
	st["duel"] = e
	st["duel_hp0"] = Game.player.hp
	Hud.banner("ÖN ELEME %d" % (i + 1), "%s — %s" % [r["name"], r["style"]], Color(1, 0.6, 0.3))
	Hud.boss_bar(e)


# ------------------------------------------------------------------ 4. aşama: final turnuvası
func _to_finals() -> void:
	stage = 4
	if Interiors.inst and Interiors.inst.inside == "chunin_hall":
		await Interiors.inst.exit()
	var sp = stadium_pos()
	Hud.dialog("Ön Eleme Gözetmeni", "Finale kaldın! Bir ay boyunca hazırlan (zaman atlanır) ve %s stadyumuna gel. Final turnuvasını Kage'ler, daimyōlar ve tüm köy izleyecek." % Game.village(host).get("name", host), [])
	if Game.world:
		Game.world.env.time_of_day = 0.4
	_mark(sp, "Chūnin Finalleri — Stadyum")
	Game.profile["active_mission"] = {"exam": "chunin", "title": "Chūnin Finalleri", "desc": "Stadyuma git: final turnuvası.", "type": "story", "rank": "B", "count": 1, "progress": 0}
	Hud.objective_changed()


func _finals() -> void:
	stage = 5
	var sp = stadium_pos()
	st["arena"] = sp
	if host != "konoha" and not BuildVillageStory.STYLE.has(host):
		Exams.make_arena(sp, 34.0, true)
	Exams.spawn_audience(sp, 34.0, 40, host == "konoha" or BuildVillageStory.STYLE.has(host))
	var fin: Array = st["finalists"]
	st["final_i"] = 0
	ExamUI.bracket("Chūnin Final Turnuvası — %s" % Game.village(host).get("name", host),
		[[p()["name"], fin[0]["name"], ""], [team_name(0) if team_name(0) != "" else "Finalist", fin[1]["name"], ""], ["Yarı final", fin[2]["name"], ""]],
		"Jüri: Kage'ler ve daimyōlar. Kazanmak terfiyi garanti etmez; kaybetmek de engellemez. Taktik, liderlik ve kararlılık değerlendirilir.", _next_final)


func _next_final() -> void:
	var i = int(st["final_i"])
	var fin: Array = st["finalists"]
	if i >= 2:
		_judge()
		return
	var sp: Vector3 = st["arena"]
	Game.player.respawn(sp + Vector3(0, 0.5, 14))
	Game.player.hp = Game.player.max_hp
	Game.player.chakra = Game.player.max_chakra
	var r: Dictionary = fin[0] if i == 0 else fin[2]
	var e = _rival_enemy(r, 1.25)
	_place(e, sp + Vector3(0, 0, -14))
	st["duel"] = e
	st["duel_hp0"] = Game.player.max_hp
	Hud.banner("FİNAL — MAÇ %d" % (i + 1), "%s — %s" % [r["name"], r["style"]], Color(1, 0.5, 0.2))
	Hud.boss_bar(e)
	Sfx.play("roar", sp, 1.6, 0.4)


func _duel_tick() -> void:
	var e = st.get("duel")
	var pl = Game.player
	if e == null:
		return
	if not is_instance_valid(e) or e.is_dead():
		st["duel"] = null
		st["hp_lost"] = float(st["hp_lost"]) + maxf(0.0, 1.0 - pl.hp / pl.max_hp)
		if stage == 3:
			st["prelim_wins"] = int(st["prelim_wins"]) + 1
			st["prelim_i"] = int(st["prelim_i"]) + 1
			Hud.banner("KAZANDIN", "Gözetmen: Kazanan %s!" % p()["name"], UI.GOOD)
			get_tree().create_timer(2.5).timeout.connect(_next_prelim)
		else:
			st["final_wins"] = int(st["final_wins"]) + 1
			_after_final_match()
		return
	if pl.hp <= 1.0 or pl.hp < pl.max_hp * 0.04:
		# yenilgi: gözetmen maçı durdurur (ölüm yok)
		pl.hp = pl.max_hp * 0.3
		e.queue_free()
		st["duel"] = null
		Hud.boss_bar(null)
		Hud.banner("MAÇ BİTTİ", "Gözetmen maçı durdurdu.", UI.BAD)
		if stage == 3:
			_fail("Ön elemelerde elendin. Bir sonraki dönemde tekrar dene!")
		else:
			st["hp_lost"] = float(st["hp_lost"]) + 1.0
			_after_final_match()


func _after_final_match() -> void:
	st["final_i"] = int(st["final_i"]) + 1
	# finalde istila (Naruto hikâyesindeki Ses istilası) kaldırıldı: oyuncu kendi hikâyesini yaşar
	if false and int(st["final_i"]) == 1 and not st.get("invasion_done", false) and (int(_flags().get("chunin_attempts", 1)) <= 1 or randf() < 0.35):
		st["invasion_done"] = true
		Hud.dialog("Baş Gözetmen", "Ne oluyor?! Tribünlerde duman... Bu bir İSTİLA! Turnuva durduruldu — tüm ninjalar savunmaya!", [{"label": "Savaş!", "cb": func():
			Orgs.exam_invasion(st["arena"], _invasion_over)}])
		return
	get_tree().create_timer(2.5).timeout.connect(_next_final)


func _invasion_over(won: bool) -> void:
	st["invasion"] = won
	Hud.dialog(Progress.kage_title(host), "İstila püskürtüldü. Turnuva iptal edildi, ancak jüri adayları değerlendirmeye devam edecek." if won else "Köy ağır hasar aldı... yine de jüri kararını verecek.", [{"label": "Kararı bekle", "cb": _judge}])


func _judge() -> void:
	stage = 0
	_field_after()
	Exams._clear_nodes()
	Hud.boss_bar(null)
	var jcount = (st.get("jutsu", {}) as Dictionary).size()
	var hp_ratio = clampf(1.0 - float(st["hp_lost"]) / maxf(1.0, float(int(st["final_wins"]) + int(st.get("final_i", 1)))), 0.0, 1.0)
	var rows = [
		["Yazılı sınav", "%d / 9" % int(st["written"]), int(st["written"]) >= 5],
		["%s (kalan gün, takım)" % area_name(), "%.1f gün • %d/2" % [float(st["forest_days"]), int(st["mates_alive"])], float(st["forest_days"]) > 0.5],
		["Ön eleme galibiyeti", "%d" % int(st["prelim_wins"]), int(st["prelim_wins"]) >= 2],
		["Final galibiyeti", "%d" % int(st["final_wins"]), int(st["final_wins"]) >= 1],
		["Taktik çeşitliliği (farklı jutsu)", "%d" % jcount, jcount >= 3],
		["Kawarimi ile kaçış", "%d" % int(st["kawarimi"]), int(st["kawarimi"]) >= 2],
		["Hasar kontrolü", "%%%d" % int(hp_ratio * 100), hp_ratio >= 0.4],
		["İstilada köyü savunma", "Evet" if st["invasion"] else "—", st["invasion"]],
	]
	var score = int(st["written"]) + int(float(st["forest_days"]) * 3.0) + int(st["mates_alive"]) * 3 + int(st["prelim_wins"]) * 8 + int(st["final_wins"]) * 12
	score += mini(5, jcount) * 3 + mini(4, int(st["kawarimi"])) * 2 + int(hp_ratio * 10.0) + (15 if st["invasion"] else 0)
	var passed = score >= 50
	rows.append(["JÜRİ PUANI", "%d / 50" % score, passed])
	_flags().erase("chunin_stage")
	p()["inventory"].erase("scroll_heaven")
	p()["inventory"].erase("scroll_earth")
	Missions.has_marker = false
	Game.profile["active_mission"] = {}
	if passed:
		ExamUI.scorecard("Chūnin Sınavı — Jüri Kararı", rows, "Turnuvadaki stratejin ve liderliğin takdir topladı. Bugünden itibaren bir CHŪNİN'sin!", true, func():
			Progress.promote(2)
			Progress.add_xp(900)
			Progress.add_ryo(1500)
			Journal.add("Chūnin oldun! Jüri liderliğini takdir etti.", "milestone")
			Exams.exam_finished.emit("chunin", true))
	else:
		Journal.add("Chūnin Sınavı'nda jüri seni bu dönem terfi ettirmedi.", "exam")
		ExamUI.scorecard("Chūnin Sınavı — Jüri Kararı", rows, "Jüri seni bu dönem terfi ettirmedi. Güçlenip bir sonraki dönem tekrar katıl (ev sahibi sırayla değişir).", false, func():
			Exams.exam_finished.emit("chunin", false), "Tamam")
	Hud.objective_changed()


func _fail(text: String) -> void:
	stage = 0
	if st.has("field"):
		_field_after()
	Exams._clear_nodes()
	for r in rivals:
		if is_instance_valid(r):
			r.queue_free()
	rivals.clear()
	team.clear()
	Hud.boss_bar(null)
	p()["inventory"].erase("scroll_heaven")
	p()["inventory"].erase("scroll_earth")
	Missions.has_marker = false
	Game.profile["active_mission"] = {}
	Hud.objective_changed()   # sağdaki görev listesi temizlensin (süre dolunca/ölünce listede kalıyordu)
	Journal.add("Chūnin Sınavı'ndan elendin.", "exam")
	Hud.dialog("Sınav Gözetmeni", text, [])


func on_technique(id: String) -> void:
	if stage in [3, 5]:
		if id == "kawarimi":
			st["kawarimi"] = int(st["kawarimi"]) + 1
		else:
			st["jutsu"][id] = true


## Sınav aşaması kayda yazılmaz (rakipler/takım sahnede yaşar): oyun yeniden yüklenince stage 0 olur ama görev
## ("parşömeni al") kayıtta kalıyordu — ormanda kaçaklar doğuyor, ölünce sınav bitmiyordu. Yarım kalan sınav iptal edilir.
var _stale_t = 0.0
func _stale_check(dt: float) -> void:
	_stale_t -= dt
	if _stale_t > 0.0 or Game.profile.is_empty():
		return
	_stale_t = 1.0
	var am = Game.profile.get("active_mission", {})
	if not am is Dictionary or am.is_empty():
		return
	var titles = ["Chūnin Sınavı", "Chūnin Finalleri"]
	for a in AREA.values():
		titles.append(a[0])
	if String(am.get("exam", "")) != "chunin" and not String(am.get("title", "")) in titles:
		return
	var inv: Dictionary = p()["inventory"]
	inv.erase("scroll_heaven")
	inv.erase("scroll_earth")
	Missions.has_marker = false
	Game.profile["active_mission"] = {}
	Hud.objective_changed()
	Journal.add("Chūnin Sınavı yarıda kaldı.", "exam")
	Hud.dialog("Sınav Gözetmeni", "Sınav sen yokken sona erdi; yarıda kalan aday elenmiş sayılır. Bir sonraki dönem yeniden kaydolabilirsin.", [])


func _process(dt: float) -> void:
	if stage == 0:
		_stale_check(dt)
	if stage == 0 or Game.player == null or Game.paused:
		return
	match stage:
		9:
			if Game.player.global_position.distance_to(stadium_pos()) < 120.0:
				_written()
		2:
			_forest_tick(dt)
		3, 5:
			_duel_tick()
		4:
			if Game.player.global_position.distance_to(stadium_pos()) < 90.0:
				_finals()
