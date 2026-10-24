"""Fetch the pinned compiler source into the ignored dependency cache."""
from pathlib import Path
import hashlib
import urllib.request

target = Path(__file__).resolve().parents[1] / 'tools/q3map2/netradiant-custom-20260114-source.zip'
digest = '8abeb91333d6e592a41d6f31c675b58aff4f345da396670654233a65a086e100'
if not target.is_file() or hashlib.sha256(target.read_bytes()).hexdigest() != digest:
    partial = target.with_suffix('.zip.part')
    urllib.request.urlretrieve('https://github.com/Garux/netradiant-custom/archive/refs/tags/20260114.zip', partial)
    if hashlib.sha256(partial.read_bytes()).hexdigest() != digest:
        partial.unlink()
        raise RuntimeError('Pinned q3map2 source checksum mismatch')
    partial.replace(target)
print(target)
