from pathlib import Path
import tempfile,zipfile,subprocess,json,hashlib
root=Path(tempfile.mkdtemp(prefix='ReyondBroom-update-test-'))
(root/'ftebroom').mkdir();(root/'fteqw64.exe').write_bytes(b'old engine');(root/'ftebroom/appearance.cfg').write_text('4 1 1');(root/'ftebroom/maps').mkdir();(root/'ftebroom/maps/mine.map').write_text('user map');(root/'ftebroom-game-profile.txt').write_text('my mod path')
(root/'ftebroom/custom.wad').write_bytes(b'user-added texture')
(root/'ftebroom/defaults.cfg').write_bytes(b'old defaults')
(root/'distribution-manifest.json').write_text(json.dumps({
 'ftebroom/custom.wad':hashlib.sha256(b'original wad').hexdigest(),
 'ftebroom/defaults.cfg':hashlib.sha256(b'old defaults').hexdigest()}))
updates=root/'updates';updates.mkdir()
for name in ('stage-old','backup-old'):
 (updates/name).mkdir();(updates/name/'cache').write_text('old')
(updates/'ReyondBroom-0.5.0-alpha.20-Windows-x64.zip.part').write_text('partial')
(updates/'notes.txt').write_text('keep')
package=root/'fixture.zip'
with zipfile.ZipFile(package,'w') as z:
 for name,data in [('fteqw64.exe',b'new engine'),('fteplug_ftebroom_x64.dll',b'new plugin'),('ftebroom/appearance.cfg',b'0 0 0'),('ftebroom-game-profile.txt',b'wrong'),('ftebroom/new.txt',b'new file')]:z.writestr('ReyondBroom-Windows-x64/'+name,data)
 z.writestr('ReyondBroom-Windows-x64/ftebroom/custom.wad',b'new stock wad')
 z.writestr('ReyondBroom-Windows-x64/ftebroom/defaults.cfg',b'new defaults')
r=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File','runtime/update-ftebroom.ps1','-Root',str(root),'-CurrentVersion','0.5.0-alpha.29','-LocalPackage',str(package)],capture_output=True,text=True)
print(r.returncode,r.stdout,r.stderr);print((root/'updates/status.txt').read_text())
assert r.returncode==0
assert not (updates/'stage-old').exists() and not (updates/'backup-old').exists()
assert not (updates/'ReyondBroom-0.5.0-alpha.20-Windows-x64.zip.part').exists()
assert (updates/'notes.txt').read_text()=='keep' and package.exists()
assert len(list(updates.glob('backup-*')))==1 and not list(updates.glob('stage-*'))
assert (root/'fteqw64.exe').read_bytes()==b'new engine'
assert (root/'ftebroom/appearance.cfg').read_text()=='4 1 1'
assert (root/'ftebroom-game-profile.txt').read_text()=='my mod path'
assert (root/'ftebroom/maps/mine.map').read_text()=='user map'
assert (root/'ftebroom/custom.wad').read_bytes()==b'user-added texture'
assert (root/'ftebroom/defaults.cfg').read_bytes()==b'new defaults'
assert list((root/'updates').glob('backup-*/fteqw64.exe'))[0].read_bytes()==b'old engine'
print('PASS: update installed; appearance, profile, user map and rollback preserved',root)
# Reject traversal before touching the live installation.
malicious=root/'unsafe.zip'
with zipfile.ZipFile(malicious,'w') as z:z.writestr('ReyondBroom-Windows-x64/../escape.txt','bad')
r=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File','runtime/update-ftebroom.ps1','-Root',str(root),'-CurrentVersion','0.5.0-alpha.29','-LocalPackage',str(malicious)],capture_output=True,text=True)
assert r.returncode==1 and not (root/'escape.txt').exists()
assert (root/'fteqw64.exe').read_bytes()==b'new engine'
# Force a failure after normal files have been staged, then verify rollback.
(root/'blocked').write_text('keep')
failed=root/'failed.zip'
with zipfile.ZipFile(failed,'w') as z:
 for name,data in [('fteqw64.exe','should roll back'),('fteplug_ftebroom_x64.dll','plugin'),('blocked/child.txt','cannot install')]:z.writestr('ReyondBroom-Windows-x64/'+name,data)
r=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File','runtime/update-ftebroom.ps1','-Root',str(root),'-CurrentVersion','0.5.0-alpha.29','-LocalPackage',str(failed)],capture_output=True,text=True)
assert r.returncode==1 and (root/'fteqw64.exe').read_bytes()==b'new engine'
assert (root/'blocked').read_text()=='keep'
print('PASS: traversal rejection and failed-install rollback')
