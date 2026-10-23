class_name NpcNav
extends RefCounted
## Köylü yürüyüşü: önündeki engeli (bina, duvar, çit, ağaç) kısa ışınla görüp yandan dolaşma,
## hedefe yaklaşamayınca "takıldı" deyip yeni hedef, hedef seçerken düz hattı açık noktaları yeğleme.
## Durum villager.nav sözlüğünde tutulur: t (ışın sayacı), off (sapma açısı), side, pt/pd (ilerleme), n (art arda takılma).

const MASK := 1          # statik dünya (binalar, duvarlar, peyzaj)
const EYE := 0.6         # ışın yüksekliği: alçak çit ve banklar da görülsün

static var stuck_events := 0   # testler için: toplam takılma sayısı
static var rays := 0
static var enabled := true     # testte karşılaştırma için kapatılabilir (eski davranış: duvara değince yeni hedef)


static func ray_clear(n: Node3D, from: Vector3, to: Vector3, wide := false) -> bool:
	rays += 1
	var a = Vector3(from.x, from.y + EYE, from.z)
	var b = Vector3(to.x, Game.ground_height(to.x, to.z) + EYE, to.z)
	var space = n.get_world_3d().direct_space_state
	var q = PhysicsRayQueryParameters3D.create(a, b, MASK)
	q.exclude = [n.get_rid()]
	if not space.intersect_ray(q).is_empty():
		return false
	if wide:
		# omuz genişliği: gövdenin iki yanından da bak (köşelere sürtünmesin)
		var d = b - a
		d.y = 0.0
		var sd = Vector3(-d.z, 0, d.x).normalized() * 0.45
		for o in [sd, -sd]:
			q = PhysicsRayQueryParameters3D.create(a + o, b + o, MASK)
			q.exclude = [n.get_rid()]
			if not space.intersect_ray(q).is_empty():
				return false
	return true


## dir: istenen yatay birim yön. Önü kapalıysa ±35..140° sapan ilk açık yönü döndürür (0.2 sn'de bir bakar).
static func steer(n, dir: Vector3, dt: float) -> Vector3:
	if not enabled:
		return dir
	var st: Dictionary = n.nav
	st["t"] = float(st.get("t", 0.0)) - dt
	var off: float = st.get("off", 0.0)
	# duvara sürtünüyorsa: duvardan uzaklaşan kayma yönü + hemen yeniden bak
	if n.is_on_wall():
		var wn: Vector3 = n.get_wall_normal()
		wn.y = 0.0
		var cur = dir.rotated(Vector3.UP, off) if off != 0.0 else dir
		if wn.length() > 0.1 and cur.dot(wn) < 0.0:
			wn = wn.normalized()
			st["t"] = 0.0
			var slide = cur - wn * cur.dot(wn)
			return (slide + wn * 0.6).normalized() if slide.length() > 0.05 else wn
	if st["t"] <= 0.0:
		st["t"] = 0.2
		var look = clampf(float(n.speed) * 0.6, 1.4, 3.5)
		var p: Vector3 = n.global_position
		if off != 0.0:
			if ray_clear(n, p, p + dir * look, true):
				off = 0.0
		elif not ray_clear(n, p, p + dir * look, true):
			var side: float = st.get("side", 1.0 if randf() < 0.5 else -1.0)
			var found = false
			for a in [35.0, 70.0, 105.0, 140.0]:
				for sd in [side, -side]:
					var cand = deg_to_rad(a) * sd
					if ray_clear(n, p, p + dir.rotated(Vector3.UP, cand) * look, true):
						off = cand
						st["side"] = sd
						found = true
						break
				if found:
					break
			if not found:
				off = PI
		st["off"] = off
	return dir.rotated(Vector3.UP, off) if off != 0.0 else dir


## Hedefe 2.5 sn'de 0.7 m'den az yaklaştıysa takıldı (true). Art arda sayısı st["n"].
static func stuck(n, goal: Vector3, dt: float) -> bool:
	if not enabled:
		return n.is_on_wall()
	var st: Dictionary = n.nav
	st["pt"] = float(st.get("pt", 0.0)) + dt
	if st["pt"] < 2.5:
		return false
	st["pt"] = 0.0
	var gp: Vector3 = n.global_position
	var d = Vector2(goal.x - gp.x, goal.z - gp.z).length()
	var prev: float = st.get("pd", 1e9)
	st["pd"] = d
	if prev - d < 0.7:
		st["n"] = int(st.get("n", 0)) + 1
		st["off"] = 0.0
		st["pd"] = 1e9
		stuck_events += 1
		return true
	st["n"] = 0
	return false


## Hedef değişince ilerleme ölçümü baştan
static func reset(n) -> void:
	var st: Dictionary = n.nav
	st["pt"] = 0.0
	st["pd"] = 1e9
	st["off"] = 0.0


## Adaylardan (Vector3) düz hattı açık ilkini seç; hiçbiri açık değilse null
static func pick_clear(n: Node3D, cands: Array):
	if not enabled:
		return null
	for q in cands:
		if ray_clear(n, n.global_position, q):
			return q
	return null
