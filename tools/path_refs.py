"""Efsane Yolu jutsuları için Narutopedia referans görüntüsü indirir.

Kullanım: python -I tools/path_refs.py id1 id2 ...
Ad kaynağı: godot/data/jutsu.json (name_en > name) ya da legend_paths.gd EXTRA_JUTSU ("name" alanı, parantez öncesi).
Önce başlık doğrudan denenir (pageimages), olmazsa arama ile ilk sonuç. Çıktı: refs/auto/<id>.png ve refs/auto/_names.txt
"""
import json
import os
import re
import sys
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'refs', 'auto')
API = 'https://naruto.fandom.com/api.php'
UA = {'User-Agent': 'ShinobiRefBot/1.0'}


def get(url):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=20) as r:
        return r.read()


def pageimage(title):
    q = API + '?action=query&prop=pageimages&piprop=original&redirects=1&format=json&titles=' + urllib.parse.quote(title)
    d = json.loads(get(q))
    for p in d.get('query', {}).get('pages', {}).values():
        src = p.get('original', {}).get('source', '')
        if src:
            return p.get('title', title), src
    return None, ''


def search(term):
    q = API + '?action=query&list=search&srlimit=3&format=json&srsearch=' + urllib.parse.quote(term)
    d = json.loads(get(q))
    return [x['title'] for x in d.get('query', {}).get('search', [])]


def names():
    data = json.load(open(os.path.join(ROOT, 'godot', 'data', 'jutsu.json'), encoding='utf8'))
    if isinstance(data, list):
        data = {x['id']: x for x in data}
    src = open(os.path.join(ROOT, 'godot', 'scripts', 'core', 'legend_paths.gd'), encoding='utf8').read()
    extra = dict(re.findall(r'"(\w+)": \{"name": "([^"]+)"', src))
    return data, extra


def main(ids):
    os.makedirs(OUT, exist_ok=True)
    data, extra = names()
    log = []
    for jid in ids:
        j = data.get(jid, {})
        cands = []
        if j.get('name_en'):
            cands.append(j['name_en'])
        nm = j.get('name') or extra.get(jid, '')
        if nm:
            cands.append(nm.split(' (')[0])
        got = ('', '')
        for c in cands:
            t, s = pageimage(c)
            if s:
                got = (t, s)
                break
        if not got[1]:
            for c in cands:
                for t in search(c):
                    t2, s = pageimage(t)
                    if s:
                        got = (t2, s)
                        break
                if got[1]:
                    break
        if got[1]:
            with open(os.path.join(OUT, jid + '.png'), 'wb') as f:
                f.write(get(got[1]))
        log.append('%s\t%s\t%s' % (jid, got[0] or '-', ' | '.join(cands)))
        print(log[-1])
    with open(os.path.join(OUT, '_names.txt'), 'a', encoding='utf8') as f:
        f.write('\n'.join(log) + '\n')


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    main(sys.argv[1:])
