class_name Canal
extends RefCounted
## Köy içinden geçen taş kanal / dere (Konoha'da Naka Nehri): akan su şeridi, iki yanda taş set + kenar taşı,
## caddelerin kesiştiği yerlerde korkuluklu taş köprü, kıyıda söğüt / fener / basamak.
## Arazi kazılamadığı için set kenarları zeminden yükselir, su yüzeyi zeminin biraz üstündedir (kanal gibi okunur).
## Yol kesişimi dışında set boyunca çarpışma vardır; evler / ağaçlar kanalın üstüne konmaz (add_solid).

const STONE := Color(0.62, 0.6, 0.56)
const STONE_D := Color(0.45, 0.44, 0.41)
const CAP := Color(0.74, 0.72, 0.67)
const WOOD := Color(0.5, 0.33, 0.2)
const RAIL := Color(0.72, 0.2, 0.16)

static var _mat: ShaderMaterial


## pts: yerel (x, n) noktalar; width: su genişliği; road_fn(x, n) -> bool: o nokta cadde üstünde mi
static func build(b: Builder, pts: Array, width: float, road_fn: Callable, rng: RandomNumberGenerator) -> void:
	# düzgün aralıklı örnekler
	var smp: Array = []
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var c: Vector2 = pts[i + 1]
		var n = maxi(1, int(a.distance_to(c) / 3.0))
		for k in n:
			smp.append(a.lerp(c, float(k) / n))
	smp.append(pts[pts.size() - 1])
	var gy = func(p: Vector2) -> float:
		var wp = b.w(Vector3(p.x, 0, p.y))
		return Game.terrain_height(wp.x, wp.z) - b.origin.y
	var half = width * 0.5
	var on_road: Array = []
	for p in smp:
		on_road.append(bool(road_fn.call(p.x, p.y)))
	# köprü bölgeleri: yola değen örneklerin iki yanına 2 örnek pay
	var bridge: Array = on_road.duplicate()
	for i in smp.size():
		if on_road[i]:
			for d in range(-2, 3):
				if i + d >= 0 and i + d < smp.size():
					bridge[i + d] = true
	# su şeridi (tek mesh)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var along := 0.0
	for i in smp.size() - 1:
		var p0: Vector2 = smp[i]
		var p1: Vector2 = smp[i + 1]
		var dir = (p1 - p0).normalized()
		var nr = Vector2(-dir.y, dir.x)
		var y0 = gy.call(p0) + 0.35
		var y1 = gy.call(p1) + 0.35
		var L = p0.distance_to(p1)
		var q = [[p0 - nr * half, y0, 0.0, along], [p0 + nr * half, y0, 1.0, along], [p1 + nr * half, y1, 1.0, along + L],
			[p0 - nr * half, y0, 0.0, along], [p1 + nr * half, y1, 1.0, along + L], [p1 - nr * half, y1, 0.0, along + L]]
		for v in q:
			st.set_uv(Vector2(v[2], v[3] / width))
			st.set_normal(Vector3.UP)
			var pp: Vector2 = v[0]
			st.add_vertex(b.w(Vector3(pp.x, v[1], pp.y)))   # kök düğüm dünya merkezinde
		along += L
		# kanal tabanı (koyu taş, suyun altında)
		var m = (p0 + p1) * 0.5
		var yaw = rad_to_deg(atan2(dir.x, dir.y))
		b.box(Vector3(m.x, (y0 + y1) * 0.5 - 0.3, m.y), Vector3(width + 0.2, 0.2, L + 0.2), STONE_D.darkened(0.25), yaw, false)
		# setler: köprü olmayan yerlerde iki yanda taş duvar + kenar taşı; köprüde taş tabliye + korkuluk
		if not bridge[i]:
			for sd in [-1.0, 1.0]:
				var e = m + nr * (half + 0.45) * sd
				var gyy = gy.call(e)
				b.box(Vector3(e.x, gyy + 0.45, e.y), Vector3(0.9, 0.9 + 0.6, L + 0.12), STONE if i % 3 else STONE.darkened(0.05), yaw, true)
				b.box(Vector3(e.x, gyy + 1.25, e.y), Vector3(1.1, 0.14, L + 0.14), CAP, yaw, false)
			b.add_solid(b.w(Vector3(m.x, 0, m.y)), half + 0.9, L * 0.5 + 0.2, deg_to_rad(-yaw))
		else:
			b.box(Vector3(m.x, (y0 + y1) * 0.5 + 0.15, m.y), Vector3(width + 2.4, 0.35, L + 0.1), CAP.darkened(0.08), yaw, true)
			if not on_road[i]:
				for sd in [-1.0, 1.0]:
					var e2 = m + nr * (half + 0.45) * sd
					b.box(Vector3(e2.x, gy.call(e2) + 0.45, e2.y), Vector3(0.9, 1.5, L + 0.12), STONE, yaw, true)
	# köprü korkulukları: her köprü bölgesinin (yol kesişimi) iki ucunda kırmızı lake korkuluk
	var i0 = -1
	for i in smp.size():
		var inb = i < smp.size() - 1 and on_road[i]
		if inb and i0 < 0:
			i0 = i
		elif not inb and i0 >= 0:
			_rails(b, smp, i0, i, half, gy)
			i0 = -1
	var mi = MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _water()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = b.view_dist
	b.root.add_child(mi)
	# kıyı süsleri: söğüt, fener, suya inen basamak (köprülerden uzak)
	for i in range(6, smp.size() - 6, 9):
		if bridge[i] or bridge[maxi(0, i - 4)] or bridge[mini(smp.size() - 1, i + 4)]:
			continue
		var p: Vector2 = smp[i]
		var dir2 = ((smp[i + 1] as Vector2) - p).normalized()
		var nr2 = Vector2(-dir2.y, dir2.x)
		var sd = 1.0 if (i / 9) % 2 == 0 else -1.0
		var bank = p + nr2 * (half + 3.2) * sd
		var wb = b.w(Vector3(bank.x, 0, bank.y))
		if not b.area_free(Vector2(wb.x, wb.z), 2.0):
			continue
		match (i / 9) % 4:
			0, 2:
				b.tree(bank.x, bank.y, rng.randf_range(0.9, 1.2), rng, gy.call(bank))
			1:
				b.lantern(bank.x, bank.y, 3.2 + gy.call(bank))
			3:
				var yaw2 = rad_to_deg(atan2(dir2.x, dir2.y))
				for k in 3:
					var sp = p + nr2 * (half + 0.4 - k * 0.5) * sd
					b.box(Vector3(sp.x, gy.call(sp) + 1.1 - k * 0.35, sp.y), Vector3(0.6, 0.18, 2.2), CAP.darkened(0.05 * k), yaw2, false)


static func _rails(b: Builder, smp: Array, i0: int, i1: int, half: float, gy: Callable) -> void:
	var a: Vector2 = smp[maxi(0, i0 - 2)]
	var c: Vector2 = smp[mini(smp.size() - 1, i1 + 1)]
	var dir = (c - a).normalized()
	var nr = Vector2(-dir.y, dir.x)
	var yaw = rad_to_deg(atan2(nr.x, nr.y))
	# korkuluk kanala dik (yol yönünde) iki yanda: suyun kenar çizgisi boyunca
	for sd in [-1.0, 1.0]:
		for end in [a, c]:
			var e: Vector2 = end + nr * 0.0
			var p0 = e - nr * (half + 0.4)
			var p1 = e + nr * (half + 0.4)
			var m = (p0 + p1) * 0.5 + dir * 0.0
			var g = gy.call(m)
			if sd < 0:
				b.box(Vector3(m.x, g + 1.05, m.y), Vector3(0.18, 0.12, half * 2.0 + 0.8), RAIL, rad_to_deg(atan2(dir.x, dir.y)) + 90.0, false)
			else:
				for k in 3:
					var pp = p0.lerp(p1, k / 2.0)
					b.box(Vector3(pp.x, g + 0.6, pp.y), Vector3(0.22, 0.95, 0.22), RAIL.darkened(0.15), 0.0, false)
				b.box(Vector3(m.x, g + 0.95, m.y), Vector3(half * 2.0 + 1.0, 0.12, 0.12), RAIL, yaw, false)


static func _water() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new()
		var sh = Shader.new()
		sh.code = """
shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;
// kanal suyu: akış yönünde kayan dalga çizgileri, kenarlarda açık köpük, hafif saydam
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) { vec2 i = floor(p), f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y); }
void fragment() {
	vec2 uv = UV;
	float flow = TIME * 0.35;
	float n = vn(vec2(uv.x * 3.0, uv.y * 2.0 - flow * 2.0)) * 0.6 + vn(vec2(uv.x * 7.0 + 3.0, uv.y * 5.0 - flow * 3.3)) * 0.4;
	float streak = smoothstep(0.72, 0.8, n);
	float edge = smoothstep(0.12, 0.0, uv.x) + smoothstep(0.88, 1.0, uv.x);
	vec3 deep = vec3(0.05, 0.2, 0.27);
	vec3 shallow = vec3(0.13, 0.36, 0.42);
	vec3 c = mix(deep, shallow, n * 0.6 + edge * 0.4);
	c = mix(c, vec3(0.8, 0.92, 0.98), streak * 0.45 + edge * 0.18);
	ALBEDO = c;
	ROUGHNESS = 0.08;
	METALLIC = 0.0;
	SPECULAR = 0.5;
	ALPHA = 0.88;
}
"""
		_mat.shader = sh
	return _mat
