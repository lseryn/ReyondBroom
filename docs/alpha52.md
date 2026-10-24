# Alpha 52: texture folders and compile WADs

In the **Quake 1** profile, open **Material → Texture folders / compile WAD…**. Choose a source directory, optionally choose an export palette, and press **Import / rebuild folder**. The directory browser supports Up, folders and palette files. The importer scans PNG, JPEG, TGA and BMP files recursively. Source images remain unchanged.

A generated WAD2 is stored in the editor's `data/texture-folder-wads` cache and registered as an additional WAD. The existing map build pipeline stages it under ASCII relative paths before calling qbsp, so source folders with spaces or non-Latin characters do not become compiler WAD paths. This is a real WAD resource workflow: Quake 1 does not mount loose source PNGs as map textures.

Empty palette paths use the active game's `gfx/palette.lmp`. Custom palettes may be raw 768-byte LMP, 256-color PCX or 8-bit BMP. Use **Preview palette** to inspect colors. The export palette must match the palette used by the game: WAD2 does not embed a palette. Image conversion retains the existing importer policy: power-of-two dimensions from 16 to 512, alpha composited over black and quantization to the first 224 palette entries, followed by four mip levels. Windows uses WIC and Linux uses the bundled image decoder; filtering may produce small pixel differences.

Short top-level filenames become lowercase texture names. Nested or long names receive a stable path-derived suffix to fit the 15-character WAD limit. Duplicate resulting names are rejected. A `.names.txt` file beside the generated WAD records source-to-texture names.

Conversion runs in the background with progress and cancellation. A failed or cancelled conversion does not publish a partially built WAD. Publication retains one `.previous` copy; a subsequent successful rebuild replaces that backup. Folder/palette choices are saved. **Rebuild all registered folders** refreshes them sequentially and stops at the first error. Rebuild after changing source images; there is no file watcher. Closing the window leaves a running conversion active; use **Cancel compilation** to stop it.

Limits: 1024 images per folder, 64 MiB per encoded image, 128 MiB per generated WAD and 128 registered folders. The import does not add new game profiles. This workflow does not yet reproduce Ultimate's high-resolution loose-image previews or masked/fullbright palette conversion policy.

## Verification checklist

1. In Quake 1, import a folder containing PNG/JPEG/TGA/BMP images and nested directories. Check that materials appear and source images remain unchanged.
2. Import non-power-of-two images; inspect the resized WAD materials. Check the name mapping for long/nested names.
3. Choose valid LMP, PCX and BMP palettes and preview them. Try an invalid palette; the editor should report the error without crashing.
4. Paint a brush with an imported texture and build the map. The compiled BSP must contain that texture, including when the source folder has spaces or non-Latin characters.
5. Change a source image, rebuild and check the updated texture. Confirm that the previous WAD exists beside the replacement.
6. Register another folder, use Rebuild all and check both results.
7. Cancel a larger conversion, then rebuild again. The previous WAD should remain usable.
8. Reopen the editor and select a registered folder. Test the same workflow on Windows and Linux, including a small display where the window scrolls.

Automated coverage includes both native decoders, PNG/JPEG resizing, recursive imports, all three palette containers, invalid palettes, cancellation, repeated builds and compiler staging. The qbsp integration check compares embedded BSP texture pixels to the generated WAD.
