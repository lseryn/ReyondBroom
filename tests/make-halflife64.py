# SPDX-License-Identifier: GPL-2.0-or-later
"""Small self-authored Half-Life v10 model: translated bone, one textured triangle."""
import struct
from pathlib import Path
import sys

data = bytearray(244)


def lump(value):
    while len(data) % 4:
        data.append(0)
    at = len(data)
    data.extend(value)
    return at


bone = lump(struct.pack('<32sii6i12f', b'root', -1, 0, *([-1] * 6), 100, -27, 12, 0, 0, 0, 1, 1, 1, 1, 1, 1))
anim = lump(struct.pack('<6HBB2h', 12, 0, 0, 0, 0, 0, 2, 2, 0, 8))
group = lump(bytes(104))
seq = bytearray(176)
struct.pack_into('<32sf', seq, 0, b'move', 24)
struct.pack_into('<i', seq, 56, 2)
struct.pack_into('<ii', seq, 120, 1, anim)
sequence = lump(seq)
points = lump(struct.pack('<9f', 0, 0, 0, 16, 0, 0, 0, 16, 0))
bone_indices = lump(bytes(3))
normals = lump(struct.pack('<3f', 0, 0, 1))
order = lump(struct.pack('<h12hh', 3, 0, 0, 0, 0, 1, 0, 15, 0, 2, 0, 0, 15, 0))
mesh = lump(struct.pack('<5i', 1, order, 0, 0, 0))
sub = bytearray(112)
struct.pack_into('<32s', sub, 0, b'body')
struct.pack_into('<8i', sub, 72, 1, mesh, 3, bone_indices, points, 1, bone_indices, normals)
submodel = lump(sub)
body = lump(struct.pack('<64s3i', b'body', 1, 1, submodel))
palette = bytearray(768)
palette[3:6] = bytes((255, 0, 0))
pixels = lump(bytes([1]) * 256 + palette)
texture = lump(struct.pack('<64s4i', b'red.bmp', 0, 16, 16, pixels))
skinrefs = lump(struct.pack('<H', 0))
struct.pack_into('<4si64si', data, 0, b'IDST', 10, b'fixture', len(data))
struct.pack_into('<2i', data, 140, 1, bone)
struct.pack_into('<4i', data, 164, 1, sequence, 1, group)
struct.pack_into('<8i', data, 180, 1, texture, 0, 1, 1, skinrefs, 1, body)
Path(sys.argv[1]).write_bytes(data)
