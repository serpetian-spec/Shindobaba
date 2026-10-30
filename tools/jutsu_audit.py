"""Jutsu görsel denetimi araçları.
  python tools/jutsu_audit.py sheets            -> _tmp/audit_sheets/sheet_NN.png (16 jutsu/sayfa, iki an)
  python tools/jutsu_audit.py ref id1 id2 ...   -> _tmp/jref/<id>.png (naruto.fandom ana görseli) + _tmp/jref/cmp_<id>.png (REFERANS | oyun a | oyun b)
"""
import io
import json
import os
import sys
import urllib.parse
import urllib.request

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUD = os.path.join(ROOT, '_tmp', 'audit')
SHEETS = os.path.join(ROOT, '_tmp', 'audit_sheets')
REF = os.path.join(ROOT, '_tmp', 'jref')
API = "https://naruto.fandom.com/api.php?"
J = json.load(open(os.path.join(ROOT, 'godot', 'data', 'jutsu.json'), encoding='utf-8'))


def ids_done():
    s = set()
    for f in os.listdir(AUD):
        if f.endswith('__a.png'):
            s.add(f[:-7])
    return sorted(s)


def sheets(ids=None):
    os.makedirs(SHEETS, exist_ok=True)
    ids = ids or ids_done()
    tw, th = 300, 169
    per = 16
    for si in range(0, len(ids), per):
        part = ids[si:si + per]
        W = Image.new('RGB', (tw * 4, th * 8), (20, 20, 24))
        d = ImageDraw.Draw(W)
        for i, k in enumerate(part):
            col, row = i // 8, i % 8
            x0, y0 = col * tw * 2, row * th
            for j, s in enumerate('ab'):
                p = os.path.join(AUD, '%s__%s.png' % (k, s))
                if os.path.exists(p):
                    W.paste(Image.open(p).resize((tw, th)), (x0 + j * tw, y0))
            nm = J.get(k, {}).get('name', k) if isinstance(J.get(k), dict) else k
            d.rectangle([x0, y0, x0 + tw * 2, y0 + 14], fill=(0, 0, 0))
            d.text((x0 + 3, y0 + 1), '%d %s | %s' % (si + i, k, nm[:40]), fill=(255, 230, 80))
        out = os.path.join(SHEETS, 'sheet_%02d.png' % (si // per))
        W.save(out)
    print('sayfa', (len(ids) + per - 1) // per)


UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"


def curl(url):
    import subprocess
    return subprocess.run(['curl', '-s', '-L', '-A', UA, url], capture_output=True, timeout=30).stdout


def q(params):
    return json.loads(curl(API + urllib.parse.urlencode(params)))


def ref(ids):
    os.makedirs(REF, exist_ok=True)
    for k in ids:
        j = J.get(k, {})
        title = j.get('name_en') or j.get('name', k)
        try:
            d = q({"action": "query", "titles": title, "prop": "pageimages", "format": "json", "pithumbsize": 900, "redirects": 1})
            url = None
            for p in d["query"]["pages"].values():
                url = (p.get("thumbnail") or {}).get("source")
            if not url:
                s = q({"action": "query", "list": "search", "srsearch": title, "srlimit": 1, "format": "json"})
                hits = s["query"]["search"]
                if hits:
                    d = q({"action": "query", "titles": hits[0]["title"], "prop": "pageimages", "format": "json", "pithumbsize": 900, "redirects": 1})
                    for p in d["query"]["pages"].values():
                        url = (p.get("thumbnail") or {}).get("source")
            if not url:
                print('YOK', k, title)
                continue
            im = Image.open(io.BytesIO(curl(url))).convert('RGB')
            im.thumbnail((640, 360))
            im.save(os.path.join(REF, k + '.png'))
            W = Image.new('RGB', (640 + 480, 360), (20, 20, 24))
            W.paste(im, (0, 0))
            for j2, s in enumerate('ab'):
                p = os.path.join(AUD, '%s__%s.png' % (k, s))
                if os.path.exists(p):
                    W.paste(Image.open(p).resize((480, 180)), (640, j2 * 180))
            ImageDraw.Draw(W).text((4, 4), '%s (%s)' % (k, title), fill=(255, 230, 80))
            W.save(os.path.join(REF, 'cmp_%s.png' % k))
            print('OK', k, title)
        except Exception as e:
            print('HATA', k, e)


if __name__ == '__main__':
    if sys.argv[1] == 'sheets':
        sheets(sys.argv[2:] or None)
    elif sys.argv[1] == 'ref':
        ref(sys.argv[2:])


def rank(out_n=0):
    """boş kareye göre değişen piksel oranı (ekranda ne kadar iz bıraktı) -> _tmp/audit_rank.txt"""
    import numpy as np
    rows = []
    for k in ids_done():
        p0 = os.path.join(AUD, k + '__0.png')
        if not os.path.exists(p0):
            continue
        b = np.asarray(Image.open(p0).convert('RGB'), dtype=np.int16)
        sc = []
        for s in 'ab':
            p = os.path.join(AUD, '%s__%s.png' % (k, s))
            if os.path.exists(p):
                a = np.asarray(Image.open(p).convert('RGB'), dtype=np.int16)
                sc.append(float((np.abs(a - b).sum(axis=2) > 70).mean()))
        if sc:
            j = J.get(k, {}) if isinstance(J.get(k), dict) else {}
            rows.append((max(sc), k, j.get('canon_rank', ''), j.get('category', ''), j.get('element', '')))
    rows.sort()
    with open(os.path.join(ROOT, '_tmp', 'audit_rank.txt'), 'w', encoding='utf-8') as f:
        for r in rows:
            f.write('%.4f\t%s\t%s\t%s\t%s\n' % r)
    print('sıralandı', len(rows))
    return [r[1] for r in rows]


if __name__ == '__main__' and sys.argv[1] == 'rank':
    ids = rank()
    n = int(sys.argv[2]) if len(sys.argv) > 2 else 64
    sheets(ids[:n])
