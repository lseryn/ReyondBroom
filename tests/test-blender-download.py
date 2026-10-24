# SPDX-License-Identifier: GPL-2.0-or-later
import hashlib
import importlib.util
import io
from pathlib import Path
import tarfile
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('installer', Path(__file__).parents[1] / 'runtime/download-blender.py')
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)

class InstallerTests(unittest.TestCase):
    def fixture(self, folder, unsafe=False):
        archive = folder / 'fixture.tar.xz'
        with tarfile.open(archive, 'w:xz') as out:
            entry = tarfile.TarInfo(installer.FOLDER + '/blender')
            entry.size = 5
            entry.mode = 0o755
            out.addfile(entry, io.BytesIO(b'test!'))
            if unsafe:
                entry = tarfile.TarInfo(installer.FOLDER + '/../../escape')
                entry.size = 3
                out.addfile(entry, io.BytesIO(b'bad'))
        installer.URL = archive.as_uri()
        installer.SHA256 = hashlib.sha256(archive.read_bytes()).hexdigest()

    def test_cache_works_without_network(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            self.fixture(root)
            installer.install(root / 'cache')
            installer.URL = 'file:///missing/offline.tar.xz'
            installer.install(root / 'cache')
            self.assertTrue((root / 'cache' / installer.FOLDER / 'ftebroom-ready.txt').is_file())

    def test_checksum_failure_can_retry(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            self.fixture(root)
            checksum = installer.SHA256
            installer.SHA256 = '0' * 64
            with self.assertRaisesRegex(ValueError, 'checksum'):
                installer.install(root / 'cache')
            self.assertFalse((root / 'cache' / installer.FOLDER).exists())
            self.assertFalse(list((root / 'cache').glob('install-*')))
            installer.SHA256 = checksum
            installer.install(root / 'cache')

    def test_path_escape_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            self.fixture(root, unsafe=True)
            with self.assertRaises(tarfile.FilterError):
                installer.install(root / 'cache')
            self.assertFalse((root / 'cache' / installer.FOLDER).exists())
            self.assertFalse((root / 'cache/escape').exists())

if __name__ == '__main__':
    unittest.main()
