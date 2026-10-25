extends Node
## Statik oyun verisi (autoload "Data"). Jutsu/klan/eşya tabloları research/ JSON'larından derlenmiş data/*.json'dan yüklenir.

const RANKS := ["Akademi Öğrencisi", "Genin", "Chunin", "Jonin", "ANBU", "Kage Adayı", "Kage"]

var jutsu = {}
var clans = {}
var items = {}
var skills = {}   # yetenek ağacı: {branches, nodes, sp_per_level, ...}
var seals: Array = []


func _ready() -> void:
	for pair in [["jutsu", "res://data/jutsu.json"], ["clans", "res://data/clans.json"], ["items", "res://data/items.json"], ["skills", "res://data/skills.json"]]:
		if FileAccess.file_exists(pair[1]):
			var d = JSON.parse_string(FileAccess.get_file_as_string(pair[1]))
			if d != null:
				set(pair[0], d)
	if jutsu.has("_seals"):
		seals = jutsu["_seals"]


## 100 seviye uzun vadeli hedef: erken seviyeler hızlı, 50'den sonra yavaşlar
const MAX_LEVEL := 100
func xp_for_level(lv: int) -> int:
	# yumuşak eğri: düşman ve görev XP'si de seviyeyle büyüdüğü için yüksek seviyeler tıkanmaz
	return int(40.0 + 11.0 * pow(lv, 1.55))   # Sv.10 ~430, Sv.24 ~1.5k, Sv.50 ~4.6k, Sv.99 ~13.5k
