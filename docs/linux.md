# Linux x86-64 distribution

The native Linux preview targets **Ubuntu 24.04 or compatible glibc 2.39+ systems**
with an X11/XWayland desktop and OpenGL. It is not an AppImage and is not a Windows
binary wrapped in Wine. Extract the complete archive and run `./Launch-FTEBroom.sh`.
Use a writable installation directory; settings stay with the portable installation.

Install runtime dependencies on Ubuntu 24.04:

```sh
sudo apt install libgl1 libx11-6 libxrandr2 libxcursor1 libxi6 libasound2t64 libpulse0 \
  libpng16-16t64 libjpeg-turbo8 zlib1g libstdc++6 libassimp5 libglib2.0-0t64 libxml2 \
  ffmpeg xdg-utils
```

Q3Map2 and Quake 1 qbsp/vis/light are bundled as native binaries. Compiler paths
default to these binaries and remain editable. Sound editing uses the installed
`/usr/bin/ffmpeg`; the package contains a small launcher, not a copied FFmpeg binary.

## Platform differences

- MAP editing, ImGui, profiles, geometry, material/entity browsers, native BSP
  inspection, builds and the internal file manager are available.
- Windows Explorer external drag-and-drop/image-to-WAD import and native Windows
  file pickers are Windows integrations. On Linux, use the internal browser and
  the WAD path/Add WAD controls or profile WAD list.
- Embedded child-window **Preview mod** is currently Windows-only. Native Linux
  BSP inspection works; launch a game separately with an explicit Run task.
- Automatic package installation/update and the LibreQuake installer are
  Windows-only. On Linux, install updates manually; download LibreQuake from the
  provided link, extract it and select its `lq1` folder.
- The first Linux package is a preview, not a claim of all-platform feature parity.

## Rebuild

Install these build dependencies in addition to the runtime dependencies:

```sh
sudo apt install build-essential git curl ca-certificates python3 cmake pkg-config \
  unzip zip zlib1g-dev libpng-dev libjpeg-dev libfreetype-dev libgl-dev libx11-dev \
  libxrandr-dev libxcursor-dev libxi-dev libasound2-dev libpulse-dev libssl-dev \
  libsdl2-dev libogg-dev libvorbis-dev libopus-dev libspeex-dev liblzma-dev \
  libassimp-dev libxml2-dev libglib2.0-dev
bash scripts/build-linux.sh /path/to/dedicated-build-directory
```

The script pins the same engine/ImGui sources as Windows and applies repository
patches. Compiler source archives are included in the corresponding-source bundle;
`scripts/linux-compiler-compat.py` records the GCC 13 compatibility edits. It does
not change compiler geometry algorithms. Sources and licenses ship in the archive.
