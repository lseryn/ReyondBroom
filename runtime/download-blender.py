#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Install the pinned portable conversion runtime, without modifying the system."""
import argparse
import hashlib
import os
from pathlib import Path
import shutil
import tarfile
import tempfile
import urllib.request

VERSION = '5.0.0'
FOLDER = 'blender-5.0.0-linux-x64'
URL = 'https://download.blender.org/release/Blender5.0/' + FOLDER + '.tar.xz'
SHA256 = '9de96e81432afba9c0a715c7233f1eff616705b75226dc5d0fa2708ddfb0e525'

def install(destination):
    destination = Path(destination).resolve()
    destination.mkdir(parents=True, exist_ok=True)
    target = destination / FOLDER
    if (target / 'ftebroom-ready.txt').is_file() and (target / 'blender').is_file():
        return
    def progress(done, total, phase):
        (destination / 'progress.txt').write_text(f'{done} {total} {phase}', encoding='utf-8')
    with tempfile.TemporaryDirectory(prefix='install-', dir=destination) as stage:
        stage = Path(stage)
        archive = stage / 'download.tar.xz'
        digest = hashlib.sha256()
        done = 0
        progress(0, 0, 'Connecting to blender.org')
        request = urllib.request.Request(URL, headers={'User-Agent': 'ReyondBroom'})
        with urllib.request.urlopen(request, timeout=45) as response, archive.open('wb') as output:
            total = int(response.headers.get('Content-Length', 0))
            while data := response.read(1024 * 1024):
                done += len(data)
                if done > 1024 ** 3:
                    raise ValueError('Blender download exceeds 1 GiB')
                output.write(data)
                digest.update(data)
                progress(done, total, 'Downloading Blender 5.0.0')
        progress(done, done, 'Verifying download')
        if digest.hexdigest() != SHA256:
            raise ValueError('Blender checksum mismatch; retry the download')
        with tarfile.open(archive) as source:
            entries = source.getmembers()
            if len(entries) > 100000 or sum(e.size for e in entries) > 4 * 1024 ** 3:
                raise ValueError('Blender archive exceeds extraction limits')
            for i, entry in enumerate(entries):
                if not entry.name.startswith(FOLDER + '/') and entry.name != FOLDER:
                    raise ValueError('Unexpected Blender archive root')
                source.extract(entry, stage, filter='data')
                if i % 100 == 0:
                    progress(i, len(entries), 'Extracting Blender')
        if not (stage / FOLDER / 'blender').is_file():
            raise ValueError('Blender executable is missing')
        (stage / FOLDER / 'ftebroom-ready.txt').write_text(SHA256)
        if target.exists():
            if (target / 'ftebroom-ready.txt').is_file():
                return
            raise ValueError('Incomplete Blender installation; remove only the managed Blender folder and retry')
        shutil.move(str(stage / FOLDER), target)
        progress(1, 1, 'Blender ready')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--destination', required=True, type=Path)
    args = parser.parse_args()
    try:
        install(args.destination)
        (args.destination / 'success.txt').write_text(VERSION)
    except Exception as error:
        args.destination.mkdir(parents=True, exist_ok=True)
        (args.destination / 'error.txt').write_text(str(error), encoding='utf-8')
        raise SystemExit(1)
