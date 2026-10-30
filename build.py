"""Godot projesini Windows exe olarak dışa aktarır.
  python build.py test   -> Test\\ShinobiYolu_TEST.exe  (her değişiklikten sonra)
  python build.py main   -> Oyun\\ShinobiYolu.exe       ("güncelle" denince, sürüm artar)
"""
import os
import sys
import json
import shutil
import subprocess

ROOT = os.path.dirname(os.path.abspath(__file__))
GODOT = os.path.join(ROOT, 'tools', 'Godot_v4.7.2-stable_win64_console.exe')
PROJ = os.path.join(ROOT, 'godot')
mode = sys.argv[1] if len(sys.argv) > 1 else 'test'
assert mode in ('test', 'main')

ver_file = os.path.join(ROOT, 'VERSION')
version = open(ver_file).read().strip() if os.path.exists(ver_file) else '0.2.0'
if mode == 'main' and '--no-bump' not in sys.argv:
    a, b, c = map(int, version.split('.'))
    version = f'{a}.{b + 1}.0'
    open(ver_file, 'w').write(version)

build_json = os.path.join(PROJ, 'data', 'build.json')
import hashlib
def _world_key():
    # godot/scripts/world/village_bake.gd key() ile aynı: res:// yolu + dosya md5, sıralı; md5 hex'in ilk 12'si
    files = []
    for d in ['scripts/world', 'data/world']:
        for f in os.listdir(os.path.join(PROJ, d)):
            if f.endswith(('.gd', '.json', '.bin', '.png')):
                files.append('res://%s/%s' % (d, f))
    files += ['res://scripts/actors/character_model.gd', 'res://scripts/actors/outfit_parts.gd']
    files.sort()
    acc = ''.join(f + hashlib.md5(open(os.path.join(PROJ, f[6:]), 'rb').read()).hexdigest() for f in files)
    return hashlib.md5(acc.encode('utf-8')).hexdigest()[:12]
json.dump({'build': mode, 'version': version, 'world': _world_key()}, open(build_json, 'w'))

name = 'ShinobiYolu_TEST' if mode == 'test' else 'ShinobiYolu'
out_dir = os.path.join(ROOT, 'Test' if mode == 'test' else 'Oyun')
os.makedirs(out_dir, exist_ok=True)
for f in os.listdir(out_dir):  # eski (Python sürümü) exe'leri temizle
    if f.endswith('.exe') or f.endswith('.pck'):
        os.remove(os.path.join(out_dir, f))
exe = os.path.join(out_dir, name + '.exe')


def used_sketchfab():
    """Kodda kullanılan hayran modeli klasörleri (sf_models.gd + sf_props.gd içindeki "file": "...")."""
    import re
    used = set()
    for rel in ('scripts/actors/sf_models.gd', 'scripts/actors/sf_props.gd'):
        f = os.path.join(PROJ, rel)
        if os.path.exists(f):
            src = open(f, encoding='utf8').read()
            if 'const USE_FAN := false' in src:   # hayran silah/aksesuar modelleri kapalı: pakete girmesin
                continue
            used |= set(re.findall(r'"file":\s*"([^"]+)"', src))
    # yerler için doğrudan yolla yüklenen modeller (ör. Sonun Vadisi: res://assets/sketchfab/valley_of_end/...)
    f = os.path.join(PROJ, 'scripts/world/build_sites.gd')
    if os.path.exists(f):
        used |= set(re.findall(r'res://assets/sketchfab/([^/"]+)/', open(f, encoding='utf8').read()))
    return used


# kullanılmayan Sketchfab modellerini paketten çıkar (assets/sketchfab ~1.4 GB)
presets = os.path.join(PROJ, 'export_presets.cfg')
presets_orig = open(presets, encoding='utf8', newline='').read()
sf_dir = os.path.join(PROJ, 'assets', 'sketchfab')
excl = ['tests/*']
if os.path.isdir(sf_dir):
    used = used_sketchfab()
    unused = sorted(d for d in os.listdir(sf_dir) if os.path.isdir(os.path.join(sf_dir, d)) and d not in used)
    excl += ['assets/sketchfab/%s/*' % d for d in unused]
    print(f'Sketchfab: {len(used & set(os.listdir(sf_dir)))} model pakette, {len(unused)} dışarıda')
open(presets, 'w', encoding='utf8', newline='').write(presets_orig.replace('exclude_filter="tests/*"', 'exclude_filter="%s"' % ', '.join(excl), 1))
try:
    subprocess.run([GODOT, '--headless', '--path', PROJ, '--import'], capture_output=True)
    r = subprocess.run([GODOT, '--headless', '--path', PROJ, '--export-release', 'Windows', exe], capture_output=True, text=True)
finally:
    open(presets, 'w', encoding='utf8', newline='').write(presets_orig)
json.dump({'build': 'dev', 'version': version}, open(build_json, 'w'))
errors = [l for l in (r.stdout + r.stderr).splitlines() if 'ERROR' in l and 'leaked' not in l and 'still in use' not in l]
if not os.path.exists(exe):
    print('\n'.join(errors[-30:]))
    sys.exit('EXPORT BASARISIZ')
print(f'OK -> {exe}  (v{version}, {os.path.getsize(exe) // 1048576} MB)')
if mode == 'main':   # beceri deneme exe'si: aynı oyun, adı SKILLTEST içerince menüsüz deneme modu açılır
    import shutil
    sk = os.path.join(ROOT, 'SkillTest')
    os.makedirs(sk, exist_ok=True)
    shutil.copy2(exe, os.path.join(sk, 'ShinobiYolu_SKILLTEST.exe'))
    print('OK -> SkillTest\ShinobiYolu_SKILLTEST.exe')
