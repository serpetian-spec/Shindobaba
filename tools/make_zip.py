"""Arkadaşa gönderilecek zip: Oyun/ShinobiYolu.exe + OKU BENİ.txt -> ShinobiYolu_v<VERSION>.zip (kök klasör). "güncelle" sonrası çalıştır."""
import os, zipfile
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
v = open('VERSION').read().strip()
out = 'ShinobiYolu_v%s.zip' % v
readme = open(os.path.join('tools', 'oku_beni.txt'), encoding='utf-8').read().replace('{v}', v)
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    z.write('Oyun/ShinobiYolu.exe', 'ShinobiYolu/ShinobiYolu.exe')
    z.writestr('ShinobiYolu/OKU BENİ.txt', readme.replace('\n', '\r\n').encode('utf-8-sig'))
print(out, os.path.getsize(out) // 1048576, 'MB', 'bozuk' if zipfile.ZipFile(out).testzip() else 'OK')
