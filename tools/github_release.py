## GitHub release: python tools/github_release.py "notlar"
## VERSION'daki sürümle release açar ve ShinobiYolu_vX.Y.Z.zip'i yükler (kimlik: git credential / Git Credential Manager).
import subprocess, json, urllib.request, urllib.error, sys, os

os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
out = subprocess.run(['git', 'credential', 'fill'], input='protocol=https\nhost=github.com\n\n', capture_output=True, text=True).stdout
tok = dict(l.split('=', 1) for l in out.splitlines() if '=' in l).get('password')
if not tok:
    sys.exit('GitHub kimliği yok (önce bir kez git push ile giriş yap)')
H = {'Authorization': 'token ' + tok, 'Accept': 'application/vnd.github+json'}
repo = 'serpetian-spec/Shindobaba'
tag = 'v' + open('VERSION').read().strip()
zipn = 'ShinobiYolu_%s.zip' % tag
notes = sys.argv[1] if len(sys.argv) > 1 else ''
body = {'tag_name': tag, 'target_commitish': 'main', 'name': 'Shinobi Yolu ' + tag,
        'body': notes + '\n\nİndir: ' + zipn + ' - zipi aç, ShinobiYolu klasöründeki ShinobiYolu.exe yi çalıştır.'}
req = urllib.request.Request('https://api.github.com/repos/%s/releases' % repo, data=json.dumps(body).encode(), headers=H, method='POST')
try:
    r = json.load(urllib.request.urlopen(req))
except urllib.error.HTTPError as e:
    sys.exit('release hata %s %s' % (e.code, e.read()[:300]))
up = r['upload_url'].split('{')[0] + '?name=' + zipn
data = open(zipn, 'rb').read()
req = urllib.request.Request(up, data=data, headers=dict(H, **{'Content-Type': 'application/zip'}), method='POST')
a = json.load(urllib.request.urlopen(req, timeout=3600))
print('OK', r['html_url'], a['state'], a['size'])
