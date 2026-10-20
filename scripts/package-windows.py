"""Package tested binaries with clean runtime defaults and corresponding sources."""
from pathlib import Path
import argparse
import hashlib
import shutil
import subprocess
import zipfile

parser = argparse.ArgumentParser()
parser.add_argument("--bundle", type=Path, required=True)
parser.add_argument("--output", type=Path, required=True)
parser.add_argument("--version", required=True)
args = parser.parse_args()
source = Path(__file__).resolve().parents[1]
bundle = args.bundle.resolve()
output = args.output.resolve()
output.mkdir(parents=True, exist_ok=False)
root = output / "FTEBroom-Windows-x64"
root.mkdir()
for name in (
    "fteqw64.exe", "fteplug_ftebroom_x64.dll", "zlib1.dll", "libpng16.dll",
    "libjpeg.dll", "libgcc_s_seh-1.dll", "libwinpthread-1.dll", "Launch-FTEBroom.cmd",
):
    shutil.copy2(bundle / name, root / name)
shutil.copy2(source / "scripts/Launch-Checks.cmd", root / "Launch-Checks.cmd")
shutil.copytree(bundle / "licenses", root / "licenses")
shutil.copytree(source / "runtime", root / "ftebroom")
for name in ("default.fmf", "installed.lst"):
    shutil.copy2(source / "runtime" / name, root / name)
shutil.copy2(source / "csaddon.dat", root / "ftebroom/csaddon.dat")
tracked = subprocess.check_output(
    ["git", "ls-files", "-z"], cwd=source
).decode("utf-8").split("\0")
for name in filter(None, tracked):
    target = root / "sources/ftebroom" / name
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source / name, target)
archives = list((bundle / "sources").glob("*.zip"))
if len(archives) < 2:
    raise RuntimeError("Pinned FTE and ImGui source archives are required")
for archive in archives:
    shutil.copy2(archive, root / "sources" / archive.name)
for path in source.glob("*.md"):
    shutil.copy2(path, root / path.name)
for folder in ("docs", "screenshots", "scripts"):
    shutil.copytree(source / folder, root / folder)
patches = ", ".join(path.name for path in sorted((source / "patches").glob("*.patch")))
info = (
    f"FTEBroom {args.version}\n"
    "Engine/SDK: f937b9d88f71fc4429db5fe56c6a98d922711b2e\n"
    f"Engine patches: {patches}\n"
    "ImGui: f5befd2d29e66809cd1110a152e375a7f1981f06\n"
)
for name in ("fteqw64.exe", "fteplug_ftebroom_x64.dll", "ftebroom/csaddon.dat"):
    info += f"{name} SHA256: {hashlib.sha256((root / name).read_bytes()).hexdigest()}\n"
(root / "build-info.txt").write_text(info, encoding="utf-8")
archive = output / f"FTEBroom-{args.version}-Windows-x64.zip"
with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zipped:
    for path in sorted(root.rglob("*")):
        if path.is_file():
            zipped.write(path, path.relative_to(output))
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
archive.with_suffix(".zip.sha256").write_text(f"{digest}  {archive.name}\n", encoding="ascii")
print(f"{archive}\n{archive.stat().st_size} bytes\nSHA256 {digest}")
