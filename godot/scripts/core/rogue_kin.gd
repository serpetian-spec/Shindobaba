class_name RogueKin
extends RefCounted
## Kaçak hayatında aile: köyden kaçınca ailen köyde kalır.
## · Gizli ziyaret: yalnız gece, kendi evine süzülürsün — irkilir, kapıyı kapattırır, sarılır (HomeLife._rogue_arrive);
##   sofra / uyku aynen; sofraya para kesesi bırakabilirsin; eşine "benimle gel" diyebilirsin (çocuk yoksa gelir → sığınağında yaşar).
## · Sorgu: ANBU arada bir aileni sorguya çeker. Bağınız sağlamsa (ya da para bıraktıysan) seni korur; değilse konuşur →
##   av-ninjaları hemen izini bulur. Sonraki ziyaretinde olanı kendi ağzından dinlersin.
## · Gözetleme: sık ziyaret evi şüpheli yapar; evden çıkınca av-ninjaları peşine düşebilir (köyden çıkar çıkmaz).

const ASK_GAP := [900.0, 1500.0]

static var _was_home := false


static func pr() -> Dictionary:
	return Game.profile


static func st() -> Dictionary:
	if not pr().has("rogue_kin") or not pr()["rogue_kin"] is Dictionary:
		pr()["rogue_kin"] = {"t": 0.0, "next": randf_range(ASK_GAP[0], ASK_GAP[1]), "asked": 0, "told": 0, "care": 0, "visits": 0.0, "leak": false}
	return pr()["rogue_kin"]


## Kaçakken: bu yakının gece evde mi (köyde kalmış, sağ, gözaltında değil)
static func at_home(id: String) -> bool:
	if id == "" or not Friends.all().has(id):
		return false
	var f: Dictionary = Friends.all()[id]
	if String(f.get("status", "")) != "" or f.get("party", false) or Time.get_unix_time_from_system() < float(f.get("away", 0.0)):
		return false
	return HomeLife.night()


static func tick(dt: float) -> void:
	if pr().is_empty() or Game.player == null:
		return
	var home_now = is_instance_valid(HomeLife.cur)
	if not Orgs.is_rogue():
		_was_home = home_now
		return
	var s = st()
	s["visits"] = maxf(float(s.get("visits", 0.0)) - dt / 900.0, 0.0)
	# evden çıkış: ev gözetleniyor muydu?
	if _was_home and not home_now and float(s.get("visits", 0.0)) > 0.0:
		var p = clampf(0.1 + 0.12 * (float(s["visits"]) - 1.0), 0.05, 0.6)
		if randf() < p:
			Orgs._hunter_t = Orgs._hunter_next   # köyden çıkar çıkmaz
			Hud.msg("Sokağın ucunda bir gölge kıpırdadı... Ev gözetleniyordu. Köyden çıkınca peşine düşecekler.", Color(1.0, 0.6, 0.5), 7.0)
	_was_home = home_now
	var hid = HomeLife.host_id()
	if hid == "" or String(Friends.all()[hid].get("status", "")) != "":
		return
	s["t"] = float(s.get("t", 0.0)) + dt
	if float(s["t"]) < float(s.get("next", 1200.0)):
		return
	s["t"] = 0.0
	s["next"] = randf_range(ASK_GAP[0], ASK_GAP[1])
	interrogate(hid)


## ANBU sorgusu (sen yokken): sonucu sonraki ziyarette öğrenirsin
static func interrogate(hid: String) -> void:
	var s = st()
	var f: Dictionary = Friends.all()[hid]
	s["asked"] = int(s.get("asked", 0)) + 1
	var strong = int(f.get("bond", 0)) >= 50 or int(s.get("care", 0)) > 0
	var covers = randf() < (0.9 if strong else 0.3)
	s["leak"] = not covers
	s["care"] = maxi(int(s.get("care", 0)) - 1, 0)
	Friends.log_event(f, "ANBU seni sordu; " + ("hiçbir şey söylemedi" if covers else "dayanamadı, konuştu"))
	if not covers:
		Orgs._hunter_t = Orgs._hunter_next   # izini buldular


## Para bırakıldı: ailen daha rahat, sorguda daha dirençli
static func on_gift() -> void:
	st()["care"] = int(st().get("care", 0)) + 2


static func on_visit() -> void:
	st()["visits"] = float(st().get("visits", 0.0)) + 1.0
