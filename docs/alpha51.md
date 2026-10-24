# Alpha 51: Unity Sync

Choose **Tools → Unity Sync**, enter a Unity project directory or a folder inside its `Assets`, and press **Sync**. The directory browser has Up and Refresh controls. The exporter creates `ReyondBroom_<map>` there and installs the managed C# importer under `Assets/ReyondBroomEditor/Editor`.

The importer creates `Prefabs/Map.prefab`, mesh assets and materials. Repeating Sync replaces generated geometry and prefab contents. Material assets retain their GUIDs and chosen shaders; copied texture assignments are refreshed. Place the generated prefab in a Unity scene. Edit instances or separate prefabs if you need changes that must survive regeneration.

Options:

- Separate brush / patch objects, or combine geometry into one mesh with material submeshes.
- Copy static texture previews from the active mounted resources, including decoded WAD previews.
- Add mesh colliders.
- Set world-unit scale (default 0.0254 Unity units per map unit).

Brushes and tessellated patches retain their UVs. Coordinates are converted from Z-up to Y-up with compensated triangle winding. Layers excluded from export remain excluded. Point entities, game logic, dynamic Quake shaders, FTE terrain and compiled lightmaps are not converted to Unity components. Missing texture previews are counted in the result; materials remain available without a texture. The importer uses URP/Lit, Standard or Diffuse when creating a new material. Unreferenced mesh/material assets from an older export are retained so references in other Unity assets are not broken.

The export does not change source maps or mod files. Generated files are staged, previous files are retained until publication succeeds, and failures attempt rollback. Unrelated importer files, unowned nonempty export folders and symbolic-link destinations are rejected. Re-sync preserves Unity `.meta` files. The importer waits until the export lock is released. Safety limits are 4096 materials, 256 MiB of exported geometry/textures, 16 megapixels per decoded image, two million imported vertices and four million triangles.

## Verification checklist

1. Export a textured brush and a curved patch into a disposable Unity project. Check scale, orientation, visible outer faces and UV alignment.
2. Compare separate and combined modes; check the optional mesh colliders.
3. Change geometry and repeat Sync. The same prefab should update without duplicate geometry or lost material GUIDs.
4. Try textures from a WAD and Quake 3 shader editor images. Shader animation is intentionally represented by a static preview.
5. Exclude a layer from export and confirm its contents are absent.
6. Try an invalid destination and an unrelated existing export directory; no unrelated files should change.
7. Repeat export on Windows and Linux. Confirm ordinary OBJ export, MAP save/reopen and editing gestures still work.

The OBJ reader has executable tests for coordinates, UVs, winding, separate/combined meshes, malformed input and actual engine output. Engine export tests run on Windows and Arch Linux under Xvfb. A Unity Editor installation is not available in the build environment; prefab creation and rendering inside Unity still require that integration check. Full editor parity remains tracked in [the comparison ledger](reyond-parity.md).
