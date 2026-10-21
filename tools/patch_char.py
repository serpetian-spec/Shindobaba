"""CharacterModel'i Quaternius Universal Base Characters gövdesine uyarlar (bölge renkleri + eklentiler)."""
import sys

p = sys.argv[1]
s = open(p, encoding='utf8').read()

start = s.index("func _region_color")
end = s.index("# ------------------------------------------------------------------ eklentiler")
s = s[:start] + '''func _region_color(bn: String, p: Vector3) -> Color:
	## alfa 0 = ten dokusu görünür, alfa 1 = kıyafet rengi
	var L = look
	var SKIN = Color(1, 1, 1, 0)
	if bn.contains("Head") or bn == "":
		return SKIN
	if bn.contains("Neck"):
		return _opaque(L["vest"]) if L["vest"] != null else SKIN
	if bn.contains("Hand") or bn.contains("Thumb") or bn.contains("Index") or bn.contains("Middle") or bn.contains("Ring") or bn.contains("Little") or bn.contains("leaf"):
		return SKIN
	if bn.contains("LowerArm"):
		if not L["sleeves"]:
			return _opaque(L["wraps"]) if absf(p.x) > 0.5 else SKIN
		return _opaque(L["wraps"]) if absf(p.x) > 0.55 else _opaque(L["top"])
	if bn.contains("UpperArm") or bn.contains("Shoulder"):
		return _opaque(L["top"])
	if bn.contains("Chest") or bn == "Spine":
		if L["vest"] != null:
			return _opaque(L["vest"])
		return _opaque(L["top2"]) if p.y > 1.38 else _opaque(L["top"])
	if bn.contains("Hips"):
		return _opaque(L["top2"]) if p.y > 1.0 else _opaque(L["pants"])
	if bn.contains("UpperLeg"):
		return _opaque(L["pants"])
	if bn.contains("LowerLeg"):
		return _opaque(L["wraps"]) if p.y < 0.3 else _opaque(L["pants"])
	if bn.contains("Toes"):
		return SKIN
	if bn.contains("Foot"):
		return _opaque(L["sandal"])
	return _opaque(L["top"])


func _opaque(c) -> Color:
	var cc: Color = c
	return Color(cc.r, cc.g, cc.b, 1.0)


'''+s[end:]

start = s.index("func _head_frame()")
end = s.index("func _hair_mesh(")
s = s[:start] + open(sys.argv[2], encoding='utf8').read() + "\n\n" + s[end:]

start = s.index("func set_eye_color")
end = s.index("func flash(")
s = s[:start] + '''func set_eye_color(c: Color) -> void:
	if eye_mat:
		eye_mat.set_shader_parameter("eye_color", c)


''' + s[end:]
open(p, 'w', encoding='utf8').write(s)
print('ok')
