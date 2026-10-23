# Alpha 42: first cross-platform parity increment

English (primary). This is an incremental release, **not full ReyondBroom parity**.

## New workflows

- Double-click PNG, JPEG, TGA, BMP, GIF or PSD files in the mod file manager to open Image viewer. Fit, 100% and zoom are available. GIF displays its first image. Image tiles preserve aspect ratio; archive members are supported. Refresh reloads changed files. The bounded cache stores reduced thumbnails separately from the full viewer image.
- Drag a MAP from the file manager into a viewport to insert its contents. Double-click still opens/replaces the current document with the existing unsaved-changes prompt. Import preserves current worldspawn settings, inserts geometry and entities, remaps group identifiers and supports one Undo/Redo. Quake 1 and Quake 3 profile families cannot be mixed by import. Terrain documents and files over 16 MiB are rejected.
- **Edit > Fracture...** partitions one convex brush into 2–128 seeded Voronoi fragments. Separation defaults to zero. Cut material and individual `func_wall` fragments are optional. Exterior material/UV projections are retained. Preview is in the scene; invalid operations roll back.
- **Edit > Perforate...** subtracts seeded convex polygonal through-holes. Configure count, sides, axis, diameter range and spacing. Keep plugs creates a `func_wall` per hole and selects only those plugs after Apply. Impossible placement leaves the original intact. The sampling method is conservative: a failed placement does not prove no geometric packing exists.
- **Convert...** is available in Model viewer and a model file's context menu. This first exporter supports **MD3** with baked vertex samples and **OBJ** with a static first sample. Accept the loss warning before converting. Sequence -1 samples consecutive poses (useful for Quake MDL/MD2); a nonnegative sequence samples that animation at the selected FPS. It extracts loaded alias-model geometry through FTE, not through a second independent importer. Bones, tags, events and skin variants are not retained. MD3 uses referenced materials; a Quake MDL's first embedded skin is written as TGA with the loaded palette. OBJ currently omits materials. Existing destinations are rejected. Conversion is not yet available to every FTE-supported target format.
- Linux external drops now share the resource-import workflow: models are copied into the mod, drops onto the scene place them, drops into the file manager copy files, and images dropped into Materials can be converted into a WAD. Linux PNG/JPEG/BMP/GIF/TGA decoding uses vendored stb_image. Windows retains WIC's additional TIFF support.

## Platform parity still outstanding

The shared editor code is built for both platforms. Windows receives the shared fixes made since alpha 37. This does **not** eliminate all platform differences: embedded mod preview is still Windows-only, and Linux's WAD destination selector uses a path field rather than a native picker. Linux audio editing still requires the documented ffmpeg dependency.

The remaining ReyondBroom work includes Settle/Bullet, Inset, Spin, Bezier Bend, dedicated linear/radial/random arrays, synchronized Symmetry, Rock/Sculpt, Polygon Cut/Spawn, Subdivision/triangular brush conversion, Subtract 2, Spawn Master and Unity Sync. Existing counterparts such as Bevel, terrain generation, grid rotation, linked groups, prefab insertion and entity/material browsing must be compared by behavior, not merely by tool names. See [parity audit](reyond-parity.md).

## Test checklist

Use a copy of a map/mod for testing.

1. In both OS builds, open your existing settings and verify the Quake 1, Quake 3 and FTE Custom game profiles. Check the existing clipboard, cursor, WAD mounting, build/BSP preview and updater flows.
2. Browse a folder with many images, scroll and resize its tiles, double-click an image, test Fit/100%/zoom and close the viewer. Test an image inside a PAK and Refresh after replacing a loose image. Invalid images should report an error without crashing.
3. Drag a compatible MAP into perspective and 2D views. Check placement, materials, brush entities, point entities and groups. Undo once and redo; save/reopen. The original source MAP must remain unchanged. Double-click must still use Open rather than Import.
4. Fracture a textured cube and an irregular brush. Check exact fragment count, deterministic seed, exterior scales/offsets, cut material, zero/nonzero separation, preview/cancel and Undo/Redo. Repeat with individual `func_wall` enabled.
5. Perforate a brush with multiple holes, varying sizes and axes. Check plug count, side count, selection and `func_wall` class. Disable Keep plugs, try parameters that cannot fit, and verify Undo/Redo and export/build.
6. Convert a small model to MD3 and reopen the result. Test multiple samples of a real animation. Check geometry, UVs and exported MDL skin. Test OBJ's static geometry. Confirm the original remains unchanged and an existing destination is refused. Unsupported models, oversized surfaces and MD3 coordinates outside its range must produce errors.
7. On Arch/Wayland, drop a WAD, PNG/JPEG and model from the desktop file manager. Choose a WAD for the image and verify its material after building. Drop a model onto the scene and into the file manager; check placement versus copying.

## Русский

Это первый этап переноса, а не завершённый паритет с ReyondBroom. Добавлены просмотр изображений и миниатюры, импорт MAP перетаскиванием, Fracture, Perforate и начальная конвертация моделей в MD3/OBJ. В Linux расширен импорт внешних файлов. Windows собирается из общей актуальной версии исходников.

Полная конвертация во все форматы, остальные перечисленные инструменты ReyondBroom и встроенный предпросмотр мода в Linux остаются отдельными незавершёнными пунктами. При проверке особенно важны Undo/Redo, сохранение текстур, отсутствие изменений исходных файлов и реальные анимированные модели.
