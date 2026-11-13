# Shinobi Yolu — çalışma kılavuzu

Godot 4.7.2 projesi (`godot/`), GDScript. Naruto evreninde açık dünya ninja oyunu; kanon karakter yok.
Ayrıntılı kurallar ve süren işler hafıza dizininde (`MEMORY.md` dizini); burası yalnız her oturumda gereken çekirdek.

## Dizin
- `godot/scripts/` oyun kodu (`core`, `actors`, `world`, `combat`…), `godot/tests/` test betikleri, `godot/data/` veri
- `tools/` yardımcı betikler ve Godot konsol exe'si (`tools/Godot_v4.7.2-stable_win64_console.exe`)
- `_tmp/` tüm geçici dosyalar, ölçüm çıktıları, test görüntüleri (C: sürücüsüne yazma)
- `refs/` referans görseller, `Ekran görüntüleri/` kullanıcıya gösterilecek kontrol görüntüleri

## Komutlar
```bash
python tools/gdcheck.py                 # sözdizimi denetimi (~25 sn) — her .gd değişikliğinden sonra, koşudan ÖNCE
python build.py test                    # test exe
python build.py main                    # ana exe (yalnız "güncelle" denince)

# test koşusu (godot/ içinden; pencere ekran dışında, Konoha önbellekten)
BAKE_ANY=1 timeout 200 ../tools/Godot_v4.7.2-stable_win64_console.exe --log-file "D:/Naruto 3D Game/_tmp/test_godot.log" --path . --resolution 960x540 \
  --position 9000,0 -- --test=res://tests/TEST.gd > ../_tmp/cikti.txt 2>&1

# takılma ölçümü
python _tmp/instr.py                    # her _process'i sarar; iş bitince MUTLAKA: python _tmp/instr.py off
TAG=X PROFV=1 bash _tmp/run_ht.sh       # 16 / 70 / 300 m/sn; 10 dakikayı aşar → hızları ayrı koş
```
- `BAKE_ANY=1`: Konoha kodu değişmiş olsa bile eski köy önbelleğini kullanır (açılış 47 → 7 sn). Köy yapısını / çarpışmasını
  denetleyen testlerde KULLANMA (eski köyü görürsün). Geliştirme önbelleği `_tmp/bake_dev/`, yayınlanan oyununki ayrı.
- Oyun / dünya testlerinde `--headless` YASAK (köy önbelleğini bozar). Yalnız `gdcheck` headless çalışır.
- İlk koşunun çıktısında önce `Parse Error` / `SCRIPT ERROR` ara; hatalı betikle uzun ölçüm boşa gider.
- Aynı anda tek Godot. Takılan testi 2 dakikada kes.
- Her Godot koşusunda `--log-file` ver (yukarıdaki gibi): vermezsen oyunun kayıt klasörüne yazar ve 30 dosya sınırı yüzünden
  kullanıcının oynadığı oturumun FPS kaydını siler.

## "güncelle" = yayın
`python build.py main` → `python tools/make_zip.py` → commit → `git push origin master:main` →
`python tools/github_release.py "notlar"`. Sürüm notu Türkçe, oyuncu gözüyle (iç değişken adı yok).
"güncelle" denmeden yayınlama, commit atma.

## Çalışma kuralları
1. Kullanıcıya her zaman Türkçe yaz; iç değişken / işlev adı yazma, oyundaki karşılığını söyle.
2. Sorma, yap. Açık karar gerektirmeyen her şeyde kendi kararını ver, sonunda kısaca bildir.
3. Alt ajan kullanma; işi doğrudan ve sırayla yap.
4. Godot pencereleri kullanıcının ekranına gelmez (`--position 9000,0`; test kipinde pencere zaten ekran dışı).
5. Küçük hata = küçük düzeltme: ölç, o değeri kare kare yazan yeri bul, yalnız onu değiştir. Çalışan pozlara / yaklaşıma dokunma.
6. Küçük düzeltmede test yağdırma: sayıyla çöz, tek kısa doğrulama.
7. Her görsel değişiklik birkaç açıdan görüntüyle, her mekanik oyun içi akışla doğrulanır; doğrulanamayanı açıkça söyle.
   "Animeye benziyor" gibi doğrulanmamış iddia yok.
8. Kaynak varsa (video / foto / wiki) önce ona bak ve onu uygula; kafadan tasarlama. Birden çok kaynak varsa ortak tasarımı çıkar.
9. Kanon önce: jutsu / klan / yol mekaniği animedeki gibi işler (şart, bedel, zayıflık). Denge için yalnız sayılar oynar;
   genel oyun kuralı kanonla çakışırsa anime kazanır.
10. Her jutsu kendine özgü görünüş ve mekanik; renk değiştirilmiş kalıp, görünür geometrik kabuk, her efekte duman yok.
11. Önce oyunda o işi yapan sistemi bul ve onu kullan (yeni paralel sistem kurma).
12. Her mekanik değişiklik yapay zekâ için de geçerli (bekleme süresi, sersemletme, silah bonusu…).
13. Dünya oyuncu merkezli değil: düşman oyuncuya göre ölçeklenmez, olay kişinin gerçek yerinde olur, görev sırasında araya olay / doğuş girmez.
14. Çeşitlilik sabit listeden değil dünya verisinden; her akış uçtan uca tüm köylerde denenir.
15. Zorluk şikâyetinde ilgili sayıyı düşür; genel sınır / formül kuralı ekleme, düşmanı topluca zayıflatma.
16. İsimler Japonca romaji (jutsu, örgüt, eşya); Türkçe yalnız açıklama ve konuşmada.
17. Yeni menü seçenekleri ◀ ▶ seçici; karo / çip satırı yok.
18. Çarpışma görselin kendi şeklinden; ulaşılabilir her kaya / yapı katıdır. Görünmez duvar bırakma.
19. Vücut değiştiren teknikler gerçek kemikleri büyütür / biçimlendirir; kutu-küre el yok. Sarkan parçalar (saç, kumaş) ikincil hareketli.
20. Hazır model / doku eklenince exe paketine girdiğini doğrula (editör görür, exe görmeyebilir); arkadaşın kartı 4 GB — doku bütçesine dikkat.

## Tuzaklar
- Dosyalar CRLF; betikle yamalarken satır sonunu koru.
- `PackedStringArray.any()` yok → `Array(...)` ile sar. İş parçacığında `surface_get_arrays` çöker → köşe dizilerini önbellekten ver.
- Paketli diziler paylaşılır; önbellekten verirken derin kopya.
- `character_model.gd` içinde `PROF` korumalı geçici satırlar var (PROFA, PROFB, PROFG, DBG*): zararsız, o dosyada iş yaparken temizlenebilir.
