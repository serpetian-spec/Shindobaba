"""Sketchfab'den seçili fan modellerini indirir (token: .sketchfab_token, git'e girmez).
Kullanım: python tools/sketchfab_dl.py
Her model godot/assets/sketchfab/<ad>/ altına glb (yoksa gltf zip) olarak iner."""
import json, os, sys, time, urllib.request, urllib.error, zipfile, io

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOKEN = open(os.path.join(ROOT, '.sketchfab_token'), encoding='utf8').read().strip()
OUT = os.path.join(ROOT, 'godot', 'assets', 'sketchfab')

# ad -> uid (oyunlardan sökülmüş olanlar hariç)
MODELS = {}
MODELS0 = {
    'kurama_calfan': '9ce3de6fd9504ca18d9b70e7309b31d8',
    'kurama_jdavid': '92ad0aadbca04969b9a2c0b24a5c1815',
    'kurama_kyubi': '5ab8141d05bf47aab604938be8c61ad8',
    'shukaku': '7e3b464111194543925b64e85f6cc1b9',
    'gyuki': 'f4d7e838a3dc4684a893b1cce5e76a10',
    'sea_slug': '0bf40ea6694f4abcb27cbf81bc8a36ea',
    'battle_toad': 'c0d9b186cdb942b29894a9340f1ca337',
    'naruto_frog': '317895774b2240fc8892c2c3082ad165',
    'toad_rogue': '1efa73c1646c49ce95b311e8c7f2d845',
    'froggy_knight': '60c7949612f6467da418a7b7a929ef24',
    'snake_anim': '83c4290cd4b648fd942d4bbc2280a3f6',
    'aoda': '05efd966a8cf49e7ae1bfbc8f556ed46',
    'slug_arion': '1777b0ce4ecb420193fe12f2cd597ebe',
    'shepherd': '18d8fbe184c5448283762893b6ea9752',
    'pakkun': 'e454a6b36cec43ceae15e5ccd467109e',
    'eagle': '30203bf39e5145f19c79e83c550139d3',
    'monkey_king': 'aabe2e20e11741459332da1b99efdf93',
    'monkey_rigged': '0560ce7d141342bba89cdba69facd8a3',
    'crow': 'd5a9b0df4da3493688b63ce42c8a83e2',
    'crow_game': '7f41fdc16ea3442788355809271cc50d',
    'susanoo_skeleton': '7757909327f14a92a3a05ece05ed2784',
    'susanoo_perfect': '41e8fe2cab25423c966cc2ab2d909314',
    'kunai_explosive': '819165867a3041eeb984a42afa65055c',
    'shuriken_pack': '26a03f5679064edf92292e0bebac50b4',
    'big_shuriken': 'aa7068a1de2541488182be52fbe0f592',
    'katana': '760dcf6835b148828cda4927cf70ab0d',
    'executioner_blade': '967a9db875cb4ba493b5e2d4dd2e8362',
    'samehada': '5bacda6b788c44f9a1e98b6fc0e9c254',
    'jp_town_street': '200fc33b8a2b4da98e71590feeb255a8',
    'jp_temple': 'a210febbec4f454dbd0df1d142be06bc',
    'shirakawago_house': 'f94da738aefc4674ab2062df5c01cd43',
    'jp_town': '6f58f3bdef404321b8850aab870e110f',
    'rocks_stylized': '7c60b4d1b8ab4187965f30c5e0212fc0',
    'rocks_70': 'bf0051544c9c41f998c154c546b09669',
    'sandstone_pillar': 'a09b1eb506ab4e198edc30c87848e843',
    'rock_tower': '9021389231044fe6a289c9e2f3e82282',
}


# ek modeller (arama sonucu): tools/sketchfab_extra.json
_extra = os.path.join(ROOT, 'tools', 'sketchfab_extra.json')
MODELS.update(MODELS0)
if os.path.exists(_extra):
    MODELS.update(json.load(open(_extra, encoding='utf8')))


def get(url, auth=True):
    for attempt in range(8):
        req = urllib.request.Request(url, headers={'Authorization': 'Token ' + TOKEN} if auth else {})
        try:
            return urllib.request.urlopen(req, timeout=180).read()
        except urllib.error.HTTPError as e:
            if e.code == 429:
                wait = int(e.headers.get('Retry-After', 0) or 0) or 60 * (attempt + 1)
                print('  bekleniyor', wait, 's', flush=True)
                time.sleep(wait)
                continue
            raise
        except (urllib.error.URLError, ConnectionError, TimeoutError) as e:
            print('  bağlantı hatası, tekrar', e, flush=True)
            time.sleep(15 * (attempt + 1))
    raise RuntimeError('indirilemedi')


def main():
    only = sys.argv[1:]
    os.makedirs(OUT, exist_ok=True)
    for name, uid in MODELS.items():
        if only and name not in only:
            continue
        dst = os.path.join(OUT, name)
        if os.path.isdir(dst) and os.listdir(dst):
            print('var', name); continue
        try:
            info = json.loads(get('https://api.sketchfab.com/v3/models/%s/download' % uid))
        except Exception as e:
            print('HATA', name, e); continue
        os.makedirs(dst, exist_ok=True)
        time.sleep(8)
        try:
            _save(info, dst, name)
        except Exception as e:
            print('HATA', name, e)


def _save(info, dst, name):
        if 'glb' in info:
            data = get(info['glb']['url'], auth=False)
            open(os.path.join(dst, name + '.glb'), 'wb').write(data)
            print('glb', name, len(data) // 1024, 'KB')
        elif 'gltf' in info:
            data = get(info['gltf']['url'], auth=False)
            zipfile.ZipFile(io.BytesIO(data)).extractall(dst)
            print('gltf', name, len(data) // 1024, 'KB')
        else:
            print('format yok', name, list(info.keys()))


if __name__ == '__main__':
    main()
