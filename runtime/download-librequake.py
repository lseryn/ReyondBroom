#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Download the pinned LibreQuake release into an editor-owned directory."""
import argparse
import hashlib
import os
from pathlib import Path, PurePosixPath
import shutil
import tempfile
import urllib.request
import zipfile

URL = 'https://github.com/lavenderdotpet/LibreQuake/releases/download/v0.09-beta/mod_lite.zip'
SHA256 = 'dce87bc769ffcd342d297aaf260dc651458d4f00bf1f332a6600ba4c52457193'

def install_package(destination, url, checksum, folder, required, marker):
    destination = Path(destination).resolve()
    destination.mkdir(parents=True, exist_ok=True)
    if (destination / marker).is_file() and (destination / required).is_file():
        return
    def progress(done, total, phase):
        temp = destination / 'progress.tmp'
        temp.write_text(f'{done} {total} {phase}', encoding='utf-8')
        os.replace(temp, destination / 'progress.txt')
    with tempfile.TemporaryDirectory(prefix='install-', dir=destination) as stage:
        stage = Path(stage)
        archive = stage / 'download.zip'
        request = urllib.request.Request(url, headers={'User-Agent': 'FTEBroom'})
        digest = hashlib.sha256()
        done = 0
        progress(0, 0, 'Connecting')
        with urllib.request.urlopen(request, timeout=30) as response, archive.open('wb') as output:
            total = max(0, int(response.headers.get('Content-Length', 0)))
            while data := response.read(256 * 1024):
                done += len(data)
                if done > 512 * 1024 * 1024:
                    raise ValueError('Download exceeds 512 MiB')
                output.write(data)
                digest.update(data)
                progress(done, total, 'Downloading')
        if digest.hexdigest() != checksum:
            raise ValueError('LibreQuake archive checksum mismatch')
        progress(done, done, 'Extracting')
        with zipfile.ZipFile(archive) as source:
            total = 0
            for entry in source.infolist():
                name = PurePosixPath(entry.filename)
                if name.is_absolute() or '..' in name.parts or '\\' in entry.filename or ':' in entry.filename:
                    raise ValueError('Unsafe archive path')
                if (entry.external_attr >> 16) & 0o170000 == 0o120000:
                    raise ValueError('Archive symlinks are unsupported')
                total += entry.file_size
                if total > 1024 * 1024 * 1024:
                    raise ValueError('Extracted archive exceeds 1 GiB')
                source.extract(entry, stage)
        if not (stage / required).is_file():
            raise ValueError('LibreQuake PAK is missing')
        target = destination / folder
        if not target.exists():
            shutil.move(str(stage / folder), target)
        if not (destination / required).is_file():
            raise ValueError('Existing installation is incomplete; choose a new download directory')
        if folder == 'mod_lite':
            (target / 'id1').mkdir(exist_ok=True)
        (destination / marker).write_text('v0.09-beta', encoding='utf-8')
        progress(done, done, 'Ready')

def install(destination):
    install_package(destination, URL, SHA256, 'mod_lite', 'mod_lite/lq1/pak0.pak', 'ready.txt')
    install_package(destination,
        'https://github.com/lavenderdotpet/LibreQuake/releases/download/v0.09-beta/dev.zip',
        '8b6cd467a73976e8ed6ee52eecc0cafc7d3a0c289058b1ccebcf05583a88f288',
        'dev', 'dev/texture-wads/lq_dev.wad', 'wads-ready.txt')
    destination = Path(destination).resolve()
    target = destination / 'mod_lite/lq1/texture-wads'
    target.mkdir(parents=True, exist_ok=True)
    for wad in (destination / 'dev/texture-wads').glob('*.wad'):
        if not (target / wad.name).exists():
            shutil.copy2(wad, target / wad.name)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--destination', required=True)
    args = parser.parse_args()
    try:
        install(args.destination)
    except Exception as error:
        path = Path(args.destination)
        path.mkdir(parents=True, exist_ok=True)
        (path / 'error.txt').write_text(str(error), encoding='utf-8')
        raise SystemExit(1)
