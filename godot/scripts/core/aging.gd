class_name Aging
## Yaş + vücut tipi. Tek oyun saati (profile "clock", sn) işler; herkesin doğum anı ("born_t") tutulur, yaş ondan çıkar.
## Görünüş CharacterModel'de (look "years" / "fat" / "mus"): evre boyu, ağaran saç, yüz çizgileri, kambur, göbek / kas.
## Güce ya da ölüme etkisi YOK (yalnız görünüş).

const YEAR := 450.0   # sn / yıl: WorldKin çocukları 5400 sn'de (12 yaş) genin olur, aynı takvim
const RANK_MIN := [0.0, 12.0, 16.0, 20.0, 20.0]     # rütbe atlayınca en az bu yaş
const RANK_START := [8.0, 12.0, 16.0, 22.0, 26.0]   # yaşı bilinmeyen eski kayıt
const GREY := Color(0.7, 0.7, 0.72)
const WHITE := Color(0.94, 0.94, 0.95)

static var _chk := 0.0
static var _shown := {}


static func clock() -> float:
	return float(Game.profile.get("clock", 0.0))


static func years(d: Dictionary) -> float:
	return (clock() - float(d.get("born_t", clock()))) / YEAR


static func set_years(d: Dictionary, y: float) -> void:
	d["born_t"] = clock() - y * YEAR


static func stage(y: float) -> String:
	return "child" if y < 12.0 else "teen" if y < 15.5 else "young" if y < 19.0 else "adult"


static func _h(seed_s: String, salt: int) -> float:
	return float(absi(hash("%s#%d" % [seed_s, salt])) % 10000) / 10000.0


# ---------------------------------------------------------------------- görünüş (CharacterModel.setup çağırır)
## look "years" varsa: evre, ağaran saç (kişiye göre 40-58 arası başlar), solan ten, çizgi ve yaşlılık oranları
static func apply_look(look: Dictionary) -> void:
	if not look.has("years") or look.get("aged", false):
		return
	var y = float(look["years"])
	look["aged"] = true   # aynı görünüm ikinci kez kurulursa (klon) saç bir daha ağarmasın
	if not look.has("age_fixed"):
		look["age"] = stage(y)
	var sd = String(look.get("age_seed", "x"))
	if look.get("hair") is Color:
		if not look.has("hair0"):
			look["hair0"] = look["hair"]
		var onset = 40.0 + _h(sd, 1) * 18.0
		var k = clampf((y - onset) / 18.0, 0.0, 1.0)
		var c: Color = look["hair0"]
		c = c.lerp(GREY, clampf(k * 1.5, 0.0, 1.0)).lerp(WHITE, clampf((k - 0.55) / 0.45, 0.0, 1.0))
		look["hair"] = c
	var old = smoothstep(55.0, 84.0, y)
	look["old"] = old
	look["lines"] = smoothstep(36.0, 72.0, y)
	if look.get("skin") is Color and old > 0.0:
		if not look.has("skin0"):
			look["skin0"] = look["skin"]
		var s: Color = look["skin0"]
		var g = s.get_luminance()
		look["skin"] = s.lerp(Color(g, g * 0.97, g * 0.95), 0.22 * old)


# ---------------------------------------------------------------------- oyuncu
static func player_years() -> float:
	var pr: Dictionary = Game.profile
	var rk = clampi(int(pr.get("rank", 0)), 0, 4)
	if not pr.has("born_t"):
		set_years(pr, float(RANK_START[rk]))
	var y = years(pr)
	if y < float(RANK_MIN[rk]):   # rütbe atladı: en az o rütbenin yaşı
		y = float(RANK_MIN[rk])
		set_years(pr, y)
	if rk == 0 and y > 11.9:      # Akademi öğrencisi mezun olana dek çocuk
		y = 11.9
		set_years(pr, y)
	return y


## Ömür: kişiye göre 76-92 yıl. Dolunca mezun çocuğun varsa yol ona geçer (Legacy.old_age)
static func lifespan() -> float:
	var pr: Dictionary = Game.profile
	if not pr.has("life"):
		pr["life"] = 76.0 + _h(String(pr.get("name", "?")), 11) * 16.0
	return float(pr["life"])


static func player_stage() -> String:
	return stage(player_years())


static func body() -> Dictionary:
	var pr: Dictionary = Game.profile
	if not pr.has("body") or not pr["body"] is Dictionary:
		pr["body"] = {"fat": 0.0, "mus": 0.0}
	return pr["body"]


## Oyuncunun görünen vücudu: Akimichi kanonda kalori klanı (tabanı dolgun)
static func player_shape() -> Vector2:
	var b = body()
	var fat = float(b["fat"])
	if String(Game.profile.get("clan", "")) == "akimichi":
		fat = clampf(0.5 + fat * 0.6, 0.2, 1.0)
	return Vector2(fat, float(b["mus"]))


static func dress_player(look: Dictionary) -> void:
	var y = player_years()
	var sh = player_shape()
	look["years"] = y
	look["age_seed"] = String(Game.profile.get("name", "oyuncu"))
	look["fat"] = sh.x
	look["mus"] = sh.y
	look.erase("aged")
	_shown = {"stage": stage(y), "y": y, "fat": sh.x, "mus": sh.y}


## Yemek: kilo (ramen, ev sofrası, bento)
static func feed(n: float) -> void:
	if Game.profile.is_empty():
		return
	var b = body()
	b["fat"] = clampf(float(b["fat"]) + n, -0.6, 1.0)


## Beden zorlandı (stamina harcaması): kas yapar, yağ yakar
static func effort(n: float) -> void:
	if Game.profile.is_empty() or n <= 0.0:
		return
	var b = body()
	var f = float(b["fat"])
	b["fat"] = clampf(f - n * 0.00003 * (1.0 if f > 0.0 else 0.25), -0.6, 1.0)
	b["mus"] = clampf(float(b["mus"]) + n * 0.00004 * (1.0 - float(b["mus"])), 0.0, 1.0)


## Vuruş / ağır antrenman: kas
static func train(n: float) -> void:
	if Game.profile.is_empty():
		return
	var b = body()
	b["mus"] = clampf(float(b["mus"]) + n * (1.0 - float(b["mus"])), 0.0, 1.0)


static func tick(dt: float) -> void:
	var pr: Dictionary = Game.profile
	pr["clock"] = clock() + dt
	var b = body()
	b["mus"] = maxf(0.0, float(b["mus"]) - dt * 0.000017)   # çalışmazsan günde ~0,02 erir
	_chk -= dt
	if _chk > 0.0:
		return
	_chk = 4.0
	var pl = Game.player
	if pl == null or not is_instance_valid(pl) or pl.get("model") == null or _shown.is_empty():
		return
	var y = player_years()
	if y >= lifespan() - 3.0:
		Legacy.old_age(y, lifespan())
	var sh = player_shape()
	var m = pl.model
	if stage(y) != String(_shown["stage"]):
		pl.rebuild_model()   # boy evresi değişti (çocuk -> genç -> yetişkin)
		return
	if absf(sh.x - float(_shown["fat"])) > 0.015 or absf(sh.y - float(_shown["mus"])) > 0.015:
		_shown["fat"] = sh.x
		_shown["mus"] = sh.y
		m.look["fat"] = sh.x
		m.look["mus"] = sh.y
		m.apply_shape()
	if y - float(_shown["y"]) >= 0.5 and y > 34.0:
		_shown["y"] = y
		m.refresh_years(y)


# ---------------------------------------------------------------------- dünya ninjaları (WorldPeople kaydı)
static func person_years(p: Dictionary) -> float:
	if not p.has("born_t"):
		var id = String(p.get("id", p.get("name", "?")))
		var rk = clampi(int(p.get("rank", 0)), 0, 3)
		var lo = [12.0, 16.0, 22.0, 30.0][rk]
		var span = [7.0, 20.0, 38.0, 40.0][rk]
		var r = _h(id, 3)
		# kendi ailen / eşin: yaşı senin yaşına bağlı
		var kin = String(p.get("kin", ""))
		var me = player_years()
		if p.get("child", false) or p.get("pupil", false):
			set_years(p, clampf(12.0 + r * 3.0, 12.0, maxf(12.0, me - 15.0)) if p.get("child", false) else 12.0 + r * 3.0)
			return years(p)
		if kin in ["baba", "anne"]:
			set_years(p, me + 23.0 + r * 9.0)
			return years(p)
		if kin == "kardeş":
			set_years(p, maxf(6.0, me + (2.0 + r * 3.0) * (1.0 if p.get("elder", false) else -1.0)))
			return years(p)
		if String(p.get("romance", "")) in ["sevgili", "eş"] or p.has("squad_key") and String(p.get("squad_key", "")) != "sensei":
			set_years(p, maxf(12.0, me - 2.0 + r * 4.0))
			return years(p)
		set_years(p, lo + span * pow(r, 1.3) + float(p.get("level", 20)) / 200.0 * 6.0)
	return years(p)


## Kişinin vücudu: doğuştan yapı (sabit tohum) + bugünkü hâli (Güç'ü arttıkça kaslanır, yaş aldıkça kilo alır)
static func person_shape(p: Dictionary) -> Vector2:
	var id = String(p.get("id", p.get("name", "?")))
	var y = person_years(p)
	var r1 = _h(id, 5)
	var fat = -0.45 + r1 * 0.7
	if _h(id, 6) < 0.07:
		fat = 0.4 + r1 * 0.5   # nadiren iri yapılı ninja
	if String(p.get("clan", "")) == "akimichi":
		fat = 0.55 + r1 * 0.45
	fat += clampf((y - 35.0) / 40.0, 0.0, 0.3)
	var mus = float(p.get("level", 20)) / 200.0 * 0.6 + (_h(id, 7) - 0.35) * 0.5
	if String(p.get("village", "")) == "kumo":
		mus += 0.15   # Kumo: iri, kaslı yapı (Raikage, Darui, Killer B)
	return Vector2(clampf(fat, -0.6, 1.0), clampf(mus, 0.0, 1.0))


static func dress_person(look: Dictionary, p: Dictionary) -> void:
	var sh = person_shape(p)
	look["years"] = person_years(p)
	look["age_seed"] = String(p.get("id", p.get("name", "?")))
	look["fat"] = sh.x
	look["mus"] = sh.y
	look.erase("aged")


# ---------------------------------------------------------------------- kayıtsız kişiler (köylü, görev kişisi)
## Evresi verilmişse o evrenin içinde, yoksa yetişkin nüfus dağılımından bir yaş; yapı işe göre (job: 0..1 beden işi)
static func dress_civil(look: Dictionary, labor := 0.2, elder := false) -> void:
	if look.has("years"):
		return
	var st = String(look.get("age", "adult"))
	var y: float
	match st:
		"child":
			y = randf_range(6.0, 11.5)
		"teen":
			y = randf_range(12.0, 15.4)
		"young":
			y = randf_range(15.6, 18.9)
		_:
			y = randf_range(66.0, 86.0) if elder else 19.0 + 60.0 * pow(randf(), 1.7)
	look["years"] = y
	look["age_seed"] = str(randi())
	var r = randf()
	look["fat"] = clampf(-0.45 + r * r * 1.5 - labor * 0.3 + clampf((y - 35.0) / 40.0, 0.0, 0.3), -0.6, 1.0)
	look["mus"] = clampf(labor * 0.7 + randf_range(-0.1, 0.25), 0.0, 1.0)
