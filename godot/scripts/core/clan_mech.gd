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
const AKI_PILLS := ["hap_horenzai", "hap_kare", "hap_togarashi"]
const NINKEN_RESPAWN := 45.0
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
	match clan():
		"akimichi":
			return {"label": "Kalori", "v": float(pr.get("kalori", KALORI_MAX)), "max": KALORI_MAX, "col": Color(1.0, 0.62, 0.2)}
		"aburame":
			return {"label": "Kikaichū", "v": float(pr.get("kikaichu", KOLONI_MAX)), "max": KOLONI_MAX, "col": Color(0.35, 0.55, 0.3)}
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
		"inuzuka":
			if jid in DOG_COMBO and dog() == null:
				return "%s yanında değil — ortak teknik köpeğinle yapılır." % String(pr.get("ninken_name", "Ninken"))
	return ""


static func kalori_cost(jid: String, j: Dictionary) -> float:
	if jid == "cho_modo":
		return 80.0   # Kelebek Modu bütün kaloriyi yakar
	return float(j.get("cost", 20)) * 0.5


static func koloni_cost(j: Dictionary) -> float:
	return float(j.get("cost", 20)) * 0.8


static func pay(jid: String, j: Dictionary) -> void:
	var pr = Game.profile
	var jc = jutsu_clan(j)
	if clan() == "akimichi" and jc == "akimichi":
		if jid == "cho_modo" and not Buffs.has("hap_togarashi"):
			pr["kalori"] = 0.0
		else:
			pr["kalori"] = maxf(0.0, float(pr.get("kalori", KALORI_MAX)) - kalori_cost(jid, j))
	elif clan() == "aburame" and jc == "aburame":
		pr["kikaichu"] = maxf(0.0, float(pr.get("kikaichu", KOLONI_MAX)) - koloni_cost(j))


## Yemek yendi (çay evi, ramen): Akimichi kalorisi dolar
static func on_eat() -> void:
	if clan() == "akimichi":
		Game.profile["kalori"] = KALORI_MAX
		Hud.msg("Kaloriler doldu!", Color(1.0, 0.65, 0.25))


## Oyuncuya darbe: ateş bedendeki kikaichū'yu yakar
static func on_player_hit(info: Dictionary) -> void:
	if clan() == "aburame" and String(info.get("element", "")) in ["katon", "yoton", "shakuton"]:
		var pr = Game.profile
		pr["kikaichu"] = maxf(0.0, float(pr.get("kikaichu", KOLONI_MAX)) - 12.0)
		Combat.popup_text(Game.player.global_position + Vector3.UP * 2.4, "Böceklerin yanıyor!", Color(1.0, 0.55, 0.3))


# ------------------------------------------------------------------ Akimichi hapları
## [Y]: Akimichi sıradaki hapı alır (yeşil -> sarı -> kırmızı); hap yoksa false (normal asker hapı)
static func use_aki_pill() -> bool:
	if clan() != "akimichi":
		return false
	var inv: Dictionary = Game.profile["inventory"]
	var stage = 0
	if Buffs.has("hap_kare"):
		stage = 2
	elif Buffs.has("hap_horenzai"):
		stage = 1
	if stage >= AKI_PILLS.size() or int(inv.get(AKI_PILLS[stage], 0)) <= 0:
		return false
	inv[AKI_PILLS[stage]] = int(inv[AKI_PILLS[stage]]) - 1
	var pl = Game.player
	match stage:
		0:
			Game.profile["kalori"] = KALORI_MAX
			Buffs.add("hap_horenzai", 30.0, {"melee": 1.5, "_name": "Yeşil Hap (Hōrenzai)", "_desc": "kalori doldu, güç artar"})
			Hud.banner("HŌRENZAI", "Yeşil hap: kaloriler doldu, güç artıyor", Color(0.4, 0.85, 0.35))
			FX.aura(pl, Color(0.4, 0.9, 0.35), 1.2)
		1:
			Buffs.add("hap_kare", 30.0, {"melee": 2.0, "armor": 0.6, "_name": "Sarı Hap (Karē)", "_desc": "yağ chakraya dönüşür; beden yıpranır"})
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
	match clan():
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
			# klan haplarını tükettiysen klan bir süre sonra yeni takım gönderir
			var inv: Dictionary = pr["inventory"]
			if int(inv.get("hap_horenzai", 0)) <= 0:
				_pill_gift_t += dt
				if _pill_gift_t > 900.0:
					_pill_gift_t = 0.0
					for id in AKI_PILLS:
						inv[id] = int(inv.get(id, 0)) + 1
					Hud.msg("Klanın yeni bir takım Akimichi hapı gönderdi (yeşil, sarı, kırmızı).", Color(1.0, 0.7, 0.3), 5.0)


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
