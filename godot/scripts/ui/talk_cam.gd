class_name TalkCam
extends Node
## RPG tarzı konuşma kamerası: diyalog açılınca konuşanın yüzüne yakın omuz üstü çekim; cevap seçenekleri gösterilirken
## oyuncunun yüzüne döner. Konuşan karakterin ağzı metin akarken açılıp kapanır. Diyalog kapanınca oyuncu kamerasına yumuşak dönüş.
## Hud.dialog() bunu çağırır (speaker: title ile en yakın konuşulabilir karakter).

static var inst: TalkCam
var cam: Camera3D
var speaker: Node3D = null
var focus_player := false
var talk_t := 0.0
var _blend := 0.0
var _active := false


static func ensure() -> TalkCam:
	if inst == null or not is_instance_valid(inst):
		inst = TalkCam.new()
		inst.name = "TalkCam"
		Game.get_tree().current_scene.add_child(inst)
	return inst


func _ready() -> void:
	cam = Camera3D.new()
	cam.fov = 40.0
	add_child(cam)


## Diyalog başladı: konuşan karakter + yazının akma süresi (ağız oynar)
func begin(sp: Node3D, talk_dur: float) -> void:
	if Game.player == null or sp == null or not is_instance_valid(sp) or sp == Game.player:
		return
	if sp.global_position.distance_to(Game.player.global_position) > 6.0 or Game.player.get("interior_locked"):
		return
	speaker = sp
	focus_player = false
	talk_t = talk_dur
	if not _active:
		_active = true
		_blend = 0.0
		cam.global_transform = Game.player.cam.global_transform
		if Game.world and Game.world.get("env"):
			Game.world.env.attach_post(cam)
	cam.current = true


## Cevap seçenekleri: oyuncunun yüzüne dön
func to_player() -> void:
	focus_player = true


func end() -> void:
	_active = false
	speaker = null
	if Game.player and Game.player.cam:
		Game.player.cam.current = true
		if Game.world and Game.world.get("env"):
			Game.world.env.attach_post(Game.player.cam)


static func _face_pos(n: Node3D) -> Vector3:
	var m = n.get("model")
	if m and m.get("skel"):
		var sk: Skeleton3D = m.skel
		var bi = sk.find_bone("Head")
		if bi >= 0:
			return (sk.global_transform * sk.get_bone_global_pose(bi)).origin + Vector3(0, 0.08, 0)
	return n.global_position + Vector3.UP * 1.6


static func _fwd(n: Node3D) -> Vector3:
	var m = n.get("model")
	var y = m.global_rotation.y if m else n.global_rotation.y
	return Vector3(sin(y), 0, cos(y))


func _process(dt: float) -> void:
	if not _active:
		return
	if not Hud.dialog_open() or speaker == null or not is_instance_valid(speaker) or Game.player == null:
		end()
		return
	var pl: Node3D = Game.player
	var a: Node3D = pl if focus_player else speaker
	var b: Node3D = speaker if focus_player else pl
	var fa = _face_pos(a)
	var fb = _face_pos(b)
	var to_b = (fb - fa)
	to_b.y = 0.0
	var dir = to_b.normalized() if to_b.length() > 0.1 else _fwd(a)
	var side = dir.cross(Vector3.UP).normalized()
	# karşıdakinin omzunun üstünden, konuşanın yüzüne (yüz ekranın 1/3'ünde)
	var want_pos = fa + dir * 1.55 + side * 0.45 + Vector3(0, 0.05, 0)
	var want_look = fa + side * 0.12 - Vector3(0, 0.03, 0)
	_blend = minf(1.0, _blend + dt * 2.5)
	var k = 1.0 - exp(-dt * 6.0)
	var cur = cam.global_transform
	var tgt = Transform3D(Basis.looking_at(want_look - want_pos, Vector3.UP), want_pos)
	cam.global_transform = cur.interpolate_with(tgt, k if _blend >= 1.0 else maxf(k, _blend * 0.25))
	# ağız: konuşan karakter yazı akarken oynar
	talk_t = maxf(0.0, talk_t - dt)
	var m = speaker.get("model")
	if m and m.has_method("set_mouth"):
		var open = 0.0
		if talk_t > 0.0 and not focus_player:
			open = clampf(0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.028) * sin(Time.get_ticks_msec() * 0.011 + 1.3), 0.0, 1.0)
		m.set_mouth(open)
