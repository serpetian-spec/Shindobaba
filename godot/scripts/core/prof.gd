class_name Prof
extends RefCounted
## Geçici profil sayaçları (mikrosaniye toplamı + çağrı sayısı)
static var data := {}
static var peak := {}

static func add(k: String, us: int) -> void:
	data[k] = data.get(k, 0) + us
	peak[k] = maxi(peak.get(k, 0), us)

static func reset() -> void:
	data.clear()
	peak.clear()
