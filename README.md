# Shinobi Yolu

Godot 4.7 ile yapılmış açık dünya ninja aksiyon / RPG oyunu. Beş büyük köy, klanlar, doğa dönüşümleri, kuyruklu canavarlar, rütbe sınavları (Akademi → Genin → Chūnin → Jōnin → ANBU → Kage), görevler, Bingo Kitabı, dostluklar ve kendi genin takımını yetiştirme.

## Oynamak

**Releases** sayfasından `ShinobiYolu.exe`'yi indir ve çalıştır (Windows, kurulum gerekmez).

### Tuşlar

| Tuş | İş |
|---|---|
| W A S D | Hareket |
| Space / Ctrl / Shift | Zıpla / uzun sıçrayış / atılma |
| Sol tık / Sağ tık | Saldırı / blok |
| 1–6 | Jutsu yuvaları |
| G | Mühür modu |
| Q | Kawarimi (yer değiştirme) |
| C | Chakra doldur |
| R / T | Fırlat / fırlatılacak aleti değiştir |
| E veya orta tık | Hedefe kilitlen |
| F | Etkileşim / konuş |
| H / Y / O | Merhem / hap / hap değiştir |
| V / Z / X / B | Göz / Sennin / Canavar / Kapılar modları |
| N | Silah çek |
| J / U | Çağrı komutu / çağrı özel |
| L | Haritadaki işaretçiyi değiştir (görev, dost, aranan, hedef) |
| Tab / I / K / M | Ninja menüsü / envanter / jutsular / harita |
| Esc | Duraklat |

## Kaynaktan derlemek

1. Godot 4.7.2'yi indir ve `tools/` klasörüne koy.
2. `python build.py main` komutunu çalıştır. Exe `Oyun/` klasörüne çıkar.

Godot projesi `godot/` klasöründe. Testler `godot/tests/` altında, `--test=res://tests/<ad>.gd` ile çalışır.
