from pathlib import Path
import struct, sys, re
root = Path(sys.argv[1]); editor = root/'editor/ftebroom'
bsp = Path((editor/'wad32-result.txt').read_text(encoding='utf-8'))
data = bsp.read_bytes(); assert struct.unpack_from('<i', data)[0] == 29
snapshot = bsp.with_suffix('.map').read_text(encoding='utf-8')
wads = re.search(r'"wad"\s*"([^"]+)"', snapshot)[1].split(';')
assert wads and all(p.isascii() and p.startswith('_ftebroom-wads/') for p in wads)
source = (root/'Карты с пробелами/concrete_sh.wad').read_bytes()
assert any((bsp.parent/p).read_bytes() == source for p in wads)
_, count, directory = struct.unpack_from('<4sii', source)
at, length = struct.unpack_from('<ii', source, directory)
name = source[at:at+16].split(b'\0')[0]
w, h, mip = struct.unpack_from('<3I', source, at+16)
expected = source[at+mip:at+mip+w*h]
offset, length = struct.unpack_from('<ii', data, 20)
found = False
for i in range(struct.unpack_from('<i', data, offset)[0]):
    relative = struct.unpack_from('<i', data, offset+4+i*4)[0]
    if relative < 0: continue
    start = offset+relative
    if data[start:start+16].split(b'\0')[0] != name: continue
    bw, bh, bmip = struct.unpack_from('<3I', data, start+16)
    assert (bw, bh) == (w, h) and bmip > 0
    assert data[start+bmip:start+bmip+w*h] == expected
    found = True
assert found, 'The selected WAD texture is not embedded in the actual Build result'
print('PASS: real background Build embeds exact external WAD pixels; ASCII staged WAD paths')
