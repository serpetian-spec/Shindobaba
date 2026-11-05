extends Node
## Güncelleyici: sürüm karşılaştırma + editör/test exe'sinde kapalı olmalı
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	var cases = [["v0.275.0", "0.274.0", true], ["v0.274.0", "0.274.0", false], ["v0.273.0", "0.274.0", false], ["v1.0.0", "0.999.0", true], ["0.274.1", "0.274.0", true]]
	var ok = true
	for c in cases:
		var r = Updater.newer(c[0], c[1])
		ok = ok and r == c[2]
		print("UPD newer(%s, %s) = %s (beklenen %s)" % [c[0], c[1], r, c[2]])
	print("UPD enabled in test = %s (false beklenir)  ALL_OK=%s" % [Updater.enabled(), ok and not Updater.enabled()])
	get_tree().quit()
