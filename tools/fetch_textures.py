"""Poly Haven (CC0) dokularını indirip anime tarzı detay dokularına çevirir -> godot/assets/tex/*.png
Detay dokusu: gri tonlu, ortalama 0.5, düşük kontrast (renk binanın kendi renginden gelir; doku yalnız yüzey dokusu katar).
  python tools/fetch_textures.py
"""
import io
import json
import os
import subprocess

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'godot', 'assets', 'tex')
UA = 'ShinobiYoluDev/1.0'
# ad -> (Poly Haven varlığı, çıktı boyutu, kontrast, posterize kademesi: cel görünüm için 0 = yok)
SET = {
    'plaster': ('clay_plaster', 512, 0.55, 0),
    'wood': ('brown_planks_03', 512, 0.7, 0),
    'roof': ('clay_roof_tiles_02', 512, 0.9, 0),
    'cobble': ('cobblestone_floor_04', 512, 0.85, 0),
    'stone': ('cobblestone_large_01', 512, 0.8, 0),
    'rock': ('cliff_side', 512, 0.9, 0),
    'sand': ('coast_sand_01', 512, 0.6, 0),
    'forest': ('forest_ground_04', 512, 0.7, 0),
    'dirt': ('dirt', 512, 0.6, 0),
    'bark': ('japanese_cedar_bark', 512, 0.9, 0),
    'grass': ('aerial_grass_rock', 512, 0.7, 0),
    'snow': ('snow_02', 512, 0.75, 0),
}


def curl(url):
    return subprocess.run(['curl', '-s', '-L', '-A', UA, url], capture_output=True, timeout=120).stdout


def main():
    os.makedirs(OUT, exist_ok=True)
    lic = []
    for name, (asset, size, contrast, post) in SET.items():
        files = json.loads(curl('https://api.polyhaven.com/files/' + asset))
        url = files['Diffuse']['1k']['jpg']['url']
        im = Image.open(io.BytesIO(curl(url))).convert('L').resize((size, size), Image.LANCZOS)
        im = im.filter(ImageFilter.GaussianBlur(0.6))   # boyalı (painterly) yumuşaklık
        a = np.asarray(im, dtype=np.float32) / 255.0
        a = (a - a.mean()) / (a.std() + 1e-5) * 0.18 * contrast + 0.5
        if post:
            a = np.round(a * post) / post
        Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).save(os.path.join(OUT, name + '.png'))
        lic.append('%s.png <- polyhaven.com/a/%s (CC0)' % (name, asset))
        print('OK', name, asset)
    open(os.path.join(OUT, 'LICENSE_CC0.txt'), 'w', encoding='utf-8').write('Poly Haven dokuları, CC0 (kamu malı)\n' + '\n'.join(lic) + '\n')


if __name__ == '__main__':
    main()
