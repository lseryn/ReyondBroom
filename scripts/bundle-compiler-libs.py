"""Bundle compiler-only shared libraries without changing the engine's loader path."""
from pathlib import Path
import json, re, shutil, subprocess

def bundle_compiler(binary: Path, source_cache: Path):
    output = subprocess.check_output(['ldd', str(binary)], text=True)
    if 'not found' in output:
        raise RuntimeError(output)
    folder = binary.parent / 'lib'
    folder.mkdir(exist_ok=True)
    notices = binary.parent / 'library-licenses'
    notices.mkdir(exist_ok=True)
    packages = set()
    versions = {}
    for name, path in re.findall(r'^\s*(\S+) => (/\S+)', output, re.M):
        if name in ('libc.so.6', 'libm.so.6', 'libstdc++.so.6', 'libgcc_s.so.1'):
            continue
        shutil.copy2(path, folder / name)
        query = subprocess.check_output(['dpkg-query', '-S', path.replace('/lib/', '/usr/lib/', 1)], text=True)
        package = query.split(': ')[0]
        packages.add(package)
        metadata = subprocess.check_output(['dpkg-query', '-W', '-f', '${source:Package} ${source:Version}', package], text=True).split()
        versions[package] = metadata
        copyright = Path('/usr/share/doc') / package.split(':')[0] / 'copyright'
        if copyright.exists():
            shutil.copy2(copyright, notices / (package.replace(':', '-') + '.txt'))
    (notices / 'packages.txt').write_text('\n'.join(sorted(packages)) + '\n')
    (notices / 'source-versions.json').write_text(json.dumps(versions, indent=2))
    source_cache.mkdir(parents=True, exist_ok=True)
    for source, version in sorted(set(map(tuple, versions.values()))):
        dsc = source_cache / f'{source}_{version.split(":")[-1]}.dsc'
        if not dsc.is_file():
            subprocess.run(['apt-get', 'source', '--download-only', f'{source}={version}'], cwd=source_cache, check=True)
    real = binary.with_name(binary.name + '.bin')
    binary.rename(real)
    binary.write_text('#!/bin/sh\nset -eu\ndir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)\n'
                      'export LD_LIBRARY_PATH="$dir/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"\n'
                      f'exec "$dir/{real.name}" "$@"\n')
    binary.chmod(0o755)

if __name__ == '__main__':
    import sys
    bundle_compiler(Path(sys.argv[1]), Path(sys.argv[2]))
