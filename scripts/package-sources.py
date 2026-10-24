"""Move corresponding sources out of the runtime into a separate release asset."""
from pathlib import Path
import hashlib
import shutil
import zipfile

def separate_sources(root, output, version, platform):
    root, output = Path(root), Path(output)
    source_root = output / ('ReyondBroom-Sources-' + platform)
    source_root.mkdir()
    candidates = [root / 'sources']
    candidates += list((root / 'tools').rglob('library-sources'))
    candidates += [p for p in (root / 'tools').rglob('*')
                   if p.is_file() and 'source' in p.name.lower()
                   and p.name.endswith(('.zip', '.tar.gz', '.tar.xz', '.tar.bz2'))]
    for path in candidates:
        if not path.exists():
            continue
        relative = path.relative_to(root)
        target = source_root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(path), str(target))
    archive = output / f'ReyondBroom-{version}-{platform}-Sources.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as package:
        for path in sorted(source_root.rglob('*')):
            if path.is_file():
                package.write(path, path.relative_to(source_root))
    archive.with_suffix('.zip.sha256').write_text(
        hashlib.sha256(archive.read_bytes()).hexdigest() + '  ' + archive.name + '\n')
    (root / 'SOURCE-CODE.txt').write_text(
        'Corresponding sources, patches and build scripts are distributed separately.\n'
        f'Download {archive.name} from the same release as this binary.\n'
        'https://github.com/reyond9079/ReyondBroom/releases\n'
        'Publish the source archive alongside the binary archive. Preserve all licenses.\n',
        encoding='utf-8')
    return archive
