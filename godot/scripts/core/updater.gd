class_name Updater
extends Node
## Otomatik güncelleme: ana exe açılışta GitHub'daki public sürüm reposunun son release'ine bakar.
## Daha yeni sürüm varsa sorar → exe'yi yanına indirir (ShinobiYolu.new) → küçük bir .bat ile eski exe'yi değiştirip yeniden açar.
## Kayıtlar user:// klasöründe olduğundan güncellemede korunur. Yalnız gerçek ana exe'de çalışır (test/skilltest/editörde değil).

const REPO := "serpetian-spec/shinobi-yolu-surum"
const API := "https://api.github.com/repos/%s/releases/latest"
const ASSET := "ShinobiYolu.exe"

var http: HTTPRequest
var dl: HTTPRequest
var new_path := ""
var bar: Label = null
var total := 0


static func enabled() -> bool:
	if not OS.has_feature("template") or Game.build_tag != "main":
		return false
	var exe = OS.get_executable_path().get_file().to_upper()
	return exe == ASSET.to_upper()


## Sürüm karşılaştırma: "0.275.0" > "0.274.0"
static func newer(remote: String, local: String) -> bool:
	var a = remote.trim_prefix("v").split(".")
	var b = local.trim_prefix("v").split(".")
	for i in maxi(a.size(), b.size()):
		var x = int(a[i]) if i < a.size() else 0
		var y = int(b[i]) if i < b.size() else 0
		if x != y:
			return x > y
	return false


func check() -> void:
	if not enabled():
		return
	http = HTTPRequest.new()
	http.timeout = 15.0
	add_child(http)
	http.request_completed.connect(_on_info)
	var err = http.request(API % REPO, ["User-Agent: ShinobiYolu-Updater", "Accept: application/vnd.github+json"])
	if err != OK:
		http.queue_free()


func _on_info(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return   # internet yok / repo yok: sessizce oyuna devam
	var d = JSON.parse_string(body.get_string_from_utf8())
	if not d is Dictionary:
		return
	var tag = String(d.get("tag_name", ""))
	if not newer(tag, Game.version):
		return
	var url = ""
	for a in d.get("assets", []):
		if String(a.get("name", "")) == ASSET:
			url = String(a.get("browser_download_url", ""))
			total = int(a.get("size", 0))
	if url == "":
		return
	var notes = String(d.get("body", "")).strip_edges()
	if notes.length() > 600:
		notes = notes.left(600) + "..."
	Hud.dialog("Yeni Sürüm: %s" % tag, "Şu an v%s oynuyorsun. Yeni sürüm hazır (%d MB).\n\n%s" % [Game.version, total / 1048576, notes], [
		{"label": "İndir ve güncelle", "cb": func(): _download(url, tag)},
		{"label": "Sonra", "cb": func(): pass}])


func _download(url: String, tag: String) -> void:
	new_path = OS.get_executable_path().get_base_dir().path_join("ShinobiYolu.new")
	dl = HTTPRequest.new()
	dl.download_file = new_path
	dl.download_chunk_size = 1 << 20
	dl.max_redirects = 10
	add_child(dl)
	dl.request_completed.connect(func(result, code, _h, _b): _on_done(result, code, tag))
	var layer = CanvasLayer.new()
	layer.layer = 120
	add_child(layer)
	bar = Label.new()
	bar.add_theme_font_size_override("font_size", 28)
	bar.add_theme_color_override("font_outline_color", Color.BLACK)
	bar.add_theme_constant_override("outline_size", 8)
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.position = Vector2(-300, -120)
	bar.size = Vector2(600, 50)
	bar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(bar)
	bar.text = "Güncelleme indiriliyor..."
	if dl.request(url, ["User-Agent: ShinobiYolu-Updater"]) != OK:
		bar.text = "İndirme başlatılamadı."


func _process(_dt: float) -> void:
	if dl and is_instance_valid(dl) and bar:
		var got = dl.get_downloaded_bytes()
		var tot = maxi(total, dl.get_body_size())
		bar.text = "Güncelleme indiriliyor... %d / %d MB" % [got / 1048576, tot / 1048576] if tot > 0 else "Güncelleme indiriliyor... %d MB" % (got / 1048576)


func _on_done(result: int, code: int, tag: String) -> void:
	dl.queue_free()
	dl = null
	var ok = result == HTTPRequest.RESULT_SUCCESS and code == 200 and FileAccess.file_exists(new_path)
	if ok and total > 0:
		var f = FileAccess.open(new_path, FileAccess.READ)
		ok = f != null and f.get_length() == total
	if not ok:
		if bar:
			bar.text = "Güncelleme indirilemedi (internet?). Sonra tekrar denenecek."
		DirAccess.remove_absolute(new_path)
		return
	bar.text = "%s indirildi — oyun yeniden açılıyor..." % tag
	Game.save_game() if Game.player else null
	var dir = OS.get_executable_path().get_base_dir()
	var bat = dir.path_join("guncelle.bat")
	var f = FileAccess.open(bat, FileAccess.WRITE)
	# eski exe kapanana kadar bekle, yenisini yerine koy, oyunu aç, kendini sil
	f.store_string("@echo off\r\ncd /d \"%s\"\r\n:bekle\r\nping -n 2 127.0.0.1 >nul\r\nmove /y \"ShinobiYolu.new\" \"%s\" >nul 2>&1 || goto bekle\r\nstart \"\" \"%s\"\r\ndel \"%%~f0\"\r\n" % [dir.replace("/", "\\"), ASSET, ASSET])
	f.close()
	await get_tree().create_timer(1.0).timeout
	OS.create_process("cmd.exe", ["/c", bat.replace("/", "\\")])
	get_tree().quit()
