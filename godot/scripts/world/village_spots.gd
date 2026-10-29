class_name VillageSpots
extends RefCounted
## Köy hayatı yalnız ana caddelerde kalmasın: sokak noktalarına ara sokak / avlu (kapı önleri), parklar ve banklar eklenir.
## VillageLife._streets bunu çağırır; yürüyenler ve doğum noktaları böylece arka sokaklara, avlulara ve parklara da dağılır.
## Kapı önleri yapı kurulurken kaydedilir; parklar (CityLandscape) arka planda kurulduğu için sonradan eklenir.

const LANDSCAPE := "res://scripts/world/city_landscape.gd"
const VL = preload("res://scripts/world/village_life.gd")
static var _doors_done := {}
static var _parks_done := {}
static var _lots_done := {}


## street_cache[vid] dizisine eksik ek noktaları bir kez ekler (çağrılması ucuz)
static func top_up(pts: Array, v: Dictionary) -> void:
	var vid := String(v["id"])
	var base_n: int = maxi(40, pts.size())
	if not _doors_done.has(vid) and (vid == "konoha" or CityInfill.done.has(vid)):
		var ds: Array = VL.doors.get(vid, [])
		if not ds.is_empty():
			_doors_done[vid] = true
			var pick := ds.duplicate()
			pick.shuffle()
			# kapı önünden 2-4 m dışarı (avlu / ara sokak), en fazla sokak noktası sayısının %70'i kadar
			for q in pick.slice(0, int(base_n * 0.7)):
				var p: Vector3 = q
				p += Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.5, 2.5))
				p.y = Game.ground_height(p.x, p.z)
				pts.append(p)
	# boş arsalardaki yaşam köşeleri (sandık yığını, bahçe, tezgâh...) önleri
	if not _lots_done.has(vid) and CityInfill.done.has(vid):
		var lots: Array = CityInfill.lots_by[vid]
		if not lots.is_empty():
			_lots_done[vid] = true
			for q in lots:
				pts.append(q)
	if not _parks_done.has(vid):
		var parks := _parks(vid)
		if not parks.is_empty():
			_parks_done[vid] = true
			var cen := Vector2(float(v["x"]), float(v["y"]))
			for lp in parks:
				var c: Vector2 = cen + Vector2(lp.x, lp.y)
				for k in 5:
					var a := randf() * TAU
					pts.append(Game.from_map(c + Vector2(cos(a), sin(a)) * randf_range(3.0, 12.0)))
			for st in VL.sites.get(vid, []):
				if st.get("type", "") == "bench":
					pts.append(st["pos"])


static func _parks(vid: String) -> Array:
	if not ResourceLoader.exists(LANDSCAPE):
		_parks_done[vid] = true
		return []
	var sc = load(LANDSCAPE)
	if sc == null:
		return []
	var pb = sc.parks_by
	if pb is Dictionary:
		return pb.get(vid, [])
	return []
