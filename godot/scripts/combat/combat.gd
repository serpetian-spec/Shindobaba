extends Node
## Dövüş çekirdeği (autoload "Combat"): kapsül hitbox testleri, hasar, hit-stop, hasar sayıları, element tablosu.
## Her savaşçı "fighters" grubundadır ve şunları sağlar: team, radius, height, take_hit(info), is_dead()

const BEATS := {"katon": "fuuton", "fuuton": "raiton", "raiton": "doton", "doton": "suiton", "suiton": "katon"}



## Element üstünlüğü (kekkei genkai dahil, bkz. elements.gd) x hava etkisi (yağmur)
## ---------------------------------------------------------------- kontrol (stun/bağlama) azalan getirisi
## Aynı hedefe 8 sn içinde art arda: süre %100 -> %60 -> %35, dördüncüde 4 sn direnç.
## Kesintisiz kontrol en fazla 3 sn sürer; sonra hedef kurtulur ve 3 sn dirençli olur ("stun at kes" yok).
const CC := ["stun", "bind", "frozen", "fear", "sleep", "paralyze"]
const CC_MAX := 3.0


## Silahsız vuruşta eller sıkılı yumruk (kullanıcı: yumruklar parmak ucuyla atılıyordu). Avuç/parmakla vurulan tarzlar açık kalır:
## Jūken (Hakke), tıbbi chakra neşteri, kâğıt, mürekkep, kil, kukla ipleri. Oyuncu ve düşman aynı (AI eşitliği).
const PALM_STYLES := ["style_juken", "style_tip", "style_kagit", "style_sumi", "style_kil", "style_akasuna"]
func punch_fist(model, style_id: String, armed: bool, dur: float) -> void:
	if model == null or not is_instance_valid(model) or model.get("overlay") == null:
		return
	var ov = model.overlay
	if armed or style_id in PALM_STYLES:
		return
	var tok = randi()
	ov.set_meta("fist_tok", tok)
	ov.fist["Right"] = 1.0
	ov.fist["Left"] = 1.0
	get_tree().create_timer(maxf(0.2, dur)).timeout.connect(func():
		if is_instance_valid(ov) and int(ov.get_meta("fist_tok", -1)) == tok:
			if float(ov.fist.get("Right", 0.0)) == 1.0:
				ov.fist.erase("Right")
			if float(ov.fist.get("Left", 0.0)) == 1.0:
				ov.fist.erase("Left"))


func cc_dur(n: Node, kind: String, d: float) -> float:
	if not kind in CC or d <= 0.0:
		return d
	# kanon teknikler ortak sınırdan muaf (kullanıcı kuralı: anime neyse o) — ör. Kagemane chakra yettikçe tutar
	if kind == "bind" and (n.has_meta("kagemane_hold") or n.has_meta("chibaku_hold") or n.has_meta("gaki_hold")):
		return d
	var now = Time.get_ticks_msec() / 1000.0
	if now < float(n.get_meta("cc_imm", 0.0)):
		_cc_pop(n, "Direnç!")
		return 0.0
	var held = false
	for k in CC:
		if n.has_status(k):
			held = true
	if held:
		if now - float(n.get_meta("cc_start", now)) > CC_MAX:
			n.set_meta("cc_imm", now + 3.0)
			n.set_meta("cc_n", 0)
			_cc_free(n)
			_cc_pop(n, "Kurtuldu!")
			return 0.0
		return d
	var cnt = int(n.get_meta("cc_n", 0)) if now - float(n.get_meta("cc_last", -99.0)) < 8.0 else 0
	if cnt >= 3:
		n.set_meta("cc_imm", now + 4.0)
		n.set_meta("cc_n", 0)
		_cc_pop(n, "Direnç!")
		return 0.0
	n.set_meta("cc_n", cnt + 1)
	n.set_meta("cc_last", now)
	n.set_meta("cc_start", now)
	return d * [1.0, 0.6, 0.35][cnt]


func _cc_free(n: Node) -> void:
	var sts = n.get("statuses")
	if sts is Dictionary:
		for k in CC:
			sts.erase(k)
	if n.get("input_locked") != null:
		n.input_locked = 0.0
	if n is Node3D:
		FX.ring((n as Node3D).global_position + Vector3.UP, Color(0.7, 0.9, 1.0), 3.0, 0.3)


func _cc_pop(n: Node, txt: String) -> void:
	var now = Time.get_ticks_msec()
	if now - int(n.get_meta("cc_pop", 0)) > 1500 and n is Node3D:
		n.set_meta("cc_pop", now)
		popup_text((n as Node3D).global_position + Vector3.UP * 2.3, txt, Color(0.7, 0.9, 1.0))


## ---------------------------------------------------------------- jutsu hasar dengesi
## data/balance.json: her jutsunun ölçülen toplam hasarını rütbesinin hedefine çeken çarpan (tests/dbg_jdmg.gd + tools/balance.py)
var _bal := {}


func jutsu_factor(info: Dictionary) -> float:
	if info.get("melee", false):
		return 1.0
	var a = info.get("attacker")
	if a == null or not is_instance_valid(a) or not a.has_meta("jid"):
		return 1.0
	if Time.get_ticks_msec() / 1000.0 - float(a.get_meta("jid_t", 0.0)) > 12.0:
		return 1.0
	if _bal.is_empty():
		var f = FileAccess.open("res://data/balance.json", FileAccess.READ)
		_bal = JSON.parse_string(f.get_as_text()) if f else {"_": 1}
	return float(_bal.get(String(a.get_meta("jid")), 1.0))


## Hasara göre bekleme KALDIRILDI (kullanıcı 2026-11-08: "güce dayalı cooldown'u kaldır" — alan jutsusu/efsane kademe/modlarla
## beklemeler dakikalara uzuyordu). Bekleme yalnız rütbe süresi (jutsu_cd). Oyuncu ve AI aynı kural.
const DMG_CD := false
func note_jutsu_dmg(atk, info: Dictionary, dmg: float) -> void:
	if not DMG_CD:
		return
	if info.get("melee", false) or atk == null or not is_instance_valid(atk) or not atk.has_meta("jid") or dmg <= 0.0:
		return
	var jid = String(atk.get_meta("jid"))
	if atk is Player:
		if atk.combat:
			atk.combat.note_jutsu_dmg(jid, dmg)
	elif atk.has_method("note_jutsu_dmg"):
		atk.note_jutsu_dmg(jid, dmg)


## Hasar -> toplam bekleme (sn): güç çarpanına bölünmüş ~800 hasar -> ~60 sn
static func dmg_cd(dmg: float, power_mult: float) -> float:
	return 4.0 + dmg / maxf(1.0, power_mult) * 0.07


## ---------------------------------------------------------------- jutsu bekleme süresi (oyuncu ve düşman aynı kural)
## Rütbeye (kademe) göre taban; verideki süre yalnız kademe ortalamasına göre ±%20-40 karakter katar
const CD_TIER := [4.0, 6.0, 9.0, 12.0, 18.0, 28.0]
const CD_AVG := [5.5, 5.2, 8.0, 11.5, 16.3, 35.5]
const CD_UTIL := ["transform", "stealth", "sensor", "utility", "heal", "revive", "teleport", "clone", "counter", "summon"]


func jutsu_cd(j: Dictionary) -> float:
	if j.has("bijuu") or String(j.get("virtual", "")) != "":
		return float(j.get("cd", 6.0))   # göz / canavar teknikleri kendi süresini kullanır
	var t = clampi(int(j.get("tier", 2)), 0, 5)
	var raw = float(j.get("cd", CD_AVG[t]))
	if String(j.get("shape", "")) in CD_UTIL:
		return maxf(raw, CD_TIER[t])
	return snappedf(CD_TIER[t] * clampf(raw / CD_AVG[t], 0.8, 1.4), 0.5)


## Blok jutsuya karşı: küçük jutsu çoğunlukla bloklanır, büyük jutsu bloğu deler (geçen hasar oranı)
const BLOCK_PASS := [0.25, 0.3, 0.4, 0.55, 0.75, 0.9]


func block_pass(info: Dictionary, melee_pass: float) -> float:
	if info.has("tier"):
		return BLOCK_PASS[clampi(int(info["tier"]), 0, 5)]
	return melee_pass


func element_mult(atk: String, dfn: String) -> float:
	return Elements.mult(atk, dfn) * Elements.env_mult(atk)


## Bir noktanın savaşçının kapsülüne (boyutuna göre) değip değmediği
func capsule_hit(point: Vector3, f: Node3D, extra: float) -> bool:
	if f.has_method("hit_test"):  # dev canavarlar: parça kutularıyla isabet
		return f.hit_test(point, extra)
	var base = f.global_position
	var h: float = f.height
	var y = clampf(point.y, base.y + f.radius, base.y + h - f.radius)
	var c = Vector3(base.x, y, base.z)
	return point.distance_to(c) <= f.radius + extra


## Yere devirme kuralı (oyuncu + NPC ortak): yalnız tekniği gerçekten havaya kaldıran (launch >= 3) ya da çok sert iten
## (knock >= 14) vuruş devirir; diğer ağır vuruşlar sendeletir (eskiden her jutsu vuruşu yere atıyordu)
func knocks_down(info: Dictionary) -> bool:
	return float(info.get("launch", 0.0)) >= 3.0 or float(info.get("knock", 0.0)) >= 14.0


## Oyuncunun yanındaki savaşan kişi sayısı (oyuncu dahil): 40 m içinde yaşayan takım arkadaşı / dost / görev müttefiki.
## Klon, çağrı, yapı sayılmaz. Ninja düşman grupları bu kadar kişi gelir (yalnızken 1, bir dostla 2 ...): 3-4 kişinin
## yalnız oyuncuyu sersemletip kilitlemesi (stunlock) adil değildi.
func party_size() -> int:
	var pl = Game.player
	if pl == null:
		return 1
	var n = 1
	for f in get_tree().get_nodes_in_group("fighters"):
		if f == pl or not is_instance_valid(f) or f.get("team") != "player":
			continue
		if f is ShadowClone or f is Summon or f is ClanConstruct or f.is_dead():
			continue
		if (f as Node3D).global_position.distance_to(pl.global_position) < 40.0:
			n += 1
	return n


## Ninja grubunun boyu: takım sayısı kadar, en çok "cap" (olayın eski üst sınırı)
func foe_count(cap: int) -> int:
	return clampi(party_size(), 1, maxi(1, cap))


func hostile(a: Node, b: Node) -> bool:
	if a == b or b == null or a == null:
		return false
	var ta = a.get("team"); var tb = b.get("team")
	if ta == null or tb == null:
		return false
	if tb == "dummy" or ta == "dummy":
		return ta != tb
	if ta == "enemy" and tb == "enemy":
		return faction_hostile(String(a.get_meta("faction", "")), String(b.get_meta("faction", "")))
	return ta != tb and ta != "neutral" and tb != "neutral"


## Oyuncuya düşman olanlar kendi aralarında: köy ninjaları/av ekipleri kaçakları ve canavarları avlar; kuyruklu canavar herkese saldırır;
## haydut ve kaçak birbirine dokunmaz (yalnız oyuncuya düşman herkes aynı takımdaydı, köy ninjaları canavara hiç vurmuyordu)
const LAW := ["konoha", "suna", "kiri", "kumo", "iwa", "ame", "hunter", "samurai"]
func faction_hostile(fa: String, fb: String) -> bool:
	if fa == "" or fb == "" or fa == fb:
		return false
	if fa == "beast" or fb == "beast":
		return true
	if (fa in LAW and fb in ["rogue", "akatsuki"]) or (fb in LAW and fa in ["rogue", "akatsuki"]):
		return true
	return false


## Küre içinde kalan düşman savaşçılara vurur. Vurulanları döndürür.
func hit_sphere(attacker: Node3D, center: Vector3, radius: float, info: Dictionary, exclude: Array = []) -> Array:
	var hits: Array = []
	WorldDamage.impact(center, radius, info)   # ağaçlar/evler yanar, devrilir, yıkılır
	for f in get_tree().get_nodes_in_group("fighters"):
		if f in exclude or not hostile(attacker, f) or f.is_dead():
			continue
		if capsule_hit(center, f, radius):
			var inf = info.duplicate()
			inf["attacker"] = attacker
			if not inf.has("dir"):
				var d: Vector3 = f.global_position - attacker.global_position
				d.y = 0
				inf["dir"] = d.normalized() if d.length() > 0.01 else -attacker.global_transform.basis.z
			f.take_hit(inf)
			hits.append(f)
			if inf.get("melee", false):
				_lion_drain(attacker, f)
	if attacker is Player:
		for n in get_tree().get_nodes_in_group("ambient_team"):
			if is_instance_valid(n) and not n.dead and capsule_hit(center, n, radius):
				provoke(n)
	if not hits.is_empty() and info.get("hitstop", 0.0) > 0.0:
		hitstop(info["hitstop"])
	return hits


## Karamatsu no Mai (kanon): kemik dikenli bedene yakın dövüşle vuran kendini saplar — darbenin gücü kadar kendine zarar,
## kemiklere çarpan darbe büyük ölçüde boşa gider. Oyuncu (PlayerModes) ve düşman (Enemy.take_hit) aynı fonksiyonu çağırır.
func larch_counter(def: Node3D, info: Dictionary) -> bool:
	var on = Buffs.has("karamatsu") if def is Player else (def.get("buffs") != null and def.buffs.has("karamatsu"))
	if not on or not info.get("melee", false):
		return false
	var atk = info.get("attacker")
	var dmg = float(info.get("dmg", 0.0))
	info["dmg"] = dmg * 0.25
	if atk is Node3D and is_instance_valid(atk) and atk.has_method("take_hit") and not atk.is_dead():
		var heavy = String(info.get("kind", "light")) == "heavy"
		atk.take_hit({"dmg": dmg * (1.6 if heavy else 1.1) + 6.0, "knock": 4.0, "kind": "heavy" if heavy else "light", "bleed": 3.0,
			"attacker": def, "dir": (atk.global_position - def.global_position).normalized()})
		VFX.debris(atk.global_position + Vector3.UP, Color(0.75, 0.05, 0.05), 8, 5.0, 0.25)
		popup_text(atk.global_position + Vector3.UP * 2.3, "Kemiklere saplandı!", Color(1.0, 0.85, 0.7))
	return true


## Jūho Sōshiken (kanon): aslan başları dokunduğu kişinin chakra ağını emer — oyuncunun chakrası azalır,
## düşmanın (chakra değeri yok) ağı kısa süre kapanır; emen taraf chakra kazanır. Oyuncu ve düşman aynı kural.
func _lion_drain(attacker: Node3D, f: Node3D) -> void:
	var on = Buffs.active.has("juho_soshiken") if attacker is Player else (attacker.get("buffs") != null and attacker.buffs.has("juho_soshiken"))
	if not on or not is_instance_valid(f):
		return
	if f is Player:
		f.chakra = maxf(0.0, f.chakra - 6.0)
	else:
		f.apply_status("sealed", 1.2)
	if attacker is Player:
		attacker.chakra = minf(attacker.max_chakra, attacker.chakra + 4.0)
	FX.burst(f.global_position + Vector3.UP * 1.1, {"amount": 6, "life": 0.35, "tex": FX.tex_spark, "size": 0.35, "vmin": 1.5, "vmax": 3.5, "dir": (attacker.global_position - f.global_position).normalized(),
		"colors": [Color(0.75, 0.9, 1.0, 1), Color(0.35, 0.65, 1.0, 0)]})


## Oyuncu yolda yürüyen köy takımından birine vurdu (tarafsız NPC'ye darbe geçmez): takım saldırıya geçer.
## Kaçaksan zaten avcın — suç sayılmaz; köylüysen "köy takımına saldırı" suçu.
func provoke(n: Node) -> void:
	if not n.is_in_group("ambient_team"):
		return
	var at = get_tree().current_scene.find_child("AmbientTeams", true, false)
	if at != null and at.has_method("provoke"):
		at.provoke(n)


## Dev saldırı alanı: origin (yerde) önündeki yelpaze dilimine giren HER düşmana vurur — boy farkı önemsiz
## (Susanoo, kuyruklu canavar, dev çağrılar: küre isabeti yerdeki küçük hedefi ıskalıyordu).
## half_deg: yelpazenin yarım açısı; reach: yatay menzil; height: origin'den yukarı kapsanan yükseklik.
func hit_zone(attacker: Node3D, origin: Vector3, dir: Vector3, reach: float, half_deg: float, height: float, info: Dictionary, exclude: Array = []) -> Array:
	var hits: Array = []
	dir.y = 0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3.ZERO
	WorldDamage.impact(origin + dir * reach * 0.55, reach * 0.45, info)
	var cmin = cos(deg_to_rad(half_deg))
	if attacker is Player:
		for n in get_tree().get_nodes_in_group("ambient_team"):
			if is_instance_valid(n) and not n.dead and (n.global_position - origin).length() < reach + 1.0:
				provoke(n)
	for f in get_tree().get_nodes_in_group("fighters"):
		if f in exclude or not hostile(attacker, f) or f.is_dead():
			continue
		var v: Vector3 = f.global_position - origin
		var fr: float = f.radius if "radius" in f else 0.5
		if f.has_method("hit_test"):
			fr = maxf(fr, float(f.height) * 0.3)
		if v.y < -3.0 - fr or v.y > height:
			continue
		var vh = Vector3(v.x, 0, v.z)
		var dh = vh.length()
		if dh > reach + fr:
			continue
		if dir != Vector3.ZERO and dh > fr + reach * 0.15 and vh.normalized().dot(dir) < cmin:
			continue
		var inf = info.duplicate()
		inf["attacker"] = attacker
		if not inf.has("dir"):
			inf["dir"] = vh.normalized() if dh > 0.01 else dir
		f.take_hit(inf)
		hits.append(f)
	if not hits.is_empty() and info.get("hitstop", 0.0) > 0.0:
		hitstop(info["hitstop"])
	return hits


func nearest_enemy(from: Node3D, max_d: float, dir := Vector3.ZERO, cone := -1.0) -> Node3D:
	var best: Node3D = null
	var bd = max_d
	for f in get_tree().get_nodes_in_group("fighters"):
		if not hostile(from, f) or f.is_dead():
			continue
		var v: Vector3 = f.global_position - from.global_position
		var d = v.length()
		if d > bd:
			continue
		if dir != Vector3.ZERO and cone > -1.0:
			var vf = Vector3(v.x, 0, v.z).normalized()
			if vf.dot(dir) < cone:
				continue
		bd = d
		best = f
	return best


## Vuruş anında oyunu kısa süre yavaşlat (Storm hissi). Gerçek zamanla ölçülür.
var hitstop_until = 0
var base_time_scale = 1.0  # Sharingan vb. yavaş çekim için
## Algı yavaşlaması (Sharingan / dojutsu modu): dünya yavaşlar, oyuncu NORMAL hızda kalır (telafi çarpanı).
## Vuruş duraksaması (hitstop) telafi edilmez: o an herkes donar.
var self_slow := false


func player_comp() -> float:
	if not self_slow or hitstop_until > 0 or base_time_scale >= 0.999:
		return 1.0
	return 1.0 / maxf(0.1, base_time_scale)


func hitstop(t: float) -> void:
	hitstop_until = maxi(hitstop_until, Time.get_ticks_msec() + int(t * 1000.0))
	Engine.time_scale = 0.05


func _process(_dt: float) -> void:
	if hitstop_until > 0 and Time.get_ticks_msec() >= hitstop_until:
		hitstop_until = 0
		Engine.time_scale = base_time_scale
	elif hitstop_until == 0 and absf(Engine.time_scale - base_time_scale) > 0.001:
		Engine.time_scale = base_time_scale


var quiet := false   # görsel denetim testleri: hasar sayısı/yazı yok


func damage_number(pos: Vector3, amount: float, col := Color(1, 0.9, 0.3), crit := false) -> void:
	if quiet:
		return
	var l = Label3D.new()
	l.text = str(int(round(amount)))
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.0018 if not crit else 0.0026
	l.font_size = 48
	l.outline_size = 12
	l.modulate = col
	l.outline_modulate = Color(0.1, 0.05, 0.05)
	get_tree().current_scene.add_child(l)
	l.global_position = pos + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
	var tw = l.create_tween().set_parallel(true)
	tw.tween_property(l, "global_position", l.global_position + Vector3(0, 1.4, 0), 0.7).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.35).set_delay(0.45)
	tw.chain().tween_callback(l.queue_free)


func popup_text(pos: Vector3, text: String, col := Color(1, 1, 1)) -> void:
	if quiet:
		return
	var l = Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.0016
	l.font_size = 40
	l.outline_size = 10
	l.modulate = col
	get_tree().current_scene.add_child(l)
	pos += Vector3(randf_range(-0.5, 0.5), randf_range(0.0, 0.4), randf_range(-0.5, 0.5))
	l.global_position = pos
	var tw = l.create_tween().set_parallel(true)
	tw.tween_property(l, "global_position", pos + Vector3(0, 1.0, 0), 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.6)
	tw.chain().tween_callback(l.queue_free)
