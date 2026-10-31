class_name Elements
extends RefCounted
## Element sistemi: temel doğalar, kekkei genkai birleşimleri, üstünlük tablosu, jutsu çarpışmaları,
## durum etkileşimleri (ıslak/yanık/donuk/şok/çamur) ve çevre (yağmur, su).
##
## Temel döngü (kanon): Katon > Fūton > Raiton > Doton > Suiton > Katon

const BEATS := {"katon": "fuuton", "fuuton": "raiton", "raiton": "doton", "doton": "suiton", "suiton": "katon"}

## Kekkei genkai = temel doğaların birleşimi (kekkei tōta: üç doğa)
const PARTS := {
	"mokuton": ["doton", "suiton"],   # Ağaç
	"hyoton": ["fuuton", "suiton"],   # Buz
	"yoton": ["katon", "doton"],      # Lav
	"futton": ["katon", "suiton"],    # Kaynar buhar
	"ranton": ["raiton", "suiton"],   # Fırtına
	"shakuton": ["katon", "fuuton"],  # Kavurma
	"bakuton": ["doton", "raiton"],   # Patlama
	"jiton": ["doton", "fuuton"],     # Mıknatıs
	"shoton": ["doton", "fuuton"],    # Kristal (kanonda bileşimi belirsiz; toprak ağırlıklı kabul edildi)
	"jinton": ["fuuton", "katon", "doton"],  # Toz (kekkei tōta)
}

const NAMES := {
	"katon": "Ateş", "fuuton": "Rüzgar", "raiton": "Yıldırım", "doton": "Toprak", "suiton": "Su",
	"mokuton": "Ağaç", "hyoton": "Buz", "yoton": "Lav", "futton": "Buhar", "ranton": "Fırtına",
	"shakuton": "Kavurma", "bakuton": "Patlama", "jiton": "Mıknatıs", "shoton": "Kristal", "jinton": "Toz",
}

## Özel durumlar (saldıran, savunan) -> çarpan. Genel formülü ezer.
const SPECIAL := {
	["mokuton", "suiton"]: 1.6,    # ağaç suyu emer
	["mokuton", "doton"]: 1.5,     # kökler toprağı parçalar
	["mokuton", "beast"]: 1.8,     # Mokuton kuyruklu canavarları bastırır
	["katon", "mokuton"]: 1.6,     # ateş ağacı yakar
	["hyoton", "suiton"]: 1.7,     # buz suyu dondurur
	["katon", "hyoton"]: 1.6,      # ateş buzu eritir
	["hyoton", "katon"]: 0.6,
	["yoton", "doton"]: 1.7,       # lav toprağı eritir
	["yoton", "hyoton"]: 1.8,
	["yoton", "mokuton"]: 1.7,
	["suiton", "yoton"]: 1.3,      # su lavı soğutur (ama buhar çıkar)
	["futton", "suiton"]: 1.5,     # buhar suyu kaynatır
	["futton", "hyoton"]: 1.5,
	["ranton", "suiton"]: 1.2,
	["ranton", "doton"]: 1.4,
	["shakuton", "suiton"]: 1.4,   # kavurma vücut suyunu buharlaştırır
	["shakuton", "hyoton"]: 1.7,
	["bakuton", "doton"]: 1.6,
	["jiton", "raiton"]: 1.4,      # mıknatıs yıldırımı saptırır
	["shoton", "hyoton"]: 1.4,
	["jinton", ""]: 1.2,           # toz her şeyi parçalar
	["raiton", "suiton"]: 1.1,     # su elektriği iletir (ıslaklık ayrıca bonus verir)
}


## Saldıran elementin savunan elemente karşı hasar çarpanı
static func mult(atk: String, dfn: String) -> float:
	if atk == "":
		return 1.0
	if SPECIAL.has([atk, dfn]):
		return SPECIAL[[atk, dfn]]
	if atk == "jinton":
		return SPECIAL[["jinton", ""]]
	if dfn == "":
		return 1.0
	var A: Array = PARTS.get(atk, [atk])
	var D: Array = PARTS.get(dfn, [dfn])
	# her parça çifti: üstünse +1, altsa -1; ortalama skor
	var s = 0.0
	for a in A:
		for d in D:
			if BEATS.get(a, "") == d:
				s += 1.0
			elif BEATS.get(d, "") == a:
				s -= 1.0
	s /= float(A.size() * D.size())
	var m = 1.0 + 0.5 * s if s > 0.0 else 1.0 + 0.4 * s
	# kekkei genkai saf temel doğaya karşı hafif üstün (iki doğayı birden yoğurur)
	if PARTS.has(atk) and not PARTS.has(dfn):
		m *= 1.1
	elif PARTS.has(dfn) and not PARTS.has(atk):
		m *= 0.92
	return m


## Hava/çevre: yağmurda ateş zayıflar, su ve yıldırım güçlenir
static func env_mult(el: String) -> float:
	if el == "" or Game.world == null or Game.world.env == null:
		return 1.0
	if String(Game.world.env.weather) == "yağmur":
		match el:
			"katon", "yoton", "shakuton":
				return 0.75
			"suiton", "raiton", "ranton":
				return 1.15
	return 1.0


static func parts(el: String) -> Array:
	return PARTS.get(el, [el] if el != "" else [])


static func has_part(el: String, p: String) -> bool:
	return el == p or p in PARTS.get(el, [])


# ------------------------------------------------------------------ jutsu çarpışması
## a, b: {"el": String, "pow": float}. Sonuç: {a_alive, b_alive, a_scale, b_scale, effect}
## effect: steam | feed | shatter | block | disperse | melt | freeze | absorb | cancel
static func clash(a: Dictionary, b: Dictionary) -> Dictionary:
	var ea: String = a["el"]; var eb: String = b["el"]
	var pa: float = maxf(0.1, a["pow"]); var pb: float = maxf(0.1, b["pow"])
	var flip = func(r: Dictionary) -> Dictionary:
		return {"a_alive": r["b_alive"], "b_alive": r["a_alive"], "a_scale": r["b_scale"], "b_scale": r["a_scale"], "effect": r["effect"]}
	# özel kurallar (iki yön)
	var rule = _rule(ea, eb, pa, pb)
	if rule.is_empty():
		var r2 = _rule(eb, ea, pb, pa)
		if not r2.is_empty():
			return flip.call(r2)
	else:
		return rule
	# genel: element üstünlüğü x güç
	var ra = mult(ea, eb) * pa
	var rb = mult(eb, ea) * pb
	var ratio = ra / rb
	if ratio > 1.25:
		return {"a_alive": true, "b_alive": false, "a_scale": clampf(1.0 - 0.5 / ratio, 0.4, 1.0), "b_scale": 0.0, "effect": "overpower"}
	if ratio < 0.8:
		return {"a_alive": false, "b_alive": true, "a_scale": 0.0, "b_scale": clampf(1.0 - 0.5 * ratio, 0.4, 1.0), "effect": "overpower"}
	return {"a_alive": false, "b_alive": false, "a_scale": 0.0, "b_scale": 0.0, "effect": "cancel"}


## ea'nın eb'ye karşı özel davranışı (yoksa boş)
static func _rule(ea: String, eb: String, pa: float, pb: float) -> Dictionary:
	# su ateşi söndürür: büyük buhar bulutu, su zayıflar
	if has_part(ea, "suiton") and (eb == "katon" or eb == "shakuton"):
		var water_ok = pa >= pb * 0.6
		return {"a_alive": water_ok, "b_alive": false, "a_scale": 0.5, "b_scale": 0.0, "effect": "steam"}
	# rüzgar ateşi besler: ateş büyür, rüzgar kaybolur
	if ea == "katon" and eb == "fuuton":
		return {"a_alive": true, "b_alive": false, "a_scale": 1.5, "b_scale": 0.0, "effect": "feed"}
	# yıldırım toprağı parçalar
	if ea == "raiton" and eb == "doton":
		return {"a_alive": true, "b_alive": false, "a_scale": 0.7, "b_scale": 0.0, "effect": "shatter"}
	# toprak suyu durdurur
	if ea == "doton" and eb == "suiton":
		return {"a_alive": true, "b_alive": false, "a_scale": 0.85, "b_scale": 0.0, "effect": "block"}
	# rüzgar yıldırımı dağıtır (kanon: Fūton > Raiton)
	if ea == "fuuton" and eb == "raiton":
		return {"a_alive": true, "b_alive": false, "a_scale": 0.8, "b_scale": 0.0, "effect": "disperse"}
	# buz + ateş: buz erir, su sıçrar; ateş zayıflar
	if ea == "katon" and eb == "hyoton":
		return {"a_alive": pa > pb * 0.7, "b_alive": false, "a_scale": 0.6, "b_scale": 0.0, "effect": "melt"}
	# buz suyu dondurur
	if ea == "hyoton" and eb == "suiton":
		return {"a_alive": true, "b_alive": false, "a_scale": 0.8, "b_scale": 0.0, "effect": "freeze"}
	# lav toprağı/buzu/ağacı eritir
	if ea == "yoton" and eb in ["doton", "hyoton", "mokuton"]:
		return {"a_alive": true, "b_alive": false, "a_scale": 0.8, "b_scale": 0.0, "effect": "melt"}
	# buhar suyu kaynatır
	if ea == "futton" and eb == "suiton":
		return {"a_alive": true, "b_alive": false, "a_scale": 0.85, "b_scale": 0.0, "effect": "steam"}
	# ağaç suyu emer, toprağı yarar
	if ea == "mokuton" and eb in ["suiton", "doton"]:
		return {"a_alive": true, "b_alive": false, "a_scale": 1.1 if eb == "suiton" else 0.8, "b_scale": 0.0, "effect": "absorb"}
	# aynı element: güce göre, yakınsa ikisi de söner
	if ea == eb:
		if pa > pb * 1.3:
			return {"a_alive": true, "b_alive": false, "a_scale": 0.6, "b_scale": 0.0, "effect": "overpower"}
		if pb > pa * 1.3:
			return {"a_alive": false, "b_alive": true, "a_scale": 0.0, "b_scale": 0.6, "effect": "overpower"}
		return {"a_alive": false, "b_alive": false, "a_scale": 0.0, "b_scale": 0.0, "effect": "cancel"}
	return {}


const EFFECT_TEXT := {
	"steam": "Su ateşi söndürdü!", "feed": "Rüzgar alevi büyüttü!", "shatter": "Yıldırım toprağı parçaladı!",
	"block": "Toprak suyu durdurdu!", "disperse": "Rüzgar yıldırımı dağıttı!", "melt": "Eridi!", "freeze": "Su dondu!",
	"absorb": "Ağaç emdi!", "cancel": "Jutsular birbirini yok etti!", "overpower": "Daha güçlü jutsu kazandı!",
}


## Çarpışma görsel + ses (pos: temas noktası, ea/eb: elementler)
static func clash_fx(pos: Vector3, effect: String, ea: String, eb: String, size := 1.0) -> void:
	var s = clampf(size, 0.6, 3.0)
	match effect:
		"steam":
			FX.burst(pos, {"amount": 70, "life": 2.6, "tex": FX.tex_smoke, "add": false, "size": 4.5 * s, "radius": 1.5 * s,
				"vmin": 2.0, "vmax": 6.0, "gravity": Vector3(0, 2.5, 0), "damp": 1.5, "explosive": 0.8,
				"colors": [Color(1, 1, 1, 0), Color(0.95, 0.97, 1, 0.85), Color(0.9, 0.92, 0.95, 0.6), Color(0.9, 0.9, 0.95, 0)]})
			Sfx.play("water", pos, 1.4)
			Sfx.play("fire", pos, 0.6, 0.5)
		"feed":
			FX.explosion(pos, 0.9 * s, Color(1.0, 0.5, 0.1))
			FX.burst(pos, {"amount": 50, "life": 0.7, "size": 2.0 * s, "vmin": 6, "vmax": 14, "tangent": 8.0,
				"colors": [Color(1, 0.95, 0.6, 1), Color(1, 0.5, 0.1, 0.9), Color(0.6, 0.1, 0.0, 0)]})
			Sfx.play("wind", pos, 0.8)
			Sfx.play("fire", pos, 0.8)
		"shatter", "block", "absorb":
			FX.dust(pos, 1.5 * s)
			FX.burst(pos, {"amount": 40, "life": 1.2, "tex": FX.tex_soft, "add": false, "size": 0.5 * s, "vmin": 5, "vmax": 12,
				"gravity": Vector3(0, -20, 0), "colors": [Color(0.5, 0.4, 0.3, 1), Color(0.45, 0.35, 0.25, 0)]})
			if effect == "shatter":
				FX.hit_spark(pos, Color(0.7, 0.85, 1.0), 1.4 * s)
				Sfx.play("thunder", pos, 1.3, 0.6)
			Sfx.play("earth", pos, 1.2)
		"disperse":
			FX.burst(pos, {"amount": 40, "life": 0.5, "tex": FX.tex_spark, "size": 1.2 * s, "vmin": 8, "vmax": 18,
				"colors": [Color(0.8, 0.9, 1, 1), Color(0.5, 0.7, 1, 0)]})
			FX.ring(pos, Color(0.85, 1, 0.9, 0.8), 5.0 * s, 0.35, false)
			Sfx.play("wind", pos, 1.3)
		"melt":
			FX.burst(pos, {"amount": 40, "life": 1.0, "size": 1.0 * s, "vmin": 4, "vmax": 10, "gravity": Vector3(0, -14, 0),
				"colors": [Color(0.85, 0.95, 1, 1), Color(0.3, 0.6, 1, 0)]})
			FX.burst(pos, {"amount": 20, "life": 1.6, "tex": FX.tex_smoke, "add": false, "size": 2.5 * s, "vmin": 1, "vmax": 3,
				"gravity": Vector3(0, 2, 0), "colors": [Color(1, 1, 1, 0), Color(0.95, 0.97, 1, 0.6), Color(1, 1, 1, 0)]})
			Sfx.play("water", pos, 1.6)
		"freeze":
			FX.burst(pos, {"amount": 50, "life": 1.2, "tex": FX.tex_spark, "size": 1.0 * s, "vmin": 3, "vmax": 9, "gravity": Vector3(0, -12, 0),
				"colors": [Color(0.9, 0.98, 1, 1), Color(0.6, 0.85, 1, 0)]})
			Sfx.play("clink", pos, 0.7)
			Sfx.play("water", pos, 1.8, 0.5)
		_:
			FX.impact(pos, color_of(ea).lerp(color_of(eb), 0.5), 1.2 * s)
			FX.ring(pos, Color(1, 1, 1, 0.8), 4.0 * s, 0.3, false)
			Sfx.play("boom", pos, 1.2, 0.7)
	if Game.world and Game.world.env and Game.world.env.has_method("add_shake"):
		Game.world.env.add_shake(0.25 * s)
	tip(effect, EFFECT_TEXT.get(effect, ""))
	Combat.popup_text(pos + Vector3.UP * 1.2, EFFECT_TEXT.get(effect, ""), Color(1, 0.95, 0.7))


static func color_of(el: String) -> Color:
	match el:
		"katon", "yoton", "shakuton": return Color(1.0, 0.5, 0.15)
		"suiton", "futton": return Color(0.4, 0.7, 1.0)
		"fuuton": return Color(0.75, 1.0, 0.85)
		"raiton", "ranton": return Color(0.6, 0.8, 1.0)
		"doton", "bakuton", "jiton": return Color(0.65, 0.5, 0.35)
		"hyoton": return Color(0.85, 0.95, 1.0)
		"mokuton": return Color(0.5, 0.75, 0.35)
	return Color(1, 1, 1)


# ------------------------------------------------------------------ ipuçları (her etkileşim ilk kez)
static var _tips := {}
static func tip(key: String, text: String) -> void:
	if key == "" or text == "" or _tips.has(key):
		return
	_tips[key] = true
	var extra = {
		"steam": "Su jutsuları ateşi söndürür.", "feed": "Rüzgar ateşi besler: ateş jutsusu büyür.",
		"shatter": "Yıldırım toprak duvarları deler.", "block": "Toprak duvar su jutsularını durdurur.",
		"disperse": "Rüzgar yıldırımı dağıtır.", "wet_shock": "Islak hedefe yıldırım ekstra hasar verir ve yayılır.",
		"extinguish": "Su, yanan hedefi söndürür.", "wet_fire": "Islak hedefe ateş zayıf işler.",
		"thaw": "Ateş donmuş hedefi eritir: ekstra hasar.", "freeze_wet": "Buz ıslak hedefi dondurur.",
		"spread": "Rüzgar yanan hedeften alevi çevreye yayar.", "mud": "Toprak çamuru hedefi yavaşlatır.",
		"rain": "Yağmurda herkes ıslanır: ateş zayıflar, su ve yıldırım güçlenir.",
	}.get(key, "")
	Hud.msg("İPUCU — %s %s" % [text, extra], Color(0.85, 0.95, 1.0), 5.0)


# ------------------------------------------------------------------ hedefte durum etkileşimleri
## Fighter.take_hit içinden çağrılır. Hasar çarpanını döndürür, durumları uygular.
static func on_hit(target: Node, info: Dictionary) -> float:
	var el: String = info.get("element", "")
	if el == "" or not target.has_method("apply_status"):
		return 1.0
	var m = 1.0
	var pos: Vector3 = target.global_position + Vector3.UP * target.height * 0.7
	var wet = target.has_status("wet")
	if has_part(el, "suiton") or el == "ranton":
		if target.has_status("burn") and not _black_flame(target):
			target.statuses.erase("burn")
			FX.burst(pos, {"amount": 20, "life": 1.2, "tex": FX.tex_smoke, "add": false, "size": 1.6, "vmin": 1, "vmax": 3,
				"gravity": Vector3(0, 2, 0), "colors": [Color(1, 1, 1, 0), Color(0.95, 0.97, 1, 0.7), Color(1, 1, 1, 0)]})
			Combat.popup_text(pos, "Söndü!", Color(0.7, 0.9, 1))
			tip("extinguish", "Söndü!")
		target.apply_status("wet", 8.0)
	if el == "hyoton":
		if wet:
			target.apply_status("frozen", 2.5)
			target.apply_status("stun", 2.5)
			target.statuses.erase("wet")
			Combat.popup_text(pos, "Dondu!", Color(0.85, 0.97, 1))
			tip("freeze_wet", "Dondu!")
		else:
			target.apply_status("chill", 3.0)
			target.apply_status("slow", 3.0)
	if has_part(el, "katon"):
		if target.has_status("frozen"):
			target.statuses.erase("frozen")
			target.statuses.erase("stun")
			m *= 1.5
			Combat.popup_text(pos, "Eridi!", Color(1, 0.7, 0.4))
			tip("thaw", "Eridi!")
		elif wet:
			m *= 0.7
			info["burn"] = 0.0  # ıslak hedef tutuşmaz
			target.statuses.erase("wet")
			Combat.popup_text(pos, "Islak...", Color(0.7, 0.8, 0.9))
			tip("wet_fire", "Islak...")
		elif not info.has("burn"):
			target.apply_status("burn", 2.0)
	if has_part(el, "raiton"):
		if wet:
			m *= 1.5
			target.apply_status("stun", 1.2)
			target.apply_status("shock", 1.2)
			Combat.popup_text(pos, "Elektrik çarptı!", Color(0.7, 0.85, 1))
			tip("wet_shock", "Elektrik!")
			_chain_shock(target, info)
			if GroundFX.kind_at(target.global_position) == "wet":   # ıslak zemin: tüm birikinti elektriklenir
				GroundFX.shock(target.global_position, info.get("attacker"), float(info.get("dmg", 10.0)))
		else:
			target.apply_status("shock", 0.4)
	if el == "fuuton" and target.has_status("burn"):
		m *= 1.25
		Combat.popup_text(pos, "Alevler yayıldı!", Color(1, 0.6, 0.2))
		tip("spread", "Alevler yayıldı!")
		var atk = info.get("attacker")
		for f in target.get_tree().get_nodes_in_group("fighters"):
			if f == target or f.is_dead() or not f.has_method("apply_status"):
				continue
			if atk != null and is_instance_valid(atk) and not Combat.hostile(atk, f):
				continue
			if f.global_position.distance_to(target.global_position) < 5.0:
				f.apply_status("burn", 3.0)
				FX.burst(f.global_position + Vector3.UP, {"amount": 14, "life": 0.6, "size": 1.0, "vmin": 2, "vmax": 5,
					"colors": [Color(1, 0.8, 0.3, 1), Color(1, 0.3, 0.05, 0)]})
	if has_part(el, "doton") and el != "jinton":
		target.apply_status("mud", 2.0)
		target.apply_status("slow", 2.0)
		if randf() < 0.3:
			tip("mud", "Çamur!")
	return m


## Amaterasu kara alevi su/yağmurla sönmez
static func _black_flame(t: Node) -> bool:
	return t.has_meta("black_flame") and bool(t.get_meta("black_flame"))


## Islak hedeften yakındaki ıslak düşmanlara elektrik sıçraması
static func _chain_shock(src: Node, info: Dictionary) -> void:
	var atk = info.get("attacker")
	var dmg = float(info.get("dmg", 10.0)) * 0.4
	for f in src.get_tree().get_nodes_in_group("fighters"):
		if f == src or f.is_dead() or not f.has_method("has_status") or not f.has_status("wet"):
			continue
		if atk != null and is_instance_valid(atk) and not Combat.hostile(atk, f):
			continue
		if f.global_position.distance_to(src.global_position) > 7.0:
			continue
		var a: Vector3 = src.global_position + Vector3.UP * 1.2
		var b: Vector3 = f.global_position + Vector3.UP * 1.2
		for k in 4:
			FX.hit_spark(a.lerp(b, (k + 0.5) / 4.0), Color(0.7, 0.85, 1.0), 0.6)
		f.hp -= dmg
		f.apply_status("stun", 0.8)
		f.apply_status("shock", 0.8)
		Combat.damage_number(b + Vector3.UP * 0.5, dmg, Color(0.6, 0.8, 1.0))


## Her karede çevre: yağmur ve suda durmak ıslatır
static func env_tick(f: Node, dt: float) -> void:
	if Game.world == null or Game.world.env == null:
		return
	var p: Vector3 = f.global_position
	var in_water = Game.terrain_height(p.x, p.z) < -0.3 and p.y < 0.4
	var raining = String(Game.world.env.weather) == "yağmur"
	if in_water or raining:
		f.apply_status("wet", 2.0)
		if f.has_status("burn") and not _black_flame(f):
			f.statuses.erase("burn")
		if raining and f.has_method("is_dead") and f.global_position.distance_to(Game.player.global_position if Game.player else p) < 30.0:
			tip("rain", "Yağmur!")


## Yanık izi (yere düşen ateş jutsuları): koyu yarıçaplı çıkartma, yavaşça kaybolur
static var _scorch_tex: ImageTexture
static func scorch(pos: Vector3, r := 2.5) -> void:
	if _scorch_tex == null:
		var n = 64
		var img = Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var d = Vector2(x - n * 0.5, y - n * 0.5).length() / (n * 0.5)
				var a = clampf(1.0 - d, 0.0, 1.0)
				a = a * a * (0.7 + 0.3 * sin(x * 0.7) * cos(y * 0.9))
				img.set_pixel(x, y, Color(0.06, 0.04, 0.03, clampf(a * 1.4, 0.0, 0.85)))
		_scorch_tex = ImageTexture.create_from_image(img)
	var dec = Decal.new()
	dec.texture_albedo = _scorch_tex
	dec.size = Vector3(r * 2.0, 3.0, r * 2.0)
	dec.cull_mask = 0xFFFFF
	var tree = Engine.get_main_loop() as SceneTree
	tree.current_scene.add_child(dec)
	dec.global_position = Vector3(pos.x, Game.terrain_height(pos.x, pos.z) + 0.5, pos.z)
	dec.rotation.y = randf() * TAU
	var tw = dec.create_tween()
	tw.tween_interval(20.0)
	tw.tween_property(dec, "modulate:a", 0.0, 4.0)
	tw.tween_callback(dec.queue_free)
	# sınırlı sayıda iz
	var all = tree.get_nodes_in_group("scorch")
	dec.add_to_group("scorch")
	if all.size() > 24:
		all[0].queue_free()
