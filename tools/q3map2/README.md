# Bundled q3map2 (Windows x64)

Unmodified compiler and its runtime DLLs from [NetRadiant-custom 20260114](https://github.com/Garux/netradiant-custom/releases/tag/20260114). Only the compiler's runtime dependencies are included; the Qt editor is not included.

Original binary archive: `netradiant-custom-20260114-windows-x86_64.zip`, SHA256 `25c2e14e2b0bd7a9897b2f943c8821458873c8713973f9c3d68d49f26fe79e35`. `SHA256SUMS.txt` records the extracted binaries. The adjacent `netradiant-custom-20260114-source.zip` contains the compiler source at that release tag. Build instructions and dependency requirements are in that source archive's README and CMake files. Upstream: https://github.com/Garux/netradiant-custom/tree/20260114 .

q3map2 is GPL licensed; retain COPYING.txt, GPL.txt, LGPL.txt and the corresponding source archive. Runtime dependency notices are under `licenses/`; dependency projects include Assimp, GLib, libjpeg-turbo, libpng, zlib/minizip, libxml2, PCRE2, bzip2, gettext, libiconv and the GCC/MinGW runtime. These DLLs remain separate and replaceable. Upstream release packaging/dependency sources are maintained by NetRadiant-custom and MSYS2 (https://github.com/msys2/MINGW-packages).

FTEBroom selects this executable when no custom q3map2 path is configured. Override it in **Build… → q3map2 executable**. Keep all adjacent DLLs when moving the compiler.
