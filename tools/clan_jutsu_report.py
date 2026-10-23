"""Klan başına jutsu sayısı: klan etiketli + klanın kekkei genkai doğası (kg:x) + klan gözü (eye:x).
Kullanım: python tools/clan_jutsu_report.py [eski_jutsu.json]"""
import json
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')


def counts(jpath):
    clans = json.load(open(os.path.join(ROOT, 'godot', 'data', 'clans.json'), encoding='utf8'))
    js = [v for k, v in json.load(open(jpath, encoding='utf8')).items() if not k.startswith('_')]
    out = {}
    for cid, c in clans.items():
        nat = c.get('kg_natures', [])
        eye = c.get('dojutsu', '')
        tagged = [j for j in js if j.get('clan') == cid]
        kg = [j for j in js if any(str(j.get('learn', '')) == 'kg:' + n for n in nat)]
        ey = [j for j in js if eye and str(j.get('learn', '')) == 'eye:' + eye]
        out[cid] = (len(tagged), len(kg), len(ey))
    return out


now = counts(os.path.join(ROOT, 'godot', 'data', 'jutsu.json'))
old = counts(sys.argv[1]) if len(sys.argv) > 1 else {}
sys.stdout.reconfigure(encoding='utf8')
print('%-10s %-14s %-14s' % ('klan', 'önce (k/kg/göz)', 'sonra (k/kg/göz)'))
for cid, v in now.items():
    print('%-10s %-14s %-14s' % (cid, '/'.join(map(str, old.get(cid, ('-',) * 3))), '/'.join(map(str, v))))
