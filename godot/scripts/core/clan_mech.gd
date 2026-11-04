class_name ClanMech
extends RefCounted
## Animedeki klan kurallarının mekanikleri (yalnız animede gerçekten bir kural/bedel olan klanlar):
## - Akimichi: kalori kaynak — beden teknikleri kalori yakar, yemekle dolar; Chō Mōdo bütün kaloriyi yakar.
##   Üç renkli Akimichi hapları sırayla (yeşil Hōrenzai -> sarı Karē -> kırmızı Tōgarashi): güç patlaması, kırmızı hap Kelebek Modunu açar ama bedeni tüketir.
## - Aburame: bedendeki kikaichū kolonisi sınırlı — böcek teknikleri koloniden harcar, böcekler chakra yiyerek çoğalır, ateş böcekleri yakar.
## - Inuzuka: ninken ortağı her zaman yanında; seviyeyle büyür (yavru -> dev köpek); ortak teknikler köpek yanındayken yapılır, yaralanırsa bir süre sonra döner.
## (Nara gölgesi ışığa bağlı: Jutsu.shadow_k; Hyūga Byakugan kör noktası: PlayerCombat; Senju/Uzumaki yaşam gücü: Player; Shintenshin bedeli: Jutsu)

const KALORI_MAX := 100.0
const KOLONI_MAX := 100.0
## Hōzuki (kanon): Suika bedeni sürekli su ister (Suigetsu/Mangetsu matara taşır) — su teknikleri ve sıvılaşma su harcar
const SU_MAX := 100.0
const SUIKA_HIT_COST := 8.0
const AKI_PILLS := ["hap_horenzai", "hap_kare", "hap_togarashi"]
const NINKEN_RESPAWN := 45.0
## Kakuzu (Toprak Kini Yolu): maskeli kalbin istediği doğa
const MASKS := {"kakuzu_maske_katon": "katon", "kakuzu_maske_futon": "fuuton", "kakuzu_maske_raiton": "raiton", "kakuzu_maske_suiton": "suiton"}
const HEART_MAX := 4
## ortak (köpekle yapılan) Inuzuka teknikleri
const DOG_COMBO := ["gatsuga", "garoga", "jujin_bunshin", "inuzuka_sototoro"]

static var _dog_t := 0.0
static var _pill_gift_t := 0.0


static func clan() -> String:
	return String(Game.profile.get("clan", "")) if not Game.profile.is_empty() else ""


static func jutsu_clan(j: Dictionary) -> String:
	var lp = String(j.get("learn", ""))
	if lp.begins_with("clan:"):
		return lp.substr(5)
	return String(j.get("clan", ""))


# ------------------------------------------------------------------ HUD göstergesi
static func meter() -> Dictionary:
	var pr = Game.profile
	if "byakugo_no_in" in pr.get("learned", []) and not clan() in ["akimichi", "aburame", "inuzuka"] and pr.get("kakuzu_hearts", []).is_empty():
		return {"label": "Byakugō", "v": float(pr.get("byakugo", 0.0)), "max": 100.0, "col": Color(0.65, 0.35, 0.9)}
	var hs: Array = pr.get("kakuzu_hearts", [])
	if not hs.is_empty() and not clan() in ["akimichi", "aburame", "inuzuka"]:
		var nm = {"katon": "Ateş", "fuuton": "Rüzgâr", "raiton": "Şimşek", "suiton": "Su", "doton": "Toprak"}
		return {"label": "Kalpler: " + ", ".join(hs.map(func(h): return nm.get(h, h))), "v": float(hs.size()), "max": float(HEART_MAX), "col": Color(0.75, 0.15, 0.2)}
	match clan():
		"akimichi":
			return {"label": "Kalori", "v": float(pr.get("kalori", KALORI_MAX)), "max": KALORI_MAX, "col": Color(1.0, 0.62, 0.2)}
		"aburame":
			return {"label": "Kikaichū", "v": float(pr.get("kikaichu", KOLONI_MAX)), "max": KOLONI_MAX, "col": Color(0.35, 0.55, 0.3)}
		"hozuki":
			return {"label": "Su", "v": float(pr.get("su", SU_MAX)), "max": SU_MAX, "col": Color(0.35, 0.7, 1.0)}
		"inuzuka":
			var d = dog()
			if d:
				return {"label": String(pr.get("ninken_name", "Ninken")), "v": float(d.hp), "max": float(d.max_hp), "col": Color(0.92, 0.88, 0.8)}
			return {"label": "%s (dönüyor %ds)" % [String(pr.get("ninken_name", "Ninken")), int(maxf(0.0, _dog_t))], "v": 0.0, "max": 1.0, "col": Color(0.6, 0.55, 0.5)}
	return {}


# ------------------------------------------------------------------ teknik atma şartı / bedeli
static func cast_block(jid: String, j: Dictionary) -> String:
	var pr = Game.profile
	var jc = jutsu_clan(j)
	if jid == "indora_no_ya" and TailedBeasts.held().size() + TailedBeasts.jarred().size() < 9:   # kanon: dokuz canavarın çakrasını emen Sasuke
		return "Indora no Ya dokuz kuyruklu canavarın çakrasıyla yapılır (%d/9)." % (TailedBeasts.held().size() + TailedBeasts.jarred().size())
	if jid in ["shinra_tensei", "bansho_ten_in", "tendo", "chibaku_tensei"] and Game.player and Jutsu.tendo_wait(Game.player) > 0.0:   # Tendō dolumu (kanon: en az 5 sn)
		return "Tendō dolmadı — itme ve çekme peş peşe yapılamaz (%.1f sn)" % Jutsu.tendo_wait(Game.player)
	if jid == "byakugo_no_in" and float(pr.get("byakugo", 0.0)) < 50.0:
		return "Byakugō mührüne henüz yeterli chakra birikmedi (%d/50) — mühür zamanla dolar." % int(pr.get("byakugo", 0.0))
	if jid == "sozo_saisei" and not Buffs.has("byakugo") and float(pr.get("byakugo", 0.0)) < 30.0:
		return "Sōzō Saisei mühürde biriken chakrayla yapılır: Byakugō açık olmalı ya da mühürde en az 30 birikim."
	if MASKS.has(jid) and not MASKS[jid] in pr.get("kakuzu_hearts", []):
		return "Bu maske için çalınmış bir %s kalbi gerek (Jiongu: Shinzō Ubai)." % Elements.NAMES.get(MASKS[jid], MASKS[jid])
	match clan():
		"akimichi":
			if jc == "akimichi":
				var need = kalori_cost(jid, j)
				if jid == "cho_modo" and Buffs.has("hap_togarashi"):
					return ""
				if float(pr.get("kalori", KALORI_MAX)) < need:
					return "Kalorin yetmiyor (%d gerekli) — bir şeyler ye ya da Akimichi hapı al [Y]." % int(need)
		"aburame":
			if jc == "aburame" and float(pr.get("kikaichu", KOLONI_MAX)) < koloni_cost(j):
				return "Kikaichū kolonin yetersiz — böceklerin çoğalmasını bekle."
		"hozuki":
			if jc == "hozuki" and float(pr.get("su", SU_MAX)) < su_cost(j):
				return "Bedenindeki su azaldı — mataradan iç, yağmura ya da suya gir."
		"inuzuka":
			if jid in DOG_COMBO and dog() == null:
				return "%s yanında değil — ortak teknik köpeğinle yapılır." % String(pr.get("ninken_name", "Ninken"))
	# Tate Eboshi (kanon): Hōzuki bir su kaynağıyla birleşip dalgayı oradan kaldırır
	if jid == "suiton_tate_eboshi" and Game.player and not water_near(Game.player.global_position):
		return "Tate Eboshi için yakında su olmalı (göl/deniz, yağmur ya da ıslak zemin)."
	if jid == "hyoton_spears" and Game.player and not water_near(Game.player.global_position):   # Sensatsu Suishō (kanon): iğneler yakındaki sudan
		return "Sensatsu Suishō için yakında su olmalı (göl/deniz, yağmur ya da ıslak zemin)."
	return ""


static func kalori_cost(jid: String, j: Dictionary) -> float:
	if jid == "cho_modo":
		return 80.0   # Kelebek Modu bütün kaloriyi yakar
	return float(j.get("cost", 20)) * 0.5


static func koloni_cost(j: Dictionary) -> float:
	return float(j.get("cost", 20)) * 0.8


static func su_cost(j: Dictionary) -> float:
	return float(j.get("cost", 20)) * 0.6


## Yakında su kaynağı: deniz/göl (arazi su seviyesinin altında), yağmur ya da ıslak zemin (su jutsularının birikintisi)
static func water_near(pos: Vector3, r := 9.0) -> bool:
	if Game.world and Game.world.env and String(Game.world.env.weather) == "yağmur":
		return true
	if GroundFX.kind_at(pos) == "wet":
		return true
	for k in 9:
		var q = pos if k == 8 else pos + Vector3(cos(k * TAU / 8.0), 0, sin(k * TAU / 8.0)) * r
		if Game.terrain_height(q.x, q.z) < -0.3:
			return true
	return false


## Hōzuki suyu dolar: suyun içinde/üstünde hızla, yağmurda orta, sırtta matara taşırken yavaş (yudumlar)
static func su_refill(pos: Vector3, swimming: bool, has_flask: bool) -> float:
	var r = 0.0
	if swimming or Game.terrain_height(pos.x, pos.z) < -0.3:
		r = 25.0
	elif Game.world and Game.world.env and String(Game.world.env.weather) == "yağmur":
		r = 6.0
	if has_flask:
		r = maxf(r, 1.5)
	return r


static func pay(jid: String, j: Dictionary) -> void:
	var pr = Game.profile
	if jid == "byakugo_no_in":
		pr["byakugo_used"] = float(pr.get("byakugo", 0.0))
		pr["byakugo"] = 0.0
	elif jid == "sozo_saisei" and not Buffs.has("byakugo"):
		pr["byakugo"] = maxf(0.0, float(pr.get("byakugo", 0.0)) - 30.0)
	var jc = jutsu_clan(j)
	if clan() == "akimichi" and jc == "akimichi":
		if jid == "cho_modo" and not Buffs.has("hap_togarashi"):
			pr["kalori"] = 0.0
		else:
			pr["kalori"] = maxf(0.0, float(pr.get("kalori", KALORI_MAX)) - kalori_cost(jid, j))
	elif clan() == "aburame" and jc == "aburame":
		pr["kikaichu"] = maxf(0.0, float(pr.get("kikaichu", KOLONI_MAX)) - koloni_cost(j))
	elif clan() == "hozuki" and jc == "hozuki":
		pr["su"] = maxf(0.0, float(pr.get("su", SU_MAX)) - su_cost(j))


## Yemek yendi (çay evi, ramen): Akimichi kalorisi dolar
static func on_eat() -> void:
	if clan() == "akimichi":
		Game.profile["kalori"] = KALORI_MAX
		Hud.msg("Kaloriler doldu!", Color(1.0, 0.65, 0.25))
	elif clan() == "hozuki":
		Game.profile["su"] = SU_MAX
		Hud.msg("Bedenindeki su doldu.", Color(0.4, 0.75, 1.0))


## Oyuncuya darbe: ateş bedendeki kikaichū'yu yakar
static func on_player_hit(info: Dictionary) -> void:
	if clan() == "aburame" and String(info.get("element", "")) in ["katon", "yoton", "shakuton"]:
		var pr = Game.profile
		pr["kikaichu"] = maxf(0.0, float(pr.get("kikaichu", KOLONI_MAX)) - 12.0)
		Combat.popup_text(Game.player.global_position + Vector3.UP * 2.4, "Böceklerin yanıyor!", Color(1.0, 0.55, 0.3))


# ------------------------------------------------------------------ Kakuzu kalpleri
## Güçlü bir hedefin kalbi: sahibinin doğasıyla birlikte (doğası yoksa rastgele); 4'ten fazlası en eskisinin yerine geçer
static func steal_heart(tt: Node3D) -> void:
	var pr = Game.profile
	var el = String(tt.get("element")) if tt.get("element") != null else ""
	if not el in ["katon", "fuuton", "raiton", "suiton"]:
		el = ["katon", "fuuton", "raiton", "suiton"].pick_random()
	if not pr.has("kakuzu_hearts"):
		pr["kakuzu_hearts"] = []
	var hs: Array = pr["kakuzu_hearts"]
	if hs.size() >= HEART_MAX:
		hs.pop_front()
	hs.append(el)
	Hud.banner("KALP ÇALINDI", "%s kalbi göğsünde atıyor (%d/%d) — maskesi uyandı" % [Elements.NAMES.get(el, el), hs.size(), HEART_MAX], Color(0.8, 0.2, 0.25))
	Sfx.play("heartbeat", Game.player.global_position, 1.0)


## Ölüm anı: çalınmış kalp varsa biri kırılır, beden iplerle dikilip kalkar
static func try_extra_life() -> bool:
	var pr = Game.profile
	if Game.player and PathJutsu.izanagi_rewrite(Game.player):
		return true   # açık İzanagi: ölüm yanılsamaydı
	var hs: Array = pr.get("kakuzu_hearts", [])
	if hs.is_empty() or Game.player == null:
		return false
	var el = hs.pop_back()
	var pl = Game.player
	pl.hp = pl.max_hp * 0.5
	if pl.combat:
		pl.combat.invuln = 2.0
	FX.aura(pl, Color(0.1, 0.1, 0.12), 1.4, Vector3(0, 0.9, 0), 2.0)
	for k in 10:
		var a = k * TAU / 10.0
		var from = pl.global_position + Vector3(cos(a) * 1.4, randf_range(0.3, 1.8), sin(a) * 1.4)
		WindFX.streak(func(q: float) -> Vector3: return from.lerp(pl.global_position + Vector3.UP * 1.0, q), 0.5, 0.03, Color(0.08, 0.08, 0.1, 1.0), k * 0.02, 8)
	Hud.banner("KALP KIRILDI", "%s kalbi durdu — iplikler bedenini yeniden dikti (%d kalp kaldı)" % [Elements.NAMES.get(el, el), hs.size()], Color(0.6, 0.1, 0.12))
	return true


# ------------------------------------------------------------------ Akimichi hapları
## Akimichi hapları tükenmez, her birinin kendi bekleme süresi var (sn): kırmızı en ağır bedelli olduğu için en uzun
const AKI_PILL_CD := {"hap_horenzai": 90.0, "hap_kare": 180.0, "hap_togarashi": 600.0}
const AKI_PILL_NAMES := {"pill": "Asker Hapı", "hap_horenzai": "Yeşil Hap (Hōrenzai)", "hap_kare": "Sarı Hap (Karē)", "hap_togarashi": "Kırmızı Hap (Tōgarashi)"}


## Seçilebilir haplar: herkes asker hapı; Akimichi ayrıca üç renkli hap
static func pill_list() -> Array:
	return ["pill"] + AKI_PILLS if clan() == "akimichi" else ["pill"]


static func pill_sel() -> String:
	var s = String(Game.profile.get("pill_sel", "pill"))
	return s if s in pill_list() else "pill"


## [O]: seçili hapı değiştir
static func next_pill() -> void:
	var l = pill_list()
	var i = (l.find(pill_sel()) + 1) % l.size()
	Game.profile["pill_sel"] = l[i]
	Hud.msg("Seçili hap: %s" % AKI_PILL_NAMES.get(l[i], l[i]), Color(1.0, 0.75, 0.4), 1.5)


static func aki_pill_left(id: String) -> float:
	var at = float(Game.profile.get("aki_pill_cd", {}).get(id, 0.0))
	var now = Time.get_ticks_msec() / 1000.0
	if at - now > float(AKI_PILL_CD.get(id, 0.0)) + 1.0:   # eski oturumdan kalan zaman damgası
		Game.profile["aki_pill_cd"][id] = 0.0
		return 0.0
	return maxf(0.0, at - now)


## [Y] seçili Akimichi hapı (yeşil / sarı / kırmızı); seçili hap asker hapıysa false
static func use_aki_pill() -> bool:
	if clan() != "akimichi":
		return false
	var id = pill_sel()
	var stage = AKI_PILLS.find(id)
	if stage < 0:
		return false
	var left = aki_pill_left(id)
	if left > 0.0:
		Hud.msg("%s hazır değil: %d sn" % [AKI_PILL_NAMES[id], ceili(left)], Color(1, 0.75, 0.5))
		return true
	if Buffs.has(id):
		return true
	if not Game.profile.has("aki_pill_cd"):
		Game.profile["aki_pill_cd"] = {}
	Game.profile["aki_pill_cd"][id] = Time.get_ticks_msec() / 1000.0 + float(AKI_PILL_CD[id])
	var pl = Game.player
	match stage:
		0:
			Game.profile["kalori"] = KALORI_MAX
			Buffs.add("hap_horenzai", 30.0, {"melee": 1.25, "_name": "Yeşil Hap (Hōrenzai)", "_desc": "kalori doldu, güç artar"})
			Hud.banner("HŌRENZAI", "Yeşil hap: kaloriler doldu, güç artıyor", Color(0.4, 0.85, 0.35))
			FX.aura(pl, Color(0.4, 0.9, 0.35), 1.2)
		1:
			Buffs.add("hap_kare", 30.0, {"melee": 1.5, "armor": 0.8, "_name": "Sarı Hap (Karē)", "_desc": "yağ chakraya dönüşür; beden yıpranır"})
			Hud.banner("KARĒ", "Sarı hap: yağ chakraya dönüşüyor — beden yıpranıyor", Color(1.0, 0.85, 0.25))
			FX.aura(pl, Color(1.0, 0.85, 0.3), 1.4)
		2:
			# kırmızı hap: bütün yağ chakraya dönüşür — Kelebek Modu; bittiğinde beden ölümün eşiğine gelir
			Buffs.add("hap_togarashi", 30.0, {"_name": "Kırmızı Hap (Tōgarashi)", "_desc": "Kelebek Modu; sonunda beden tükenir"})
			Hud.banner("TŌGARASHI", "Kırmızı hap: bütün kaloriler chakraya döndü — Kelebek Modu!", Color(1.0, 0.3, 0.25))
			Jutsu.execute(pl, "cho_modo", null)
			pl.get_tree().create_timer(30.0).timeout.connect(func():
				if is_instance_valid(pl) and pl.hp > 0.0:
					pl.hp = maxf(1.0, pl.max_hp * 0.1)
					Game.profile["kalori"] = 0.0
					Buffs.add("aki_tukenme", 90.0, {"melee": 0.5, "speed": 0.7, "_name": "Tükenmiş Beden", "_desc": "kırmızı hap bedeni sıfırladı"})
					Hud.msg("Kırmızı hapın bedeli: beden tükendi, zayıf düştün.", Color(1.0, 0.45, 0.4), 5.0))
	Sfx.play("heal", pl.global_position, 0.7)
	return true


# ------------------------------------------------------------------ Inuzuka ortağı
static func dog() -> Node3D:
	if Game.player == null:
		return null
	for n in Game.player.get_tree().get_nodes_in_group("ninken"):
		if is_instance_valid(n) and n.get("owner_f") == Game.player and not n.dead:
			return n
	return null


static func _spawn_dog() -> void:
	var pl = Game.player
	var lv = int(Game.profile.get("level", 1))
	var d = Ninken.new()
	d.owner_f = pl
	d.add_to_group("inuzuka_partner")
	pl.get_tree().current_scene.add_child(d)
	d.global_position = Missions.open_ground(pl.global_position + pl.global_transform.basis.x * 2.0, 3.0)
	# yavru köpek seviyeyle büyür (anime: Akamaru kucakta yavrudan binilecek dev köpeğe)
	var s = 0.6 if lv < 15 else (1.0 if lv < 30 else 1.6)
	if d.vis:
		d.vis.scale = Vector3.ONE * s
	d.max_hp = 80.0 + lv * 12.0
	d.hp = d.max_hp
	FX.smoke_puff(d.global_position + Vector3.UP * 0.5, 0.6, 8)


static func tick(dt: float) -> void:
	if Game.player == null or Game.profile.is_empty():
		return
	var pr = Game.profile
	# Byakugō mührü: Tsunade/Sakura gibi her an az az chakra biriktirir (Byakugō açıkken birikmez)
	if "byakugo_no_in" in pr.get("learned", []) and not Buffs.has("byakugo"):
		pr["byakugo"] = minf(100.0, float(pr.get("byakugo", 0.0)) + dt / 3.0)
	match clan():
		"hozuki":
			var flask = String(Gear.equipped(pr, "sirt").get("id", "")) in ["sake_kabagi", "sirt_015", "sirt_050"]   # matara/kabak
			var gain = su_refill(Game.player.global_position, Game.player.swimming, flask)
			if gain > 0.0:
				pr["su"] = minf(SU_MAX, float(pr.get("su", SU_MAX)) + gain * dt)
		"aburame":
			# böcekler chakra yiyerek çoğalır
			var k = float(pr.get("kikaichu", KOLONI_MAX))
			if k < KOLONI_MAX and Game.player.chakra > 1.0:
				pr["kikaichu"] = minf(KOLONI_MAX, k + 1.5 * dt)
				Game.player.chakra -= 0.3 * dt
		"inuzuka":
			if not pr.has("ninken_name"):
				pr["ninken_name"] = ["Kiba-maru", "Shiromaru", "Tora", "Hayate", "Kuromaru", "Yuki"].pick_random()
			if dog() == null:
				if _dog_t <= 0.0:
					_dog_t = NINKEN_RESPAWN
					if pr.get("_dog_seen", false):
						Hud.msg("%s yaralandı — dinlenip %d sn sonra yanına döner." % [pr["ninken_name"], int(NINKEN_RESPAWN)], Color(0.9, 0.8, 0.6))
					else:
						_dog_t = 0.5
				_dog_t -= dt
				if _dog_t <= 0.0:
					_spawn_dog()
					pr["_dog_seen"] = true
		"akimichi":
			# sarı hap: yağ chakraya dönerken beden yıpranır
			if Buffs.has("hap_kare") and Game.player.hp > Game.player.max_hp * 0.15:
				Game.player.hp -= Game.player.max_hp * 0.01 * dt
			pass   # renkli haplar tükenmez: her birinin bekleme süresi var (AKI_PILL_CD)


## Yeni karakter / eski kayıt: klan başlangıç eşyaları
static func ensure(pr: Dictionary) -> void:
	if String(pr.get("clan", "")) == "akimichi":
		if not pr.has("kalori"):
			pr["kalori"] = KALORI_MAX
		if not pr.get("flags", {}).get("aki_pills_given", false):
			for id in AKI_PILLS:
				pr["inventory"][id] = int(pr["inventory"].get(id, 0)) + 1
			pr["flags"]["aki_pills_given"] = true
	if String(pr.get("clan", "")) == "aburame" and not pr.has("kikaichu"):
		pr["kikaichu"] = KOLONI_MAX
