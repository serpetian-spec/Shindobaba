class_name SharkArt
extends RefCounted
## Kisame'nin su köpekbalıkları (anime): torpido gövde, üstü koyu mavi / karnı beyaz, yüksek sırt yüzgeci, göğüs yüzgeçleri,
## hilal kuyruk (sallanır), açık ağız + diş sıraları, küçük kara göz, solungaç çizgileri; yüzeyde su parıltısı.
## +Z ile kurulur, kök -Z'ye bakar (ClayArt._fwd). s=1: ~2.2 m

const TOP := Color(0.16, 0.36, 0.72)
const BELLY := Color(0.88, 0.94, 1.0)
const DARK := Color(0.05, 0.06, 0.1)

static var _mat: ShaderMaterial


static func mat() -> ShaderMaterial:
	# referans (Gōshokuzame/Daikōdan kareleri): köpekbalıkları SUDAN — yarı saydam soluk mavi-ak, akan köpük çizgili
	# (eskiden opak koyu mavi toon balık: oyuncak gibi duruyordu)
	if _mat == null:
		_mat = VFX.mat_water(Color(0.32, 0.58, 0.85), Color(0.62, 0.84, 0.97), Color(0.95, 1.0, 1.0), Vector3(0, 0, 1), 0.74, 0.95, 0.05)
	return _mat


static func _col(_t: float, ang: float, _sd) -> Color:
	# üst mavi, alt beyaz; arada keskin anime sınırı
	var up = sin(ang)
	return BELLY if up < -0.15 else TOP.lerp(TOP.lightened(0.25), clampf(1.0 - up, 0.0, 1.0) * 0.5)


static func _mi(b: MB) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(mat())
	mi.material_override = mat()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func shark(s := 1.0) -> Node3D:
	var root = Node3D.new()
	var b = MB.new()
	var pts = [Vector3(0, 0.0, 1.1), Vector3(0, 0.04, 0.95), Vector3(0, 0.06, 0.6), Vector3(0, 0.05, 0.2), Vector3(0, 0.03, -0.25), Vector3(0, 0.02, -0.6)]
	var rad = [Vector2(0.06, 0.05), Vector2(0.17, 0.14), Vector2(0.27, 0.25), Vector2(0.27, 0.26), Vector2(0.18, 0.17), Vector2(0.07, 0.07)]
	Loft.tube(b, ClayArt._sc(pts, s), ClayArt._sc(rad, s), TOP, 18, 3, true, true, _col)
	# alt çene (açık ağız): burnun altından geriye
	Loft.tube(b, ClayArt._sc([Vector3(0, -0.3, 0.85), Vector3(0, -0.25, 0.62), Vector3(0, -0.14, 0.38)], s), ClayArt._sc([Vector2(0.07, 0.035), Vector2(0.15, 0.06), Vector2(0.21, 0.09)], s), BELLY, 12, 3)
	# ağız içi koyu + üst ve alt diş sırası
	b.add("sphere", Vector3(0, -0.15, 0.74) * s, Vector3(0.26, 0.17, 0.32) * s, Color(0.55, 0.12, 0.18), Vector3.ZERO, 12)
	for q in 7:
		var a = (q - 3) * 0.32
		var tp = Vector3(sin(a) * 0.13, -0.07, 0.9 - absf(q - 3) * 0.06)
		b.add("cone", tp * s, Vector3(0.05, 0.11, 0.04) * s, Color.WHITE, Vector3(180, 0, 0), 4)
		b.add("cone", (tp + Vector3(0, -0.19, -0.04)) * s, Vector3(0.045, 0.09, 0.04) * s, Color.WHITE, Vector3.ZERO, 4)
	for sx in [-1.0, 1.0]:
		b.add("sphere", Vector3(sx * 0.2, 0.1, 0.76) * s, Vector3(0.05, 0.07, 0.07) * s, DARK, Vector3.ZERO, 8)
		for q in 3:   # solungaç çizgileri
			b.add("box", Vector3(sx * 0.255, 0.0, 0.42 - q * 0.07) * s, Vector3(0.012, 0.16, 0.015) * s, TOP.darkened(0.45), Vector3(0, 0, sx * 8.0))
		# göğüs yüzgeci: geriye ve aşağı süpürülmüş
		Loft.tube(b, ClayArt._sc([Vector3(sx * 0.2, -0.12, 0.35), Vector3(sx * 0.42, -0.24, 0.15), Vector3(sx * 0.58, -0.32, -0.05)], s), ClayArt._sc([Vector2(0.12, 0.025), Vector2(0.09, 0.02), Vector2(0.02, 0.01)], s), TOP, 8, 3)
	# yüksek sırt yüzgeci (geriye eğik)
	Loft.tube(b, ClayArt._sc([Vector3(0, 0.25, 0.25), Vector3(0, 0.45, 0.08), Vector3(0, 0.62, -0.1)], s), ClayArt._sc([Vector2(0.025, 0.16), Vector2(0.02, 0.1), Vector2(0.008, 0.02)], s), TOP, 8, 3)
	root.add_child(_mi(b))
	# hilal kuyruk: ayrı pivot, yüzerken sallanır
	var tail = Node3D.new()
	tail.position = Vector3(0, 0.02, -0.55) * s
	var tb = MB.new()
	Loft.tube(tb, ClayArt._sc([Vector3(0, 0, 0), Vector3(0, 0.25, -0.2), Vector3(0, 0.5, -0.38)], s), ClayArt._sc([Vector2(0.03, 0.09), Vector2(0.025, 0.07), Vector2(0.008, 0.015)], s), TOP, 8, 3)
	Loft.tube(tb, ClayArt._sc([Vector3(0, 0, 0), Vector3(0, -0.18, -0.16), Vector3(0, -0.32, -0.28)], s), ClayArt._sc([Vector2(0.03, 0.08), Vector2(0.025, 0.06), Vector2(0.008, 0.015)], s), TOP, 8, 3)
	tail.add_child(_mi(tb))
	root.add_child(tail)
	var tw = tail.create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tail.rotation.y = -0.45
	tw.tween_property(tail, "rotation:y", 0.45, 0.22)
	tw.tween_property(tail, "rotation:y", -0.45, 0.22)
	return ClayArt._fwd(root)
