import runpy
from pathlib import Path
import tempfile
import zipfile

split=runpy.run_path(str(Path(__file__).resolve().parents[1]/'scripts/package-sources.py'))['separate_sources']
with tempfile.TemporaryDirectory() as temp:
    output=Path(temp);root=output/'runtime';root.mkdir()
    files={'sources/fteqw-source.zip':'fte','sources/ftebroom/native/test.cpp':'code',
           'tools/q3map2/compiler-source.zip':'compiler','tools/q3map2/library-sources/dependency.tar.xz':'dep',
           'tools/audio/ffmpeg-source.tar.xz':'audio','tools/audio/LICENSE.txt':'license',
           'tools/q3map2/q3map2.exe':'binary','ftebroom/maps/start.map':'map'}
    for name,data in files.items():
        p=root/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(data)
    archive=split(root,output,'test','Windows-x64')
    with zipfile.ZipFile(archive) as z:
        assert z.read('sources/fteqw-source.zip')==b'fte'
        assert z.read('tools/q3map2/library-sources/dependency.tar.xz')==b'dep'
        assert z.read('sources/ftebroom/native/test.cpp')==b'code'
    assert not (root/'sources').exists()
    assert not (root/'tools/q3map2/compiler-source.zip').exists()
    assert (root/'tools/audio/LICENSE.txt').read_text()=='license'
    assert (root/'tools/q3map2/q3map2.exe').read_text()=='binary'
    assert (root/'ftebroom/maps/start.map').read_text()=='map'
print('PASS: sources separated; binaries, runtime and licenses preserved')
