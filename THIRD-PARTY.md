# Third-party notices / Сторонние компоненты

- FTE Quake and csaddon: https://github.com/fte-team/fteqw — GPL-2.0-or-later. Copied csaddon sources preserve original notices; see FTE-LICENSE.txt. Changes: FTEBroom command routing, box creation and Redo dispatch fix.
- Dear ImGui: https://github.com/ocornut/imgui — MIT, Copyright (c) 2014-2025 Omar Cornut. The build copies its complete license into the output.
- ReyondBroom and TrenchBroom are workflow references. This repository does not include their Qt application sources. The FTEBroom implementation is GPL-2.0-or-later.
- GCC runtime components statically linked into the plugin are covered by their licenses and GCC Runtime Library Exception. See https://www.gnu.org/licenses/gcc-exception-3.1.html.

The default build compiles the pinned FTE source with the included patch. An optional user-supplied FTE binary may differ from the pinned SDK. Preserve corresponding engine source and all applicable third-party notices when distributing that binary; do not label the SDK checkout as its corresponding source unless it matches.

По умолчанию движок собирается из закреплённых исходников с патчем. Можно указать сторонний бинарник FTE. Для его распространения нужны соответствующие именно ему исходники и лицензии. Закреплённая версия SDK не обязательно совпадает с версией бинарника.

The default engine build applies patches/preserve-brush-surface-metadata.patch to the pinned source. Bundled source archives include the base source; the adjacent patch records the engine modification. PNG, JPEG and zlib libraries retain their included upstream notices. / Сборка движка включает патч сохранения метаданных; исходники состоят из базового архива и прилагаемого патча.


- Bundled q3map2: NetRadiant-custom 20260114, GPL; unmodified compiler, corresponding source archive and runtime notices in [tools/q3map2](tools/q3map2/README.md). / Встроенный q3map2: исходники и лицензии находятся рядом с компилятором.

- Quake 1 compiler bundle: ericw-tools v0.18.1 (separate GPL-3.0 tools), unmodified Windows binaries. Version, source URL and checksums: [tools/ericw/PIN.json](tools/ericw/PIN.json). The distribution contains corresponding source, GPL text and Embree/TBB notices. The repository fetches the pinned bundle during build rather than storing a second copy of all binaries.
- Quake entity descriptions in `runtime/quake1.ent`: Copyright (C) 1996-1997 Id Software, Inc., GPL-2.0-or-later; derived from [Quake-Tools qcc/v101qc](https://github.com/id-Software/Quake-Tools/tree/master/qcc/v101qc). FTEBroom adds structured editor properties and model hints. The original game art, sounds and executable game logic are not included. `quake1-editor.wad` is original FTEBroom test/editor artwork under the repository license.

- `runtime/librequake.def`: QUAKED descriptions from LibreQuake v0.09-beta (`qcsrc`, https://github.com/lavenderdotpet/LibreQuake/tree/v0.09-beta/qcsrc), Copyright Id Software and LibreQuake contributors, GPL-2.0-or-later. The optional downloader retrieves the original upstream Mod Lite archive and preserves its per-resource license notices; game data is not bundled with FTEBroom.
